# 🃏 CardManager - Version Bitbucket

[![Docker](https://img.shields.io/badge/docker-ready-green.svg)](https://www.docker.com/)
[![Bitbucket](https://img.shields.io/badge/bitbucket-ready-blue.svg)](https://bitbucket.org/)
[![SSH](https://img.shields.io/badge/auth-ssh-orange.svg)](#configuration-ssh)

**Version adaptée pour les dépôts Bitbucket privés de PCaFXC**

## 🚀 Démarrage ultra-rapide

### Prérequis
- Docker Desktop installé
- Accès SSH configuré pour Bitbucket
- Clé SSH ajoutée à votre compte Bitbucket

### Installation en 3 étapes

```bash
# 1. Cloner ce projet
git clone https://github.com/votre-compte/docker-cardmanager-bitbucket.git
cd docker-cardmanager-bitbucket

# 2. Démarrer (configure automatiquement l'environnement)
chmod +x start-bitbucket.sh
./start-bitbucket.sh

# 3. Accéder à l'application
# http://localhost:8080
```

⏱️ **Temps d'installation :** 10-15 minutes (premier démarrage)

---

## 🏗️ Architecture

| Service | Port | Source Bitbucket | Branche |
|---------|------|------------------|---------|
| **GestionCarte** | 8080 | `pcafxc/gestioncarte` | `feature/card-manager-511` |
| **Painter** | 8081 | `pcafxc/painter` | `feature/card-manager-511` |
| **Mason** | - | `pcafxc/mason` | `feature/RETRIEVER-511` |
| **MariaDB** | 3307 | - | Base locale |
| **Nginx** | 8082 | - | Serveur d'images |

### 🔄 Workflow de build
```
Dépôts Bitbucket SSH → Clone → Maven Build → Docker Images → Services
```

---

## ⚙️ Configuration

### Configuration SSH (obligatoire)

1. **Générer une clé SSH** (si pas encore fait) :
   ```bash
   ssh-keygen -t ed25519 -C "votre.email@example.com"
   ```

2. **Ajouter la clé à Bitbucket** :
   ```bash
   # Copier la clé publique
   cat ~/.ssh/id_ed25519.pub
   
   # L'ajouter dans Bitbucket → Settings → SSH keys
   ```

3. **Tester la connexion** :
   ```bash
   ssh -T git@bitbucket.org
   # Doit afficher : "authenticated via ssh"
   ```

### Variables d'environnement (.env)

Le fichier `.env` est créé automatiquement avec :

```bash
# Dépôts Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# Branches de développement
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# Base de données locale
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou
LOCAL_DB_NAME=dev
```

---

## 🛠️ Commandes utiles

### Scripts principaux
```bash
./start-bitbucket.sh        # 🚀 Démarrage complet
./diagnostic-bitbucket.sh   # 🔍 Diagnostic complet
```

### Docker Compose
```bash
docker-compose ps           # État des services
docker-compose logs -f      # Logs en temps réel
docker-compose down         # Arrêter tous les services
docker-compose restart      # Redémarrer
```

### Debug spécifique
```bash
# Logs d'un service spécifique
docker-compose logs -f gestioncarte
docker-compose logs -f painter

# Reconstruire une image
docker-compose build --no-cache gestioncarte

# Test SSH dans un conteneur
docker run --rm -it -v ~/.ssh:/root/.ssh alpine/git ssh -T git@bitbucket.org
```

---

## 🎯 URLs d'accès

| Service | URL | Description |
|---------|-----|-------------|
| **Application** | http://localhost:8080 | Interface principale CardManager |
| **API Painter** | http://localhost:8081 | Service de traitement d'images |
| **Images** | http://localhost:8082/images/ | Galerie d'images uploadées |
| **Health Checks** | http://localhost:8080/actuator/health | Santé de l'application |

---

## 🔧 Développement

### Utiliser une branche différente

Modifiez `.env` et reconstruisez :
```bash
# Modifier la branche dans .env
PAINTER_BRANCH=feature/nouvelle-feature

# Reconstruire
docker-compose build --no-cache painter
docker-compose up -d
```

### Base de données locale

Pour utiliser votre MariaDB local existant :
```bash
# Connexion à votre base
mysql -h localhost -P 3306 -u ia -pfoufafou dev

# Dans .env, configurez :
LOCAL_DB_HOST=host.docker.internal  # Pour accéder à l'hôte depuis Docker
```

### Développement avec hot-reload

Pour développer sans rebuild constant :
```bash
# Monter le code source en volume (ajoutez dans docker-compose.yml)
volumes:
  - ./src:/usr/src/app/src
```

---

## 🐛 Dépannage

### Problèmes fréquents

#### 1. Erreur d'authentification SSH
```bash
# Vérifier la connexion Bitbucket
ssh -T git@bitbucket.org

# Démarrer SSH agent si nécessaire
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
```

#### 2. Build qui échoue
```bash
# Nettoyer et reconstruire
docker-compose down
docker system prune -f
./start-bitbucket.sh
```

#### 3. Services qui ne démarrent pas
```bash
# Diagnostic complet
./diagnostic-bitbucket.sh

# Logs détaillés
docker-compose logs
```

#### 4. Port déjà utilisé
```bash
# Trouver le processus
lsof -i :8080

# Ou changer le port dans docker-compose.yml
ports:
  - "9080:8080"  # Au lieu de 8080:8080
```

### Debug SSH dans Docker

```bash
# Test SSH dans un conteneur
docker run --rm -it \
  -v ~/.ssh:/root/.ssh:ro \
  -v $(pwd):/workspace \
  alpine/git sh

# Dans le conteneur :
ssh -T git@bitbucket.org
git clone git@bitbucket.org:pcafxc/mason.git
```

---

## 📊 Monitoring

### Health Checks automatiques

Les services incluent des health checks :
```bash
# Vérifier la santé
docker-compose ps

# Status dét