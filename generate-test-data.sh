#!/bin/bash

echo "Generando datos de prueba..."
echo ""

# Lista de usuarios de ejemplo
users=(
  '{"user_name": "Juan Pérez", "email": "juan.perez@example.com"}'
  '{"user_name": "María García", "email": "maria.garcia@example.com"}'
  '{"user_name": "Carlos López", "email": "carlos.lopez@example.com"}'
  '{"user_name": "Ana Martínez", "email": "ana.martinez@example.com"}'
  '{"user_name": "Luis Rodríguez", "email": "luis.rodriguez@example.com"}'
  '{"user_name": "Laura Fernández", "email": "laura.fernandez@example.com"}'
  '{"user_name": "Pedro Sánchez", "email": "pedro.sanchez@example.com"}'
  '{"user_name": "Isabel Torres", "email": "isabel.torres@example.com"}'
  '{"user_name": "Miguel Ramírez", "email": "miguel.ramirez@example.com"}'
  '{"user_name": "Carmen Flores", "email": "carmen.flores@example.com"}'
  '{"user_name": "Diego Herrera", "email": "diego.herrera@example.com"}'
  '{"user_name": "Sofía Castro", "email": "sofia.castro@example.com"}'
  '{"user_name": "Andrés Medina", "email": "andres.medina@example.com"}'
  '{"user_name": "Paula Rivas", "email": "paula.rivas@example.com"}'
  '{"user_name": "Jorge Duarte", "email": "jorge.duarte@example.com"}'
  '{"user_name": "Verónica Silva", "email": "veronica.silva@example.com"}'
  '{"user_name": "Alberto Moreno", "email": "alberto.moreno@example.com"}'
  '{"user_name": "Daniela Pardo", "email": "daniela.pardo@example.com"}'
  '{"user_name": "Ricardo Gómez", "email": "ricardo.gomez@example.com"}'
  '{"user_name": "Natalia Reyes", "email": "natalia.reyes@example.com"}'
  '{"user_name": "Héctor Jiménez", "email": "hector.jimenez@example.com"}'
  '{"user_name": "Gabriela Ortiz", "email": "gabriela.ortiz@example.com"}'
  '{"user_name": "Tomás Villalba", "email": "tomas.villalba@example.com"}'
  '{"user_name": "Elena Carrillo", "email": "elena.carrillo@example.com"}'
  '{"user_name": "Rodrigo Navarro", "email": "rodrigo.navarro@example.com"}'
  '{"user_name": "Patricia León", "email": "patricia.leon@example.com"}'
  '{"user_name": "Esteban Fuentes", "email": "esteban.fuentes@example.com"}'
  '{"user_name": "Lucía Cabrera", "email": "lucia.cabrera@example.com"}'
  '{"user_name": "Felipe Salazar", "email": "felipe.salazar@example.com"}'
  '{"user_name": "Camila Robles", "email": "camila.robles@example.com"}'
  '{"user_name": "Oscar Molina", "email": "oscar.molina@example.com"}'
  '{"user_name": "Valeria Montoya", "email": "valeria.montoya@example.com"}'
  '{"user_name": "Santiago Vera", "email": "santiago.vera@example.com"}'
  '{"user_name": "Lorena Castaño", "email": "lorena.castano@example.com"}'
  '{"user_name": "Emilio Vargas", "email": "emilio.vargas@example.com"}'
  '{"user_name": "Adriana Peña", "email": "adriana.pena@example.com"}'
  '{"user_name": "Mauricio Barrios", "email": "mauricio.barrios@example.com"}'
  '{"user_name": "Claudia Navas", "email": "claudia.navas@example.com"}'
  '{"user_name": "Hernán Valdez", "email": "hernan.valdez@example.com"}'
  '{"user_name": "Julieta Ponce", "email": "julieta.ponce@example.com"}'
)

# Registrar usuarios
for i in "${!users[@]}"; do
  echo "[$((i+1))/10] Registrando usuario..."
  
  curl -X POST http://localhost:8000/register/ \
    -H "Content-Type: application/json" \
    -d "${users[$i]}" \
    -s -o /dev/null -w "Status: %{http_code}\n"
  
  # Pausa de 2 segundos entre cada registro
  sleep 2
done

echo ""
echo "Datos de prueba generados!"
echo ""
echo "Verifica:"
echo "   - Prometheus: http://localhost:9090"
echo "   - Grafana: http://localhost:3000"
echo "   - Logs: docker logs notification-service -f"