

# Wisecow DevOps Assessment

A comprehensive DevOps project demonstrating containerization, Kubernetes deployment, CI/CD automation, system monitoring scripts, and zero-trust security policies.

## 📋 Table of Contents
- [Overview](#overview)
- [Problem Statement 1: Containerization & Kubernetes Deployment](#problem-statement-1-containerization--kubernetes-deployment)
- [Problem Statement 2: System Administration Scripts](#problem-statement-2-system-administration-scripts)
- [Problem Statement 3: Zero-Trust Security Policy](#problem-statement-3-zero-trust-security-policy)
- [Technologies Used](#technologies-used)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
---

## 🎯 Overview

This project showcases the deployment and automation of the Wisecow application - a fortune-telling cow web server. The implementation includes containerization, Kubernetes orchestration, automated CI/CD pipelines, monitoring scripts, and security policies following DevOps best practices.

**Live Application:** The Wisecow app displays random fortune quotes in ASCII cow art, accessible via web browser.

---

## 🐳 Problem Statement 1: Containerization & Kubernetes Deployment

### Objectives Completed
✅ Dockerized the Wisecow application  
✅ Created Kubernetes manifests for deployment  
✅ Implemented CI/CD pipeline with GitHub Actions  
✅ Deployed to Kubernetes cluster (Kind)  
✅ Exposed application as a Kubernetes service  

### Implementation Details

#### Dockerfile
```dockerfile
FROM ubuntu:22.04

# Install prerequisites
RUN apt-get update && \
    apt-get install -y fortune-mod cowsay netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Set PATH for cowsay
ENV PATH="/usr/games:${PATH}"

# Copy application
WORKDIR /app
COPY wisecow.sh .
RUN chmod +x wisecow.sh

# Expose port
EXPOSE 4499

# Run application
CMD ["./wisecow.sh"]
```

#### Kubernetes Resources
- **Deployment:** Manages 2 replicas for high availability
- **Service:** NodePort service exposing the application
- **Resource Limits:** Configured CPU and memory limits for stability

#### CI/CD Pipeline
- **Trigger:** Automated on push to main branch
- **Actions:**
  - Builds Docker image
  - Pushes to Docker Hub
  - Tags with commit SHA and 'latest'
  - Uses GitHub Actions secrets for secure authentication

### Deployment Commands

```bash
# Build and push Docker image
docker build -t ashikimg/wisecow:latest .
docker push ashikimg/wisecow:latest

# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify deployment
kubectl get pods
kubectl get svc wisecow-service

# Access application
kubectl port-forward service/wisecow-service 8080:80
# Visit: http://localhost:8080
```

### Testing Environment Notes
- **Image Pull Policy:** Uses 'latest' tag for testing; production should use commit SHA tags for version control

---

## 📜 Problem Statement 2: System Administration Scripts

### 1️⃣ Application Health Checker

**Purpose:** Monitors application uptime and availability via HTTP status code checks.

**Features:**
- ✅ HTTP status code validation (200-299 = UP, others = DOWN)
- ✅ Color-coded console output
- ✅ Timestamped logging to file
- ✅ Configurable timeout settings
- ✅ Continuous monitoring mode
- ✅ Connection failure detection

**Usage:**
```bash
# Single check
./scripts/app_health_checker.sh http://localhost:8080

# Continuous monitoring (every 10 seconds)
./scripts/app_health_checker.sh http://localhost:8080 -i 10

# Custom timeout
./scripts/app_health_checker.sh http://example.com -t 30
```

**Example Output:**
```
Application Health Checker
==========================
Monitoring: http://localhost:8080
Log file: app_health.log

[2025-11-23 16:00:00] UP - http://localhost:8080 - Status: 200
```

### 2️⃣ Automated Backup Solution

**Purpose:** Automates directory backups to local or remote destinations with comprehensive logging.

**Features:**
- ✅ Compressed tar.gz backups
- ✅ Timestamp-based naming
- ✅ Local and remote (SCP) backup support
- ✅ Automatic backup rotation (keeps last N backups)
- ✅ Success/failure reporting
- ✅ Detailed logging with timestamps

**Usage:**
```bash
# Local backup
./scripts/automated_backup.sh -s /var/www -d /backups -n website_backup

# Remote backup via SCP
./scripts/automated_backup.sh -s /var/www -d /backups -r user@remote-server -n website_backup

# Custom retention (keep last 10 backups)
./scripts/automated_backup.sh -s /data -d /backups -n data_backup -k 10
```

**Backup Naming Convention:**
```
<backup_name>_<YYYYMMDD_HHMMSS>.tar.gz
Example: wisecow_project_20251123_160000.tar.gz
```

**Log Output:**
```
[2025-11-23 16:15:49] [INFO] Starting backup of /root/test_backup_source
[2025-11-23 16:15:49] [SUCCESS] Backup completed successfully
[2025-11-23 16:15:49] [INFO] Backup size: 4.0K
[2025-11-23 16:15:49] [INFO] Cleaning up old backups, keeping last 5
```

---

## 🔒 Problem Statement 3: Zero-Trust Security Policy

### KubeArmor Security Implementation

**Purpose:** Implements runtime security enforcement following zero-trust principles for the Wisecow application.

### Security Controls

#### Process Restrictions
| Process | Action | Reason |
|---------|--------|--------|
| `/usr/games/cowsay` | Allow | Required for cow ASCII art |
| `/usr/games/fortune` | Allow | Required for fortune quotes |
| `/bin/bash` | Allow | Required for script execution |
| `/usr/bin/nc` | Allow | Required for network communication |
| All others | **Block** | Zero-trust default deny |

#### File Access Controls
| Path/Directory | Action | Reason |
|----------------|--------|--------|
| `/app/` | Allow | Application files |
| `/tmp/` | Allow | Temporary storage |
| `/etc/passwd` | **Block** | Prevent credential access |
| `/etc/shadow` | **Block** | Prevent password hash access |
| All others | **Block** | Zero-trust default deny |

#### Network Controls
| Protocol | Action | Reason |
|----------|--------|--------|
| TCP | Allow | Required for HTTP service |
| UDP | **Block** | Not needed for application |

### Policy Application

```bash
# Install KubeArmor
karmor install

# Apply security policy
kubectl apply -f kubearmor-policies/wisecow-security-policy.yaml

# Monitor policy violations
karmor logs --follow

# View active policies
kubectl get kubearmorpolicies
```

### Expected Security Behavior
- ✅ Wisecow application runs normally with allowed processes
- ❌ Attempts to access `/etc/passwd` or `/etc/shadow` are blocked
- ❌ Attempts to execute unauthorized binaries are blocked
- ❌ UDP network traffic is blocked
- 📝 All violations are logged for security monitoring

### Testing Notes
**Resource Requirements for Full Testing:**
- Minimum 2 vCPUs (AWS t2.small or equivalent)
- 2GB+ RAM
- Kubernetes cluster with KubeArmor support

**Current Status:** Policy created and validated.

---

## 🛠️ Technologies Used

| Category | Technologies |
|----------|-------------|
| **Containerization** | Docker, Docker Hub |
| **Orchestration** | Kubernetes, Kind |
| **CI/CD** | GitHub Actions |
| **Security** | KubeArmor |
| **Scripting** | Bash |
| **Infrastructure** | AWS EC2 (Amazon Linux 2023) |
| **Version Control** | Git, GitHub |

---

## 🚀 Getting Started

### Prerequisites
- Docker installed and running
- kubectl installed
- Kind or Minikube for local Kubernetes
- Git for version control
- (Optional) AWS account for EC2 deployment

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/ashikimg/wisecow-devops.git
cd wisecow-devops
```

2. **Build and run with Docker**
```bash
docker build -t wisecow:latest .
docker run -d -p 4499:4499 wisecow:latest
curl http://localhost:4499
```

3. **Deploy to Kubernetes**
```bash
# Create Kind cluster
kind create cluster --name wisecow-cluster

# Load image
kind load docker-image ashikimg/wisecow:latest --name wisecow-cluster

# Deploy
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Access
kubectl port-forward service/wisecow-service 8080:80
```

4. **Test monitoring scripts**
```bash
# Health check
./scripts/app_health_checker.sh http://localhost:8080

# Backup
./scripts/automated_backup.sh -s ./app -d ./backups -n test
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
│   └── service.yaml                  # Kubernetes service manifest
├── scripts/
│   ├── app_health_checker.sh         # Application health monitoring
│   ├── automated_backup.sh           # Backup automation script
│   ├── app_health.log               # Health check logs
│   └── backup.log                   # Backup operation logs
├── kubearmor-policies/
│   ├── wisecow-security-policy.yaml # Zero-trust security policy
│   └── README.md                    # Policy documentation
├── Dockerfile                        # Container image definition
├── wisecow.sh                       # Main application script
├── LICENSE                          # MIT License
└── README.md                        # This file
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

**Trigger:** Push or Pull Request to main branch

**Steps:**
1. Checkout code
2. Set up Docker Buildx
3. Login to Docker Hub (using secrets)
4. Extract metadata and create tags
5. Build Docker image
6. Push to Docker Hub with tags:
   - `latest` (for main branch)
   - `main-<commit-sha>` (for version tracking)

**Secrets Required:**
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password/token

---

## 📊 Monitoring & Logging

### Application Logs
```bash
# View pod logs
kubectl logs -f deployment/wisecow-deployment

# View health check logs
cat scripts/app_health.log

# View backup logs
cat scripts/backup.log
```

### Security Monitoring
```bash
# View KubeArmor alerts
karmor logs --follow

# Check policy violations
kubectl logs -n kubearmor -l app=kubearmor
```

---

## 🔐 Security Best Practices Implemented
- ✅ Docker image configured; runs as root (recommend switching to non-root for production)
- ✅ Resource limits configured to prevent resource exhaustion
- ✅ Zero-trust security policies with KubeArmor
- ✅ Secrets management via GitHub Actions secrets
- ✅ Minimal base image (Ubuntu 22.04) with only required packages
- ✅ Network policies restricting unnecessary protocols
- ✅ File access restrictions preventing sensitive data exposure

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Ashik**
- GitHub: [@ashikimg](https://github.com/ashikimg)
- Docker Hub: [ashikimg](https://hub.docker.com/u/ashikimg)

---

## 🙏 Acknowledgments

- Original Wisecow application by [@nyrahul](https://github.com/nyrahul/wisecow)
- AccuKnox for the assessment opportunity
- KubeArmor team for excellent security documentation
- DevOps community for best practices and guidance

---

## 📞 Support

For questions or issues:
- Open an issue in this repository
- Contact via GitHub profile

---
