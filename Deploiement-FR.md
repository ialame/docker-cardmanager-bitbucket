# 🚀 Guide de Déploiement CardManager

**Version :** 1.0.0  
**Dernière mise à jour :** Juillet 2025  
**Temps estimé :** 10-15 minutes

## 📋 Table des matières

1. [Prérequis](#-prérequis)
2. [Installation rapide](#-installation-rapide)
3. [Configuration](#-configuration)
4. [Vérification](#-vérification)
5. [Utilisation](#-utilisation)
6. [Maintenance](#-maintenance)
7. [Dépannage](#-dépannage)

---

## 🔧 Prérequis

### ✅ Logiciels requis

| Logiciel | Version minimale | Installation |
|----------|------------------|--------------|
| **Docker** | 24.0+ | [docker.com](https://docker.com) |
| **Docker Compose** | 2.0+ | Inclus avec Docker Desktop |
| **Git** | 2.30+ | [git-scm.com](https://git-scm.com) |

### 💻 Système d'exploitation

- ✅ **macOS** 12+ (Monterey ou plus récent)
- ✅ **Windows** 10/11 avec WSL2
- ✅ **Linux** (Ubuntu 20.04+, Fedora 35+, etc.)

### 🔌 Réseau

- **Ports requis :** 8080, 8081, 8082, 3307
- **Connexion internet** pour télécharger les dépôts GitHub

---

## ⚡ Installation rapide

### 1️⃣ Cloner le projet

```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
```

### 2️⃣ Configuration automatique

#### Option A : Dépôts publics (recommandé)
```bash
cp .env.template .env
# Les valeurs par défaut sont déjà configurées
```

#### Option B : Configuration personnalisée
```bash
# Éditer le fichier .env avec vos paramètres
nano .env
```

### 3️⃣ Démarrage

#### macOS / Linux
```bash
chmod +x start.sh
./start.sh
```

#### Windows (PowerShell)
```powershell
.\start.bat
```

### 4️⃣ Vérification rapide

Ouvrez votre navigateur : **http://localhost:8080**

✅ **Si la page s'affiche → Installation réussie !**

---

## ⚙️ Configuration

### 📝 Variables d'environnement (.env)

```bash
# === DÉPÔTS GITHUB ===
MASON_REPO_URL=https://github.com/ialame/mason
PAINTER_REPO_URL=https://github.com/ialame/painter
GESTIONCARTE_REPO_URL=https://github.com/ialame/gestioncarte

# === BRANCHES ===
MASON_BRANCH=main
PAINTER_BRANCH=main
GESTIONCARTE_BRANCH=main

# === BASE DE DONNÉES ===
# Option 1: Base fournie (recommandé)
DATABASE_IMAGE=custom-mariadb:latest

# Option 2: Base locale de développement
LOCAL_DB_HOST=localhost
LOCAL_DB_PORT=3306
LOCAL_DB_NAME=dev
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou

# === AUTHENTIFICATION (optionnel) ===
# Pour les dépôts privés uniquement
GIT_TOKEN=your_github_token_here
```

### 🔐 Configuration pour dépôts privés

Si vos dépôts GitHub sont privés :

1. **Créer un token GitHub :**
    - Aller sur GitHub → Settings → Developer settings → Personal access tokens
    - Créer un token avec permissions `repo`

2. **Configurer le token :**
   ```bash
   echo "GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx" >> .env
   ```

---

## ✅ Vérification

### 🏥 Diagnostic automatique

```bash
./scripts/diagnostic.sh
```

### 🔍 Vérification manuelle

#### 1. État des conteneurs
```bash
docker-compose ps
```

**Résultat attendu :**
```
NAME                    STATE     PORTS
cardmanager-mariadb     Up        0.0.0.0:3307->3306/tcp
cardmanager-painter     Up        0.0.0.0:8081->8080/tcp
cardmanager-gestion     Up        0.0.0.0:8080->8080/tcp
cardmanager-nginx       Up        0.0.0.0:8082->80/tcp
```

#### 2. Test des services

| Service | URL | Test |
|---------|-----|------|
| **Application principale** | http://localhost:8080 | Page d'accueil |
| **API Images** | http://localhost:8081/health | `{"status":"OK"}` |
| **Serveur Images** | http://localhost:8082/images/ | Liste vide ou images |

#### 3. Logs en cas de problème
```bash
# Tous les services
docker-compose logs

# Service spécifique
docker-compose logs gestioncarte
docker-compose logs painter
```

---

## 🎯 Utilisation

### 🌐 Accès aux services

| Service | URL | Description |
|---------|-----|-------------|
| **🏠 Application** | http://localhost:8080 | Interface principale |
| **🖼️ Images** | http://localhost:8082/images/ | Consultation des images |
| **⚙️ API** | http://localhost:8081 | API de traitement |

### 📱 Utilisation de l'application

1. **Accéder à l'application :** http://localhost:8080
2. **Créer une collection** de cartes
3. **Ajouter des cartes** avec images
4. **Gérer vos collections**

### 🖼️ Gestion des images

- **Upload :** Via l'interface web
- **Consultation :** http://localhost:8082/images/
- **Stockage :** Volume Docker persistant

---

## 🛠️ Maintenance

### 🔄 Scripts de maintenance

```bash
# Démarrer les services
./start.sh

# Arrêter les services
./stop.sh

# Redémarrer tous les services
./restart.sh

# Diagnostic complet
./scripts/diagnostic.sh

# Sauvegarde des données
./scripts/backup.sh
```

### 💾 Sauvegarde

#### Sauvegarde automatique
```bash
./scripts/backup.sh
```

#### Sauvegarde manuelle
```bash
# Images
docker run --rm -v cardmanager_images:/source -v $(pwd):/backup alpine tar czf /backup/images-backup.tar.gz -C /source .

# Base de données
docker exec cardmanager-mariadb mysqldump -u ia -pfoufafou dev > database-backup.sql
```

### 🔄 Mise à jour

```bash
# Arrêter les services
docker-compose down

# Récupérer les dernières modifications
git pull origin main

# Reconstruire et redémarrer
docker-compose build --no-cache
docker-compose up -d
```

---

## 🆘 Dépannage

### ❌ Problèmes fréquents

#### 1. Erreur de port occupé
```bash
# Vérifier les ports
netstat -tulpn | grep -E ':(8080|8081|8082|3307)'

# Solution: Arrêter les services conflictuels ou changer les ports
```

#### 2. Erreur de mémoire Docker
```bash
# Vérifier l'espace disque
docker system df

# Nettoyer si nécessaire
docker system prune -f
```

#### 3. Problème d'authentification GitHub
```bash
# Vérifier le token
echo $GIT_TOKEN

# Vérifier les permissions du token sur GitHub
```

#### 4. Service qui ne démarre pas
```bash
# Voir les logs détaillés
docker-compose logs [service_name]

# Redémarrer un service spécifique
docker-compose restart [service_name]
```

### 🔍 Commandes de diagnostic

```bash
# État général
docker-compose ps
docker-compose logs --tail=50

# Espace disque
docker system df

# Connectivité réseau
curl -I http://localhost:8080
curl -I http://localhost:8081/health

# Processus et ports
ps aux | grep docker
netstat -tulpn | grep docker
```

### 📞 Support

#### 🆘 En cas de problème persistant

1. **Exécuter le diagnostic :**
   ```bash
   ./scripts/diagnostic.sh > diagnostic-report.txt
   ```

2. **Rassembler les informations :**
    - Fichier `diagnostic-report.txt`
    - Logs : `docker-compose logs > logs.txt`
    - Configuration : `cat .env` (sans les tokens)

3. **Signaler le problème :**
    - Créer une issue sur GitHub
    - Joindre les fichiers de diagnostic

#### 📚 Resources supplémentaires

- **Documentation Docker :** [docs.docker.com](https://docs.docker.com)
- **Guide Git :** [git-scm.com/doc](https://git-scm.com/doc)
- **Dépôts du projet :**
    - Mason : https://github.com/ialame/mason
    - Painter : https://github.com/ialame/painter
    - GestionCarte : https://github.com/ialame/gestioncarte

---

## 📈 Optimisation

### ⚡ Performance

```bash
# Allouer plus de ressources à Docker
# Docker Desktop → Settings → Resources

# Optimiser les images Docker
docker system prune -f
```

### 🔒 Sécurité

```bash
# Vérifier les ports exposés
docker-compose ps

# Utiliser des tokens avec permissions minimales
# GitHub → Settings → Developer settings → Fine-grained tokens
```

---

**✨ Félicitations ! Votre installation CardManager est opérationnelle !**

> 💡 **Conseil :** Bookmarquez http://localhost:8080 pour un accès rapide

---

*Guide créé avec ❤️ pour la communauté CardManager*