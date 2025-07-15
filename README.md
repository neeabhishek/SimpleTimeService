# SimpleTimeService

A minimal Python web server that returns a JSON payload containing the current timestamp and your IP address.
This repo demonstrates:

1. A **Flask** app (`app.py`)
2. Containerization via **Docker** (`app/Dockerfile`)
3. Infrastructure provisioning on AWS with **Terraform** (`terraform/` directory)

---

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Getting the Code](#-getting-the-code)
3. [Run Locally (Without Docker)](#-run-locally-without-docker)
4. [Build & Run with Docker](#-build--run-with-docker)
5. [Deploy Infrastructure with Terraform](#-deploy-infrastructure-with-terraform)
6. [Accessing the Service](#-accessing-the-service)
7. [Cleanup](#-cleanup)
8. [Contributing](#-contributing)

---

## 🚀 Prerequisites

* **Git**
* **Python 3.11+**
* **Docker Engine**
* **Terraform 1.5+**
* **AWS CLI** (configured with credentials having permissions to create VPC, EKS, IAM roles, etc.)

---

## 📥 Getting the Code

```bash
git clone https://github.com/neeabhishek/SimpleTimeService.git
cd SimpleTimeService
```

---

## 🏃‍♀️ Run Locally (Without Docker)

1. (Optional) Create a Python virtual environment:

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
2. Install dependencies:

   ```bash
   pip install flask or pip install -r requirement.txt
   ```
3. Start the server:

   ```bash
   python app/SimpleTimeService/app.py
   ```
4. Open your browser or run:

   ```bash
   curl http://localhost:5000
   ```

   You should see:

   ```json
   {
     "timestamp": "2025-07-14T21:30:15.123456",
     "ip": "127.0.0.1"
   }
   ```

---

## 🐳 Build & Run with Docker

1. **Build** the image:

   ```bash
   cd app && \
   docker build .
   ```
2. **Run** the container:

   ```bash
   docker run $(docker images -q | head -n1)

   ```
3. **Test**:

   ```bash
   curl http://localhost:5000
   ```

---

## 🌩️ Deploy Infrastructure with Terraform

All Terraform code lives under `terraform/`.

1. **Configure your AWS variables** (by passing the values in  `terraform/variable.tf`):

   ```terraform
   variable "access_key" {
    description = "Access key of IAM user"
    type = string
    default = "" ###Use your IAM user access keys.
    }
    variable "secret_key" {
    description = "Secret key of IAM user"
    type = string
    default = "" ###Use your IAM user secret keys.
    }
    variable "region" {
    description = "Region where the resources needs to deployed"
    type = string
    default = "" ###Use the region of your choice.
    }
   ```
2. **Initialize** Terraform:

   ```bash
   cd terraform
   terraform init
   ```
3. **Preview** the changes:

   ```bash
   terraform plan
   ```
4. **Apply** (creates VPC, subnets, EKS cluster, IAM roles, etc.):

   ```bash
   terraform apply -auto-approve
   ```
5. **Configure kubectl** to talk to your new EKS cluster:

   ```bash
   aws eks --region ${AWS_Region} \
     update-kubeconfig --name eks-particle41
   ```

Create a Kubernetes Deployment & Service manifest to run your Docker image on the cluster.*

1. Copy the below Deployment and Service definitions into deployment.yml and svc.yaml.

 ```yaml
   apiVersion: apps/v1
kind: Deployment
metadata:
  name: particle41-app
  labels:
    app: particle41-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: particle41-app
  template:
    metadata:
      labels:
        app: particle41-app
    spec:
      containers:
      - name: particle41-app
        image: neeabhishek/particle41:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
   ```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: particle41-svc
  labels:
    app: particle41-app
spec:
  type: LoadBalancer
  ports:
  - targetPort: 5000
    port: 5000
  selector:
    app: particle41-app
   ```
2. Execute the following commands
   
```bash
   kubectl apply -f svc.yml
   kubectl apply -f deployment.yml
   ```

---

## 🔗 Accessing the Service

* **Locally (Docker)**: `http://localhost:5000`
* **On EKS**: `http://${EKS_ENDPOINT}:80`
---

## 🧹 Cleanup

* **Local Docker**:

  ```bash
  docker rm -f $(docker ps -q | head -n1)
  docker rmi $(docker images -q | head -n1)
  ```
* **Terraform / AWS**:

  ```bash
  cd terraform
  terraform destroy -auto-approve
  ```

---

> **Notes for newcomers**
>
> * You don’t need deep AWS/Terraform knowledge—just follow the `terraform/` commands.
> * For Kubernetes, you can start by running the service locally in Docker before moving to EKS.
