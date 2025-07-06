## Flask + MongoDB Dockerized

# Folder Structure
.
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── src/
│   ├── app.py
│   ├── config.py
│   ├── db_config.json
│   ├── models/
│   └── factory/

# Dockerfile and Docker Compose

-- For the Flask app served from **src/app.py**, I wrote a simple Dockerfile where I copied the whole **src/** folder to **/app/** and asked it to broadcast on port 5005.

-- I wrote a **docker-compose.yml** file to run the Flask app and the MongoDB service together.

-- To be able to access the Flask application over the internet, I edited the **app.py** file and added the relevant port information.

`if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5005)`

-- I updated the MongoDB connection in **config.py** to support both local and container-based development.

## Run and Control


`docker compose up --build` and `http://localhost:5005/todos/` or `curl http://localhost:5005/todos/`

## Environment Variables

Variable	                   Purpose	                         Default
MONGO_URI	           MongoDB connection string	        mongodb://mongo:27017/myDatabase
MONGO_DB_NAME	       MongoDB database name	                  myDatabase

-- These can be modified for other environments with Docker-Compose.yml.

## Local Kubernetes Setup with Minikube

To simulate a production-like Kubernetes environment locally, a `setup_minikube.sh` script is provided.

## Prerequisites
- Docker
- Minikube: [Install Guide](https://minikube.sigs.k8s.io/docs/start/)

## Run the setup

`chmod +x scripts/setup_minikube.sh`
`./scripts/setup_minikube.sh`

## Flask + MongoDB Application - Kubernetes Deployment (Step 4)

This step focuses on deploying a Python-based Flask application with MongoDB on a Kubernetes cluster. The goal was to get the application up and running with internal connectivity and basic access verification.

### 1. Docker Image Created
- Selected an open-source Flask + PyMongo application.
- Built a custom Docker image using a `Dockerfile` and tested it locally with `docker-compose`.

### 2. Minikube Setup and Cluster Initialization

`minikube start`

## MongoDB Deployed via Helm

Used Bitnami's official Helm chart:

`helm repo add bitnami https://charts.bitnami.com/bitnami
helm install hep-mongodb bitnami/mongodb \
  --set auth.rootPassword=hepApipass321 \
  --set auth.username=mongoadmin \
  --set auth.database=hepApidb`

MongoDB was accessible via:

`mongodb://mongoadmin:<dbpassword>@<database>-mongodb.default.svc.cluster.local:27017/<dbname>
`

## Flask Application Deployed to Kubernetes

Used a Kubernetes Deployment with 2 replicas.

Environment variables were passed to the container for MongoDB connectivity:

`env:
  - name: MONGO_URI
    value: mongodb://mongoadmin:<dbpassword>@<database>-mongodb.default.svc.cluster.local:27017/<dbname>`

## Service Created (NodePort)

Created a Kubernetes Service to expose the Flask app:

`spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 5000
      nodePort: 30080`

## Testing & Validation

Internally tested the Flask API via service DNS:

`wget http://flask-service.default.svc.cluster.local/todos/`

Attempted external access via:

`curl http://<minikube-ip>:30080/todos/`

Pod logs confirmed successful MongoDB connectivity and HTTP requests.

