#!/bin/bash

set -e

echo "Desplegando Microservicios en Kubernetes..."
echo ""

# 1. Namespace
echo "[1/9] Creando namespace..."
kubectl apply -f namespace/
sleep 2

# 2. ConfigMap y Secrets
echo "[2/9] Creando ConfigMaps y Secrets..."
kubectl apply -f configmap/
kubectl apply -f secrets/
sleep 2

# 3. Storage
echo "[3/9] Creando Persistent Volumes..."
kubectl apply -f storage/
sleep 5

# 4. Zookeeper
echo "[4/9] Desplegando Zookeeper..."
kubectl apply -f messaging/zookeeper.yaml
echo "Esperando a Zookeeper..."
kubectl wait --for=condition=ready pod -l app=zookeeper -n microservices --timeout=120s
sleep 5

# 5. Kafka
echo "[5/9] Desplegando Kafka..."
kubectl apply -f messaging/kafka.yaml
echo "Esperando a Kafka..."
kubectl wait --for=condition=ready pod -l app=kafka -n microservices --timeout=180s
sleep 10

# 6. MySQL
echo "[6/9] Desplegando MySQL..."
kubectl apply -f databases/
echo "Esperando a MySQL..."
kubectl wait --for=condition=ready pod -l app=mysql -n microservices --timeout=180s
sleep 10

# 7. Microservicios
echo "[7/9] Desplegando microservicios..."
kubectl apply -f services/
sleep 10

# 8. Monitoring
echo "[8/9] Desplegando Prometheus y Grafana..."
kubectl apply -f monitoring/
sleep 10

# 9. Adminer
echo "[9/9] Desplegando Adminer..."
kubectl apply -f admin/
sleep 5

echo ""
echo "¡Despliegue completado!"
echo ""
echo "Ver estado de pods:"
echo "   kubectl get pods -n microservices"
echo ""
echo "Ver servicios:"
echo "   kubectl get svc -n microservices"
echo ""
echo "Acceder a servicios:"
echo "   minikube service user-service -n microservices"
echo "   minikube service grafana -n microservices"
echo "   minikube service prometheus -n microservices"
echo "   minikube service adminer -n microservices"
