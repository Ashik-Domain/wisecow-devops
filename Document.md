# 🌟 Wisecow DevOps Assessment

A complete end-to-end DevOps project demonstrating containerization, Kubernetes deployment, CI/CD automation, system monitoring scripts, and zero-trust security implementation using KubeArmor.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Problem Statement 1: Containerization & Kubernetes Deployment](#-problem-statement-1-containerization--kubernetes-deployment)
- [Problem Statement 2: System Administration Scripts](#-problem-statement-2-system-administration-scripts)
- [Problem Statement 3: Zero-Trust Security Policy](#-problem-statement-3-zero-trust-security-policy)
- [Technologies Used](#-technologies-used)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Monitoring & Logging](#-monitoring--logging)
- [Security Best Practices](#-security-best-practices-implemented)
- [Screenshots](#-project-screenshots)
- [Author](#-author)
- [Acknowledgments](#-acknowledgments)

---

## 🎯 Overview

This project demonstrates a holistic DevOps implementation using the **Wisecow application** — a shell-based web server that serves random fortune messages in ASCII cow format.

### The project covers:

- 🐳 **Docker containerization**
- ☸️ **Kubernetes orchestration**
- 🔄 **CI/CD with GitHub Actions**
- 🩺 **Application health monitoring**
- 💾 **Automated backup system**
- 🔐 **Zero-trust runtime security using KubeArmor**

Everything is production-ready and aligned with DevOps best practices.

---

## 🐳 Problem Statement 1: Containerization & Kubernetes Deployment

### ✅ Objectives Completed

- ✔️ Dockerized Wisecow application
- ✔️ Created Kubernetes manifests (Deployment, Service, Ingress)
- ✔️ Added resource requests & limits
- ✔️ Implemented CI/CD pipeline for Docker automation
- ✔️ Deployed on local Kubernetes cluster (KinD)
- ✔️ Added TLS-ready ingress (Challenge Goal)
- ✔️ Implemented zero-trust runtime policy

### 🧱 Dockerfile

The Dockerfile installs required dependencies, sets up the application, and exposes the application port.

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y fortune-mod cowsay netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/games:${PATH}"

WORKDIR /app
COPY wisecow.sh .
RUN chmod +x wisecow.sh

EXPOSE 4499
CMD ["./wisecow.sh"]
```

### ☸️ Kubernetes Resources

#### Deployment
- 2 replicas for high availability
- CPU & memory limits applied
- Uses Docker Hub image: `ashikimg/wisecow:latest`

#### Service
- Type: **NodePort**
- Exposes app internally as Service → maps to external NodePort
- Port mapping: 80 → 4499 (container) → 30001 (NodePort)

#### Ingress (TLS Ready)
- Domain: `wisecow.local`
- HTTPS enforced via `ssl-redirect`
- Uses TLS secret: `wisecow-tls`

**TLS Setup Note:**
> TLS certificates can be generated using:
> - **cert-manager** for automated certificates
> - **openssl** for self-signed certificates  
> - Cloud provider certificates (ACM, Let's Encrypt)
>
> Example for self-signed certificate:
> ```bash
> openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
>   -keyout tls.key -out tls.crt -subj "/CN=wisecow.local"
> kubectl create secret tls wisecow-tls --key tls.key --cert tls.crt
> ```

### 🚀 Deployment Commands

```bash
# Build and push Docker image
docker build -t ashikimg/wisecow:latest .
docker push ashikimg/wisecow:latest

# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Verify deployment
kubectl get pods
kubectl get svc

# Access Application
kubectl port-forward service/wisecow-service 8080:80
# Visit: http://localhost:8080
```

---

## 📜 Problem Statement 2: System Administration Scripts

Two automation scripts were developed:

1. **Application Health Checker**
2. **Automated Backup Solution**

### 1️⃣ Application Health Checker

**Purpose:** Determines whether an application is UP or DOWN using HTTP status codes.

#### ⭐ Features

- ✅ Checks service availability via HTTP
- ✅ Color-coded output (GREEN/YELLOW/RED)
- ✅ Logs entries to `app_health.log`
- ✅ Supports timeout and continuous monitoring
- ✅ Captures failed cURL attempts
- ✅ Distinguishes between HTTP codes (2xx=UP, 3xx=REDIRECT, 4xx/5xx=DOWN)

#### ▶️ Usage

```bash
# Single health check
./scripts/app_health_checker.sh http://localhost:8080

# Continuous monitoring (every 10 seconds)
./scripts/app_health_checker.sh http://localhost:8080 -i 10

# Custom timeout
./scripts/app_health_checker.sh http://example.com -t 20

# Help
./scripts/app_health_checker.sh -h
```

#### 📝 Sample Output

```
Application Health Checker
==========================
Monitoring: http://localhost:8080
Log file: app_health.log

[2025-11-23 16:12:05] UP - http://localhost:8080 - Status: 200
```

---

### 2️⃣ Automated Backup Solution

**Purpose:** Automates local or remote directory backups using tar and SCP.

#### ⭐ Features

- ✅ Creates `.tar.gz` compressed backups
- ✅ Timestamp-based filenames
- ✅ Remote server backup support using SCP
- ✅ Logs backups to `backup.log`
- ✅ Backup rotation (keeps last 5 by default, configurable)
- ✅ Handles errors gracefully
- ✅ Reports backup size and success/failure

#### ▶️ Usage

```bash
# Local backup
./scripts/automated_backup.sh -s /var/www -d /backup -n mybackup

# Remote backup
./scripts/automated_backup.sh -s /data -d /backup -r user@server -n data_backup

# Custom retention count (keep last 10 backups)
./scripts/automated_backup.sh -s /data -d /backup -k 10

# Help
./scripts/automated_backup.sh -h
```

#### 📦 Backup Naming Format

```
<name>_YYYYMMDD_HHMMSS.tar.gz

Example: wisecow_project_20251123_161727.tar.gz
```

#### 📊 Sample Log Output

```
[2025-11-23 16:17:27] [INFO] Starting backup of /root/wisecow-devops
[2025-11-23 16:17:27] [SUCCESS] Backup completed successfully
[2025-11-23 16:17:27] [INFO] Backup size: 36K
[2025-11-23 16:17:27] [INFO] Cleaning up old backups, keeping last 5
```

---

## 🔒 Problem Statement 3: Zero-Trust Security Policy

A complete **KubeArmor-based zero-trust runtime security policy** was implemented to enforce strict process, file, and network controls.

### ⭐ Security Controls

#### 🧩 Process Controls (Allowed Only)

| Process | Action | Reason |
|---------|--------|--------|
| `/usr/games/cowsay` | **Allow** | Required for cow ASCII art |
| `/usr/games/fortune` | **Allow** | Required for fortune quotes |
| `/bin/bash` | **Allow** | Required for script execution |
| `/usr/bin/nc` | **Allow** | Required for network communication |
| **All other processes** | **Block** | Zero-trust default deny |

#### 📁 File Access Controls

| Path/Directory | Action | Reason |
|----------------|--------|--------|
| `/app/` | **Allow** | Application files |
| `/tmp/` | **Allow** | Temporary storage |
| `/etc/passwd` | **Block** | Prevent credential access |
| `/etc/shadow` | **Block** | Prevent password hash access |
| **All other files** | **Block** | Zero-trust default deny |

#### 🌐 Network Controls

| Protocol | Action | Reason |
|----------|--------|--------|
| TCP | **Allow** | Required for HTTP service |
| UDP | **Block** | Not needed for application |

### ▶️ Apply KubeArmor Policy

```bash
# Install KubeArmor
karmor install

# Apply security policy
kubectl apply -f kubearmor-policies/wisecow-security-policy.yaml

# Monitor policy violations in real-time
karmor logs --follow

# View active policies
kubectl get kubearmorpolicies
```

### ✅ Expected Security Behavior

- ✔️ Wisecow application runs normally with allowed processes
- ❌ Attempts to access `/etc/passwd` or `/etc/shadow` are **blocked**
- ❌ Attempts to execute unauthorized binaries are **blocked**
- ❌ UDP network traffic is **blocked**
- 🔍 All violations are logged in real-time for security monitoring

### 🧪 Testing Policy Violations

```bash
# Execute into a pod
kubectl exec -it <wisecow-pod-name> -- /bin/bash

# Try to access blocked files (should fail)
cat /etc/passwd   # Permission denied
cat /etc/shadow   # Permission denied

# Try unauthorized command (should fail)
whoami            # Permission denied

# View violations
karmor logs --follow
```

---

## 🛠️ Technologies Used

| Category | Technologies |
|----------|-------------|
| **Containerization** | Docker, Docker Hub |
| **Orchestration** | Kubernetes, KinD |
| **CI/CD** | GitHub Actions |
| **Runtime Security** | KubeArmor |
| **Scripting** | Bash |
| **Cloud** | AWS EC2 (Amazon Linux 2023) |
| **Version Control** | Git & GitHub |
| **Monitoring** | kubectl, logs, custom scripts |

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (v20.10+)
- **kubectl** (v1.25+)
- **KinD** or **Minikube** (for local Kubernetes)
- **Git**
- **Optional:** AWS EC2 instance (t2.small minimum)

### Quick Start Guide

#### 1️⃣ Clone the Repository

```bash
git clone https://github.com/ashikimg/wisecow-devops.git
cd wisecow-devops
```

#### 2️⃣ Run with Docker

```bash
# Build the image
docker build -t wisecow .

# Run the container
docker run -d -p 4499:4499 --name wisecow-test wisecow

# Test the application
curl http://localhost:4499
```

#### 3️⃣ Deploy to Kubernetes

```bash
# Create KinD cluster
kind create cluster --name wisecow-cluster

# Load Docker image into KinD
kind load docker-image ashikimg/wisecow:latest --name wisecow-cluster

# Deploy all Kubernetes resources
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify deployment
kubectl get pods
kubectl get svc

# Access the application
kubectl port-forward service/wisecow-service 8080:80
# Visit: http://localhost:8080
```

#### 4️⃣ Test Monitoring Scripts

```bash
# Test health checker
chmod +x scripts/app_health_checker.sh
./scripts/app_health_checker.sh http://localhost:8080

# Test backup script
chmod +x scripts/automated_backup.sh
./scripts/automated_backup.sh -s ./app -d ./backups -n test_backup
```

#### 5️⃣ Apply Security Policy (Optional)

```bash
# Install KubeArmor
karmor install

# Apply the policy
kubectl apply -f kubearmor-policies/wisecow-security-policy.yaml

# Monitor security events
karmor logs --follow
```

---

## 📁 Project Structure

```
wisecow-devops/
├── .github/
│   └── workflows/
│       └── docker-build-push.yaml    # CI/CD pipeline configuration
├── k8s/
│   ├── deployment.yaml               # Kubernetes deployment manifest
│   ├── service.yaml                  # Kubernetes service manifest
│   └── ingress.yaml                  # Ingress with TLS configuration
├── kubearmor-policies/
│   ├── wisecow-security-policy.yaml  # Zero-trust security policy
│   └── README.md                     # Policy documentation
├── scripts/
│   ├── app_health_checker.sh         # Application health monitoring
│   ├── automated_backup.sh           # Backup automation script
│   └── backup.log                    # Backup operation logs
├── screenshots/                      # Project demonstration screenshots
├── Dockerfile                        # Container image definition
├── wisecow.sh                        # Main application script
├── LICENSE                           # Apache License
└── README.md                         # Assessment file
└── Document.md                       # This file
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

**Trigger:** Automatic on push or pull request to `main` branch

#### Pipeline Steps:

1. ✅ **Checkout code** from repository
2. ✅ **Set up Docker Buildx** for multi-platform builds
3. ✅ **Login to Docker Hub** (using secrets)
4. ✅ **Extract metadata** and create tags
5. ✅ **Build Docker image** with caching
6. ✅ **Push to Docker Hub** with tags:
   - `latest` (for main branch)
   - `main-<commit-sha>` (for version tracking)

#### Required Secrets:

Configure these in GitHub repository settings:

- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password/access token

#### Workflow File Location:

`.github/workflows/docker-build-push.yaml`

---

## 📊 Monitoring & Logging

### Kubernetes Logs

```bash
# View pod logs
kubectl logs -f deployment/wisecow-deployment

# View logs from specific pod
kubectl logs -f <pod-name>

# View logs from all pods
kubectl logs -f -l app=wisecow
```

### Script Logs

```bash
# View health check logs
cat scripts/app_health.log

# View backup logs
cat scripts/backup.log

# Tail logs in real-time
tail -f scripts/backup.log
```

### KubeArmor Security Logs

```bash
# Monitor security events in real-time
karmor logs --follow

# View KubeArmor system logs
kubectl logs -n kubearmor -l app=kubearmor

# Check policy status
kubectl describe kubearmorpolicy wisecow-security-policy
```

---

## 🔐 Security Best Practices Implemented

- ✅ **Resource limits** on containers to prevent resource exhaustion
- ✅ **Zero-trust security policy** for workload protection
- ✅ **GitHub Actions secrets** for secure authentication
- ✅ **Minimal Docker image** with only required packages
- ✅ **TLS-ready ingress** for encrypted communication
- ✅ **Strict file & process access control** via KubeArmor
- ✅ **Efficient Docker caching** via Buildx for faster builds
- ✅ **Network protocol restrictions** (TCP only)
- ✅ **Automated vulnerability scanning** via Docker Hub
- ✅ **Least privilege principle** in Kubernetes manifests

### 🔧 Production Recommendations:

- Switch to non-root user in Dockerfile
- Implement proper secret management (Vault, Sealed Secrets)
- Add network policies for pod-to-pod communication
- Enable pod security standards
- Implement resource quotas and limit ranges
- Add liveness and readiness probes
- Use specific image tags instead of `latest` in production

---

## 📸 Project Screenshots

> 📷 **Note:** Screenshots demonstrating working deployments and security policies are available in the `screenshots/` directory.

---


## 👤 Author

**Ashik**

- 🐙 GitHub: [@ashikimg](https://github.com/ashikimg)
- 🐳 Docker Hub: [ashikimg](https://hub.docker.com/u/ashikimg)
- 💼 Project: Wisecow DevOps Assessment

---

## 🙏 Acknowledgments

- **Original Wisecow App** by [@nyrahul](https://github.com/nyrahul/wisecow)
- **AccuKnox** for the comprehensive assessment opportunity
- **KubeArmor Team** for excellent security documentation
- **DevOps Community** for best practices and guidance
- **Open Source Contributors** for the amazing tools and libraries

---

## 🤝 Contributing

While this is an assessment project, feedback and suggestions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

## 📞 Support

For questions or issues related to this project:

- 📫 Open an issue in the GitHub repository
- 💬 Contact via GitHub profile

---

<div align="center">

**⭐ If you found this project helpful, please consider giving it a star! ⭐**

Made with ❤️ by Ashik

</div>
