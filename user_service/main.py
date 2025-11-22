from fastapi import FastAPI, Depends
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import sessionmaker, Session
from prometheus_fastapi_instrumentator import Instrumentator
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable
import json
import os
import time
from dotenv import load_dotenv
from pydantic import BaseModel
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Cargar variables de entorno
load_dotenv()

# Crear la aplicación FastAPI
app = FastAPI(title="User Service", version="1.0.0")

# Database settings
DATABASE_URL = f"mysql+mysqlconnector://{os.getenv('MYSQL_USER')}:{os.getenv('MYSQL_PASSWORD')}@{os.getenv('MYSQL_HOST')}/{os.getenv('MYSQL_DATABASE')}"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Kafka configuration
KAFKA_BROKER_URL = os.getenv("KAFKA_BROKER_URL", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "user_events")

# Producer global (se inicializa lazy)
_producer = None

def get_kafka_producer():
    """
    Lazy initialization del KafkaProducer con reintentos.
    """
    global _producer
    if _producer is None:
        max_retries = 5
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                logger.info(f"Intentando conectar a Kafka en {KAFKA_BROKER_URL} (intento {attempt + 1}/{max_retries})")
                _producer = KafkaProducer(
                    bootstrap_servers=KAFKA_BROKER_URL,
                    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                    max_block_ms=5000,
                )
                logger.info("Conectado exitosamente a Kafka")
                break
            except NoBrokersAvailable:
                logger.warning(f"Kafka no disponible en intento {attempt + 1}")
                if attempt < max_retries - 1:
                    time.sleep(retry_delay)
                else:
                    logger.error("No se pudo conectar a Kafka después de varios intentos")
                    _producer = None
    
    return _producer

# CONFIGURAR PROMETHEUS
instrumentator = Instrumentator()
instrumentator.instrument(app)
instrumentator.expose(app, endpoint="/metrics")

class UserCreate(BaseModel):
    user_name: str
    email: str

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), index=True)
    email = Column(String(50), index=True)

# Crear tablas
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.on_event("startup")
async def startup_event():
    """Intentar conectar a Kafka al iniciar (pero sin bloquear)."""
    logger.info("Iniciando User Service...")
    try:
        get_kafka_producer()
    except Exception as e:
        logger.warning(f"No se pudo conectar a Kafka al inicio: {e}")

@app.get("/", tags=["Root"])
async def root():
    return {"message": "User Service API", "status": "running", "version": "1.0.0"}

@app.get("/health", tags=["Health"])
async def health():
    """Health check endpoint."""
    kafka_status = "connected" if _producer is not None else "disconnected"
    return {
        "status": "healthy",
        "kafka": kafka_status,
        "database": "connected"
    }

@app.get("/user-service", tags=["Root"])
async def root_service():
    return {"message": "User Service - OK"}

@app.post("/register/", tags=["Users"])
async def register_user(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user and store it in MySQL, then emit a UserRegistered event."""
    # Guardar en la base de datos
    new_user = User(name=user.user_name, email=user.email)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Intentar enviar evento a Kafka
    producer = get_kafka_producer()
    
    if producer:
        try:
            event = {
                "event_type": "UserRegistered",
                "data": {"user_name": user.user_name, "email": user.email},
            }
            producer.send(KAFKA_TOPIC, event)
            logger.info(f"Evento enviado a Kafka para usuario: {user.user_name}")
            kafka_status = "event_sent"
        except Exception as e:
            logger.error(f"Error al enviar evento a Kafka: {e}")
            kafka_status = "event_failed"
    else:
        logger.warning("Kafka no disponible, usuario registrado pero evento no enviado")
        kafka_status = "kafka_unavailable"
    
    return {
        "message": "User registered successfully",
        "user_id": new_user.id,
        "kafka_status": kafka_status
    }

@app.get("/users/", tags=["Users"])
async def list_users(db: Session = Depends(get_db)):
    """List all users."""
    users = db.query(User).all()
    return {"users": [{"id": u.id, "name": u.name, "email": u.email} for u in users]}