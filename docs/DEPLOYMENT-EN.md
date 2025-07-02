# 🚀 CardManager Deployment Guide

**Version:** 1.0.0
**Date:** July 2025
**Level:** Beginner to Advanced

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick installation](#quick-installation)
3. [Detailed installation](#detailed-installation)
4. [Verification](#verification)
5. [First usage](#first-usage)
6. [Maintenance](#maintenance)
7. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Minimum system requirements
- **RAM:** 4 GB minimum (8 GB recommended)
- **Storage:** 10 GB free space
- **OS:** Windows 10+, macOS 10.15+, or modern Linux
- **Network:** Internet connection for initial download

### Required software

#### Docker Desktop (mandatory)

**Windows/macOS:**
1. Download from [docker.com](https://www.docker.com/products/docker-desktop)
2. Install and restart your computer
3. Start Docker Desktop

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```
*Log out and log back in after this command*

#### Git (optional)
If Git is not installed:
- **Windows:** [git-scm.com](https://git-scm.com/)
- **macOS:** `xcode-select --install`
- **Linux:** `sudo apt install git` (Ubuntu) or equivalent

---

## ⚡ Quick installation (5 minutes)

### Option 1: With Git
```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
docker-compose up -d
```

### Option 2: Without Git
1. Download ZIP from GitHub
2. Extract to a folder
3. Open terminal in that folder
4. Run: `docker-compose up -d`

### ⏳ Wait times
- **First launch:** 10-15 minutes (downloading images)
- **Subsequent launches:** 1-2 minutes

### ✅ Quick verification
Open http://localhost:8080 - You should see the CardManager interface

---

## 🔧 Detailed installation

### Step 1: Download the project

**With Git:**
```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
```

**Without Git:**
1. Go to https://github.com/ialame/docker-cardmanager-github
2. Click "Code" → "Download ZIP"
3. Extract to a folder of your choice
4. Open terminal/command prompt in that folder

### Step 2: Docker verification

```bash
# Check Docker is working
docker --version
docker-compose --version

# Test Docker
docker run hello-world
```

If these commands fail, restart Docker Desktop.

### Step 3: Configuration (optional)

**Custom ports:**
If default ports are occupied, modify `docker-compose.yml`:
```yaml
ports:
  - "8080:8080"  # Application → "9080:8080" for example
  - "8081:8081"  # Painter → "9081:8081"
  - "8082:80"    # Images → "9082:80"
  - "3307:3306"  # Database → "3308:3306"
```

**Existing data:**
To import an existing database:
1. Place your SQL file in `init-db/`
2. The file will be imported automatically on first startup

### Step 4: Launch services

```bash
# Launch in background
docker-compose up -d

# OR launch with visible logs
docker-compose up
```

### Step 5: Monitor startup

```bash
# View service status
docker-compose ps

# Follow logs
docker-compose logs -f

# Logs for specific service
docker-compose logs -f gestioncarte
```

---

## ✅ Deployment verification

### Automatic tests

1. **Main application:**
   - URL: http://localhost:8080
   - ✅ You should see the CardManager interface

2. **Image service:**
   - URL: http://localhost:8082/images/
   - ✅ You should see an image index

3. **Painter API:**
   - URL: http://localhost:8081/actuator/health
   - ✅ You should see `{"status":"UP"}`

### Manual tests

```bash
# Check all services
docker-compose ps

# Test database
docker-compose exec mariadb-standalone mysql -u ia -p'foufafou' -e "SELECT 'DB OK';"

# Check volumes
docker volume ls | grep cardmanager
```

### In case of error

```bash
# View error logs
docker-compose logs

# Restart specific service
docker-compose restart painter

# Complete restart
docker-compose down
docker-compose up -d
```

---

## 🎯 First usage

### Connect to the application

1. Open http://localhost:8080
2. The CardManager interface appears
3. Start exploring the features

### Upload images

1. Use the upload function in the interface
2. Images are automatically:
   - Saved to disk
   - Indexed in database
   - Visible at http://localhost:8082/images/

### Import existing data

If you have data to import:
1. Stop services: `docker-compose down`
2. Place your SQL files in `init-db/`
3. Restart: `docker-compose up -d`

---

## 🛠️ Maintenance

### Basic commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# View logs
docker-compose logs -f

# Update
git pull
docker-compose pull
docker-compose up -d --build
```

### Backup

**Database backup:**
```bash
docker-compose exec mariadb-standalone mysqldump -u ia -p'foufafou' dev > backup-$(date +%Y%m%d).sql
```

**Images backup:**
```bash
docker run --rm -v cardmanager_images:/data -v $(pwd):/backup alpine tar czf /backup/images-backup-$(date +%Y%m%d).tar.gz /data
```

### Cleanup

```bash
# Stop and remove containers
docker-compose down

# Also remove volumes (WARNING: data loss)
docker-compose down --volumes

# Clean unused Docker images
docker system prune -f
```

---

## 🚨 Troubleshooting

### Common issues

#### "Port already in use"
```bash
# Find which process uses the port
lsof -i :8080
# or on Windows
netstat -ano | findstr :8080

# Change port in docker-compose.yml
ports:
  - "9080:8080"  # Instead of 8080:8080
```

#### "Cannot connect to Docker daemon"
- Start Docker Desktop
- On Linux: `sudo systemctl start docker`

#### Services not starting
```bash
# View detailed logs
docker-compose logs service_name

# Clean restart
docker-compose down
docker-compose up -d
```

#### "No space left on device"
```bash
# Clean Docker
docker system prune -a -f
docker volume prune -f
```

#### Images not displaying
```bash
# Check nginx service
docker-compose logs nginx-images

# Check volume permissions
docker-compose exec nginx-images ls -la /usr/share/nginx/html/images/
```

### Automatic diagnostic

Create this script for automatic diagnosis:

```bash
#!/bin/bash
echo "🔍 CardManager Diagnostic"
echo "========================"

echo "Docker version:"
docker --version

echo -e "\nServices status:"
docker-compose ps

echo -e "\nPort usage:"
lsof -i :8080,:8081,:8082,:3307 || netstat -ano | findstr ":8080 :8081 :8082 :3307"

echo -e "\nDisk space:"
df -h

echo -e "\nDocker space:"
docker system df
```

### Support contacts

1. **Documentation:** Re-read this guide and the [FAQ](FAQ-EN.md)
2. **GitHub Issues:** [Report a bug](https://github.com/ialame/docker-cardmanager-github/issues)
3. **Logs:** Always include logs with `docker-compose logs`

---

## 📞 Support and resources

### Useful resources
- **[English FAQ](FAQ-EN.md)** - Frequently asked questions
- **[Technical guide](TECHNICAL-EN.md)** - Advanced configuration
- **[Docker documentation](https://docs.docker.com/)** - Official Docker documentation

### Community
- **GitHub Issues:** For bugs and feature requests
- **GitHub Discussions:** For general questions

---

**🎉 Congratulations! Your CardManager installation is ready!**

*Built with ❤️ for card collectors*
