#!/bin/bash

set -e

# Config
PROFILE_NAME="hep-cluster"
CPUS=2
MEMORY=4096
DISK_SIZE="20g"
DRIVER="docker"

echo "Checking if minikube is installed..."

if ! command -v minikube &> /dev/null; then
    echo "Minikube is not installed. Please install it first:"
    echo "https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

echo "Minikube is installed."

echo "Starting minikube with profile: $PROFILE_NAME"

minikube start --profile="$PROFILE_NAME" \
  --cpus="$CPUS" \
  --memory="$MEMORY" \
  --disk-size="$DISK_SIZE" \
  --driver="$DRIVER" \
  --addons=ingress,metrics-server,dashboard,registry,storage-provisioner,default-storageclass \
  --nodes=1

echo "Minikube cluster '$PROFILE_NAME' started with:"
echo "   - CPUs: $CPUS"
echo "   - Memory: $MEMORY MB"
echo "   - Disk: $DISK_SIZE"
echo "   - Addons: ingress, metrics-server"

echo "Verifying cluster status..."
kubectl get nodes

echo "Enabling Kubernetes Dashboard..."
minikube dashboard --url --profile="$PROFILE_NAME"

echo "Tip: You can set kubectl context with:"
echo "kubectl config use-context "$PROFILE_NAME""

echo "Then deploy your application with:"
echo "kubectl apply -f k8s/"