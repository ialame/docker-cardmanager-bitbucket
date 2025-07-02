# CardManager - Système de Gestion de Cartes

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/ialame/docker-cardmanager-github)
[![Docker](https://img.shields.io/badge/docker-ready-green.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

## 🚀 Démarrage ultra-rapide

### macOS / Linux
```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
./start.sh
```

### Windows
```cmd
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
start.bat
```

**Accès immédiat :** http://localhost:8080

---

## 📚 Documentation complète

### 🇫🇷 Guides français
- 📖 **[Guide de déploiement complet](GUIDE-DEPLOIEMENT-FR.md)** - Installation, configuration, dépannage

### 🇺🇸 English guides
- 📖 **[Complete deployment guide](DEPLOYMENT-GUIDE-EN.md)** - Installation, configuration, troubleshooting

### 🔧 Documentation technique
- ⚙️ **[Configuration avancée](docs/CONFIGURATION.md)**
- 🐛 **[Dépannage](docs/TROUBLESHOOTING.md)**
- 🔄 **[Guide de mise à jour](docs/UPDATE.md)**

---

## 🏗️ Architecture

| Service | Port | Rôle |
|---------|------|------|
| **GestionCarte** | 8080 | 🏠 Application principale |
| **Painter** | 8081 | 🎨 Service de traitement d'images |
| **Nginx** | 8082 | 🖼️ Serveur d'images |
| **MariaDB** | 3307 | 🗄️ Base de données |

### 🔄 Workflow
```
GitHub Repos → Docker Build → Services → Application Web
```

---

## 🛠️ Scripts utiles

```bash
./start.sh           # 🚀 Démarrer tous les services
./stop.sh            # ⏹️ Arrêter tous les services  
./restart.sh         # 🔄 Redémarrer tous les services
./scripts/backup.sh  # 💾 Sauvegarder les données
./scripts/diagnostic.sh # 🏥 Diagnostic automatique
```

---

## ⚡ Utilisation quotidienne

### 🎯 Accès rapide
- **Application :** http://localhost:8080
- **Images :** http://localhost:8082/images/
- **API :** http://localhost:8081

### 📱 Fonctionnalités principales
- ✅ Gestion de collections de cartes
- ✅ Upload et traitement d'images
- ✅ Interface web intuitive
- ✅ Stockage persistant

---

## 🔧 Configuration personnalisée

### 📝 Fichier .env
```bash
# Dépôts GitHub (modifiables)
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte

# Branches (modifiables)
MASON_BRANCH=main
PAINTER_BRANCH=main  
GESTIONCARTE_BRANCH=main

# Base de données (auto-configurée)
LOCAL_DB_HOST=localhost
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou
```

### 🔐 Dépôts privés
Si vos dépôts sont privés, ajoutez un token GitHub :
```bash
echo "GIT_TOKEN=ghp_xxxxxxxxxxxx" >> .env
```

---

## 🆘 Support rapide

### ❓ Problème courant
1. **Port déjà utilisé :** Changez les ports dans `docker-compose.yml`
2. **Service ne démarre pas :** `docker-compose logs [service]`
3. **Page inaccessible :** Vérifiez `docker-compose ps`

### 📞 Aide détaillée
- 🇫🇷 **Problème ?** → [Guide français](GUIDE-DEPLOIEMENT-FR.md#-dépannage)
- 🇺🇸 **Issue ?** → [English guide](DEPLOYMENT-GUIDE-EN.md#-troubleshooting)
- 🐛 **Bug ?** → [Créer une issue](https://github.com/ialame/docker-cardmanager-github/issues)

---

## 🎯 Structure du projet

```
docker-cardmanager-github/
├── 📋 README.md                    # Ce fichier
├── 🇫🇷 GUIDE-DEPLOIEMENT-FR.md      # Guide français complet
├── 🇺🇸 DEPLOYMENT-GUIDE-EN.md       # Guide anglais complet
├── ⚙️ docker-compose.yml           # Configuration services
├── 🔧 .env.template                # Template de configuration
├── 📁 docker/                      # Dockerfiles des services
│   ├── mason/Dockerfile
│   ├── painter/Dockerfile
│   └── gestioncarte/Dockerfile
├── 📁 scripts/                     # Scripts utilitaires
│   ├── diagnostic.sh
│   ├── backup.sh
│   └── setup.sh
└── 📁 docs/                        # Documentation technique
    ├── CONFIGURATION.md
    ├── TROUBLESHOOTING.md
    └── UPDATE.md
```

---

## 🌟 Développé pour vous

**CardManager** simplifie la gestion de collections de cartes avec une architecture moderne et une installation en 1 clic.

> 💡 **Astuce :** Bookmarquez http://localhost:8080 pour un accès instantané !

---

**✨ Prêt à commencer ? Suivez le guide de votre langue !**

*Projet maintenu avec ❤️ par la communauté*