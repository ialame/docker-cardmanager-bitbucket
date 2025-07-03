# 🃏 CardManager - Docker Project

**Complete card collection management system with Bitbucket integration**

## ⚡ Quick Start

```bash
# 1. Configure SSH access to Bitbucket
# 2. Copy SSH keys to docker/ssh-keys/
# 3. Configure .env file
# 4. Start services
docker-compose up -d
```

## 📚 Documentation

- **[🇫🇷 French Documentation](docs/FR/)** - Documentation française complète
- **[🇬🇧 English Documentation](docs/EN/)** - Complete English documentation

## 🏗️ Architecture

- **GestionCarte** (Port 8080) - Main web application
- **Painter** (Port 8081) - Image processing service
- **MariaDB** (Port 3308) - Database
- **Nginx** (Port 8082) - Image server

## 🚀 Services

| Service | URL | Description |
|---------|-----|-------------|
| Main App | http://localhost:8080 | Web interface |
| API | http://localhost:8081 | Image processing |
| Images | http://localhost:8082 | Image server |

---

**This project was cleaned and optimized** ✨
