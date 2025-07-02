# 🚀 CardManager Deployment Guide

**Version:** 1.0.0  
**Last Updated:** July 2025  
**Estimated Time:** 10-15 minutes

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Quick Installation](#-quick-installation)
3. [Configuration](#-configuration)
4. [Verification](#-verification)
5. [Usage](#-usage)
6. [Maintenance](#-maintenance)
7. [Troubleshooting](#-troubleshooting)

---

## 🔧 Prerequisites

### ✅ Required Software

| Software | Minimum Version | Installation |
|----------|----------------|--------------|
| **Docker** | 24.0+ | [docker.com](https://docker.com) |
| **Docker Compose** | 2.0+ | Included with Docker Desktop |
| **Git** | 2.30+ | [git-scm.com](https://git-scm.com) |

### 💻 Operating System

- ✅ **macOS** 12+ (Monterey or newer)
- ✅ **Windows** 10/11 with WSL2
- ✅ **Linux** (Ubuntu 20.04+, Fedora 35+, etc.)

### 🔌 Network

- **Required ports:** 8080, 8081, 8082, 3307
- **Internet connection** to download GitHub repositories

---

## ⚡ Quick Installation

### 1️⃣ Clone the project

```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
```

### 2️⃣ Automatic Configuration

#### Option A: Public repositories (recommended)
```bash
cp .env.template .env
# Default values are already configured
```

#### Option B: Custom configuration
```bash
# Edit the .env file with your settings
nano .env
```

### 3️⃣ Launch

#### macOS / Linux
```bash
chmod +x start.sh
./start.sh
```

#### Windows (PowerShell)
```powershell
.\start.bat
```

### 4️⃣ Quick verification

Open your browser: **http://localhost:8080**

✅ **If the page loads → Installation successful!**

---

## ⚙️ Configuration

### 📝 Environment Variables (.env)

```bash
# === GITHUB REPOSITORIES ===
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte

# === BRANCHES ===
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main

# === DATABASE ===
# Option 1: Provided database (recommended)
DATABASE_IMAGE=custom-mariadb:latest

# Option 2: Local development database
LOCAL_DB_HOST=localhost
LOCAL_DB_PORT=3306
LOCAL_DB_NAME=dev
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou

# === AUTHENTICATION (optional) ===
# For private repositories only
GIT_TOKEN=your_github_token_here
```

### 🔐 Configuration for private repositories

If your GitHub repositories are private:

1. **Create a GitHub token:**
    - Go to GitHub → Settings → Developer settings → Personal access tokens
    - Create a token with `repo` permissions

2. **Configure the token:**
   ```bash
   echo "GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx" >> .env
   ```

---

## ✅ Verification

### 🏥 Automatic diagnosis

```bash
./scripts/diagnostic.sh
```

### 🔍 Manual verification

#### 1. Container status
```bash
docker-compose ps
```

**Expected result:**
```
NAME                    STATE     PORTS
cardmanager-mariadb     Up        0.0.0.0:3307->3306/tcp
cardmanager-painter     Up        0.0.0.0:8081->8080/tcp
cardmanager-gestion     Up        0.0.0.0:8080->8080/tcp
cardmanager-nginx       Up        0.0.0.0:8082->80/tcp
```

#### 2. Service testing

| Service | URL | Test |
|---------|-----|------|
| **Main Application** | http://localhost:8080 | Homepage |
| **Images API** | http://localhost:8081/health | `{"status":"OK"}` |
| **Images Server** | http://localhost:8082/images/ | Empty list or images |

#### 3. Logs in case of problems
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs gestioncarte
docker-compose logs painter
```

---

## 🎯 Usage

### 🌐 Service Access

| Service | URL | Description |
|---------|-----|-------------|
| **🏠 Application** | http://localhost:8080 | Main interface |
| **🖼️ Images** | http://localhost:8082/images/ | Image viewing |
| **⚙️ API** | http://localhost:8081 | Processing API |

### 📱 Application Usage

1. **Access the application:** http://localhost:8080
2. **Create a card collection**
3. **Add cards** with images
4. **Manage your collections**

### 🖼️ Image Management

- **Upload:** Via web interface
- **Viewing:** http://localhost:8082/images/
- **Storage:** Persistent Docker volume

---

## 🛠️ Maintenance

### 🔄 Maintenance Scripts

```bash
# Start services
./start.sh

# Stop services
./stop.sh

# Restart all services
./restart.sh

# Complete diagnosis
./scripts/diagnostic.sh

# Data backup
./scripts/backup.sh
```

### 💾 Backup

#### Automatic backup
```bash
./scripts/backup.sh
```

#### Manual backup
```bash
# Images
docker run --rm -v cardmanager_images:/source -v $(pwd):/backup alpine tar czf /backup/images-backup.tar.gz -C /source .

# Database
docker exec cardmanager-mariadb mysqldump -u ia -pfoufafou dev > database-backup.sql
```

### 🔄 Update

```bash
# Stop services
docker-compose down

# Get latest changes
git pull origin main

# Rebuild and restart
docker-compose build --no-cache
docker-compose up -d
```

---

## 🆘 Troubleshooting

### ❌ Common Issues

#### 1. Port occupied error
```bash
# Check ports
netstat -tulpn | grep -E ':(8080|8081|8082|3307)'

# Solution: Stop conflicting services or change ports
```

#### 2. Docker memory error
```bash
# Check disk space
docker system df

# Clean if necessary
docker system prune -f
```

#### 3. GitHub authentication problem
```bash
# Check token
echo $GIT_TOKEN

# Verify token permissions on GitHub
```

#### 4. Service won't start
```bash
# See detailed logs
docker-compose logs [service_name]

# Restart specific service
docker-compose restart [service_name]
```

### 🔍 Diagnostic Commands

```bash
# General status
docker-compose ps
docker-compose logs --tail=50

# Disk space
docker system df

# Network connectivity
curl -I http://localhost:8080
curl -I http://localhost:8081/health

# Processes and ports
ps aux | grep docker
netstat -tulpn | grep docker
```

### 📞 Support

#### 🆘 For persistent issues

1. **Run diagnostics:**
   ```bash
   ./scripts/diagnostic.sh > diagnostic-report.txt
   ```

2. **Gather information:**
    - File `diagnostic-report.txt`
    - Logs: `docker-compose logs > logs.txt`
    - Configuration: `cat .env` (without tokens)

3. **Report the issue:**
    - Create a GitHub issue
    - Attach diagnostic files

#### 📚 Additional Resources

- **Docker Documentation:** [docs.docker.com](https://docs.docker.com)
- **Git Guide:** [git-scm.com/doc](https://git-scm.com/doc)
- **Project Repositories:**
    - Mason: https://github.com/ialame/mason
    - Painter: https://github.com/ialame/painter
    - GestionCarte: https://github.com/ialame/gestioncarte

---

## 📈 Optimization

### ⚡ Performance

```bash
# Allocate more resources to Docker
# Docker Desktop → Settings → Resources

# Optimize Docker images
docker system prune -f
```

### 🔒 Security

```bash
# Check exposed ports
docker-compose ps

# Use tokens with minimal permissions
# GitHub → Settings → Developer settings → Fine-grained tokens
```

---

**✨ Congratulations! Your CardManager installation is operational!**

> 💡 **Tip:** Bookmark http://localhost:8080 for quick access

---

*Guide created with ❤️ for the CardManager community*