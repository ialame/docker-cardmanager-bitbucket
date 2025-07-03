# 🃏 CardManager - Gestionnaire de Collections de Cartes

<div align="center">

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![MariaDB](https://img.shields.io/badge/MariaDB-11.2-orange?logo=mariadb)](https://mariadb.org)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2-green?logo=spring)](https://spring.io)
[![Nginx](https://img.shields.io/badge/Nginx-Alpine-brightgreen?logo=nginx)](https://nginx.org)

**Système complet de gestion de collections de cartes avec upload d'images et interface web**

[🇫🇷 Français](#français) | [🇬🇧 English](#english)

</div>

---

## 🇫🇷 Français

### ⚡ Démarrage rapide

```bash
# 1. Cloner le projet
git clone https://github.com/ialame/docker-cardmanager-bitbucket.git
cd docker-cardmanager-bitbucket

# 2. Démarrer les services
docker-compose up -d

# 3. Ouvrir l'application
open http://localhost:8080
```

**⏱️ Temps d'installation :** 5-10 minutes  
**🎯 Prêt à l'emploi** avec base de données préconfigurée

### 🌟 Fonctionnalités

- 🃏 **Gestion complète** de collections de cartes Pokemon
- 📸 **Upload et traitement** d'images haute qualité
- 🗄️ **Base de données** persistante MariaDB
- 🌐 **Interface web** moderne et intuitive
- 🔄 **API REST** pour intégrations externes
- 📦 **Déploiement Docker** en un clic

### 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GestionCarte  │    │     Painter     │    │     MariaDB     │
│   (Frontend)    │◄──►│  (Images API)   │    │   (Database)    │
│   Port: 8080    │    │   Port: 8081    │    │   Port: 3308    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │      Nginx      │
                       │ (Images Server) │
                       │   Port: 8082    │
                       └─────────────────┘
```

### 📚 Documentation

| Document | Description |
|----------|-------------|
| **[📖 Guide d'installation](docs/FR/DEPLOIEMENT-FR.md)** | Installation détaillée step-by-step |
| **[❓ FAQ](docs/FR/FAQ-FR.md)** | Questions fréquentes et solutions |
| **[🔧 Guide technique](docs/FR/TECHNIQUE-FR.md)** | Configuration avancée |

### 🚀 Scripts d'automatisation

```bash
# Démarrage
./scripts/start.sh

# Arrêt
./scripts/stop.sh

# Diagnostic
./scripts/diagnostic.sh

# Sauvegarde
./scripts/backup.sh
```

---

## 🇬🇧 English

### ⚡ Quick Start

```bash
# 1. Clone the project
git clone https://github.com/ialame/docker-cardmanager-bitbucket.git
cd docker-cardmanager-bitbucket

# 2. Start services
docker-compose up -d

# 3. Open application
open http://localhost:8080
```

**⏱️ Installation time:** 5-10 minutes  
**🎯 Ready to use** with preconfigured database

### 🌟 Features

- 🃏 **Complete management** of Pokemon card collections
- 📸 **Upload and processing** of high-quality images
- 🗄️ **Persistent database** MariaDB
- 🌐 **Modern web interface** and intuitive
- 🔄 **REST API** for external integrations
- 📦 **Docker deployment** with one click

### 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GestionCarte  │    │     Painter     │    │     MariaDB     │
│   (Frontend)    │◄──►│  (Images API)   │    │   (Database)    │
│   Port: 8080    │    │   Port: 8081    │    │   Port: 3308    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │      Nginx      │
                       │ (Images Server) │
                       │   Port: 8082    │
                       └─────────────────┘
```

### 📚 Documentation

| Document | Description |
|----------|-------------|
| **[📖 Installation Guide](docs/EN/DEPLOYMENT-EN.md)** | Detailed step-by-step installation |
| **[❓ FAQ](docs/EN/FAQ-EN.md)** | Frequently asked questions and solutions |
| **[🔧 Technical Guide](docs/EN/TECHNICAL-EN.md)** | Advanced configuration |

### 🚀 Automation Scripts

```bash
# Start
./scripts/start.sh

# Stop
./scripts/stop.sh

# Diagnostic
./scripts/diagnostic.sh

# Backup
./scripts/backup.sh
```

---

## 🔧 Configuration

### Prérequis / Prerequisites

- **Docker** 24.0+
- **Docker Compose** 2.0+
- **Git** (optionnel/optional)
- **4GB RAM** minimum

### Variables d'environnement / Environment Variables

Copiez `.env.template` vers `.env` et ajustez selon vos besoins.  
Copy `.env.template` to `.env` and adjust as needed.

```bash
# Dépôts Bitbucket / Bitbucket Repositories
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# Branches de développement / Development Branches
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# Ports réseau / Network Ports
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
DB_PORT=3308
```

---

## 🆘 Support

### 🐛 Signaler un bug / Report a Bug

1. Consultez la [FAQ](docs/FR/FAQ-FR.md) / Check the [FAQ](docs/EN/FAQ-EN.md)
2. Exécutez le diagnostic / Run diagnostic: `./scripts/diagnostic.sh`
3. Créez une issue GitHub avec les logs / Create GitHub issue with logs

### 💬 Communauté / Community

- **GitHub Issues** : Bugs et demandes de fonctionnalités / Bugs and feature requests
- **Documentation** : Guides complets / Complete guides

---

## 📄 Licence / License

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus de détails.  
This project is licensed under MIT. See [LICENSE](LICENSE) for details.

---

<div align="center">

**🎉 Développé avec ❤️ pour les collectionneurs de cartes**  
**🎉 Built with ❤️ for card collectors**

</div>