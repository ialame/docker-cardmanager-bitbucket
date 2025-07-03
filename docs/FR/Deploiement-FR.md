# 🚀 Guide de Déploiement CardManager

**Version :** 2.0.0  
**Dernière mise à jour :** Juillet 2025  
**Temps estimé :** 10-15 minutes

## 📋 Table des matières

1. [Prérequis](#-prérequis)
2. [Installation rapide](#-installation-rapide)
3. [Configuration Bitbucket](#-configuration-bitbucket)
4. [Déploiement](#-déploiement)
5. [Vérification](#-vérification)
6. [Première utilisation](#-première-utilisation)
7. [Maintenance](#-maintenance)
8. [Dépannage](#-dépannage)

---

## 🔧 Prérequis

### ✅ Configuration système

| Composant | Requis | Recommandé |
|-----------|---------|------------|
| **RAM** | 4 GB | 8 GB |
| **Stockage** | 5 GB | 10 GB |
| **CPU** | 2 cœurs | 4 cœurs |
| **OS** | Windows 10+, macOS 11+, Linux | |

### 📦 Logiciels requis

#### 1. Docker Desktop

**Windows/macOS :**
1. Téléchargez depuis [docker.com](https://www.docker.com/products/docker-desktop)
2. Installez et redémarrez
3. Démarrez Docker Desktop

**Linux (Ubuntu/Debian) :**
```bash
# Installation automatique
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Redémarrer la session
logout
```

#### 2. Git (optionnel)

**Windows :** [git-scm.com](https://git-scm.com/)  
**macOS :** `xcode-select --install`  
**Linux :** `sudo apt install git`

### 🔌 Réseau

**Ports utilisés :**
- **8080** : Interface web principale
- **8081** : API Painter (traitement images)
- **8082** : Serveur d'images Nginx
- **3308** : Base de données MariaDB

---

## ⚡ Installation rapide

### Option 1 : Clone Git (recommandé)

```bash
# 1. Cloner le projet
git clone https://github.com/ialame/docker-cardmanager-bitbucket.git
cd docker-cardmanager-bitbucket

# 2. Configurer les accès Bitbucket (voir section suivante)

# 3. Démarrer
docker-compose up -d

# 4. Vérifier
open http://localhost:8080
```

### Option 2 : Téléchargement ZIP

1. Téléchargez le ZIP depuis GitHub
2. Décompressez dans un dossier
3. Ouvrez un terminal dans ce dossier
4. Suivez les étapes de configuration Bitbucket
5. Exécutez `docker-compose up -d`

---

## 🔑 Configuration Bitbucket

### Prérequis Bitbucket

Ce projet utilise **3 dépôts privés Bitbucket** :
- `pcafxc/mason` (bibliothèques communes)
- `pcafxc/painter` (traitement d'images)
- `pcafxc/gestioncarte` (interface principale)

### 1. Configuration SSH (Recommandé)

#### a) Générer une clé SSH

```bash
# Générer une nouvelle clé SSH
ssh-keygen -t ed25519 -C "votre@email.com"

# Ajouter au ssh-agent
ssh-add ~/.ssh/id_ed25519
```

#### b) Ajouter la clé à Bitbucket

1. Copiez votre clé publique :
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. Dans Bitbucket :
    - Allez dans **Settings** → **SSH keys**
    - Cliquez **Add key**
    - Collez votre clé publique

3. Testez la connexion :
   ```bash
   ssh -T git@bitbucket.org
   ```

#### c) Configurer les clés pour Docker

```bash
# Copier vos clés SSH vers le projet
mkdir -p docker/ssh-keys
cp ~/.ssh/id_ed25519 docker/ssh-keys/bitbucket_ed25519
cp ~/.ssh/id_ed25519.pub docker/ssh-keys/bitbucket_ed25519.pub

# Créer le fichier de configuration SSH
cat > docker/ssh-keys/config << EOF
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile /root/.ssh/bitbucket_ed25519
    StrictHostKeyChecking no
EOF
```

### 2. Configuration des variables

```bash
# Copier le template
cp .env.template .env

# Éditer la configuration
nano .env
```

Ajustez ces variables dans `.env` :

```bash
# === DÉPÔTS BITBUCKET ===
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# === BRANCHES DE DÉVELOPPEMENT ===
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# === CONFIGURATION RÉSEAU ===
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
DB_PORT=3308

# === BASE DE DONNÉES ===
LOCAL_DB_NAME=dev
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou
MYSQL_ROOT_PASSWORD=root_password
```

---

## 🚀 Déploiement

### Script automatique (Recommandé)

```bash
# Démarrage complet
./scripts/start.sh
```

### Déploiement manuel

```bash
# 1. Construction des images
docker-compose build --no-cache

# 2. Démarrage des services
docker-compose up -d

# 3. Vérification
docker-compose ps
```

### ⏳ Temps de démarrage

- **Premier build** : 15-20 minutes (compilation Java)
- **Démarrages suivants** : 2-3 minutes
- **Vérification complète** : 5 minutes

---

## ✅ Vérification

### 🔍 Tests automatiques

```bash
# Diagnostic complet
./scripts/diagnostic.sh
```

### 🧪 Tests manuels

#### 1. État des services

```bash
docker-compose ps
```

**Résultat attendu :**
```
NAME                       STATUS        PORTS
cardmanager-mariadb        Up            0.0.0.0:3308->3306/tcp
cardmanager-painter        Up (healthy)  0.0.0.0:8081->8081/tcp
cardmanager-gestioncarte   Up (healthy)  0.0.0.0:8080->8080/tcp
cardmanager-nginx          Up            0.0.0.0:8082->80/tcp
```

#### 2. Test des endpoints

| Service | URL | Test | Résultat attendu |
|---------|-----|------|------------------|
| **Application** | http://localhost:8080 | Interface web | Page d'accueil CardManager |
| **API Painter** | http://localhost:8081/actuator/health | Health check | `{"status":"UP"}` |
| **Images** | http://localhost:8082 | Serveur d'images | Index des images |

#### 3. Test de communication

```bash
# Test communication GestionCarte → Painter
docker exec cardmanager-gestioncarte wget -qO- http://painter:8081/actuator/health
```

**Résultat attendu :** `{"status":"UP"}`

---

## 🎯 Première utilisation

### 1. Accès à l'application

1. Ouvrez votre navigateur
2. Allez sur http://localhost:8080
3. L'interface CardManager s'affiche

### 2. Test d'upload d'image

1. Créez une nouvelle carte via l'interface
2. Uploadez une image
3. Vérifiez que l'image apparaît dans http://localhost:8082

### 3. Vérification de la base de données

```bash
# Connexion à la base
docker exec -it cardmanager-mariadb mariadb -u ia -pfoufafou dev

# Vérifier les tables
SHOW TABLES;

# Voir les données
SELECT COUNT(*) FROM card_image;
```

---

## 🛠️ Maintenance

### Scripts de gestion

```bash
# Démarrage
./scripts/start.sh

# Arrêt
./scripts/stop.sh

# Redémarrage
./scripts/restart.sh

# Diagnostic
./scripts/diagnostic.sh

# Sauvegarde
./scripts/backup.sh

# Nettoyage
./scripts/clean.sh
```

### Sauvegardes

#### Sauvegarde automatique

```bash
./scripts/backup.sh
```

#### Sauvegarde manuelle

```bash
# Base de données
docker exec cardmanager-mariadb mariadb-dump -u ia -pfoufafou dev > backup-$(date +%Y%m%d).sql

# Images
docker run --rm -v cardmanager_images:/data -v $(pwd):/backup alpine tar czf /backup/images-backup-$(date +%Y%m%d).tar.gz /data
```

### Mise à jour

```bash
# 1. Arrêter les services
docker-compose down

# 2. Récupérer les mises à jour
git pull origin main

# 3. Reconstruire
docker-compose build --no-cache

# 4. Redémarrer
docker-compose up -d
```

---

## 🚨 Dépannage

### Problèmes fréquents

#### 1. Port occupé

```bash
# Identifier le processus
lsof -i :8080

# ou sur Windows
netstat -ano | findstr :8080

# Solution : changer le port dans docker-compose.yml
ports:
  - "9080:8080"  # Au lieu de 8080:8080
```

#### 2. Erreur SSH Bitbucket

```bash
# Vérifier la connexion
ssh -T git@bitbucket.org

# Reconfigurer les clés
rm -rf docker/ssh-keys/*
# Reprendre la configuration SSH
```

#### 3. Services qui redémarrent

```bash
# Voir les logs
docker-compose logs painter
docker-compose logs gestioncarte

# Problèmes fréquents :
# - Configuration Hikari
# - Communication réseau
# - Permissions base de données
```

#### 4. Erreur de mémoire Docker

```bash
# Vérifier l'espace
docker system df

# Nettoyer
docker system prune -f
docker volume prune -f
```

### Diagnostic avancé

#### Vérification réseau

```bash
# Test réseau entre conteneurs
docker exec cardmanager-gestioncarte ping painter

# Vérification DNS
docker exec cardmanager-gestioncarte nslookup painter
```

#### Logs détaillés

```bash
# Logs en temps réel
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs --tail=50 painter

# Logs avec horodatage
docker-compose logs -t gestioncarte
```

### Scripts de réparation

En cas de problème persistant :

```bash
# Réinitialisation complète
./scripts/reset.sh

# Nettoyage et redémarrage
./scripts/clean.sh && ./scripts/start.sh
```

---

## 📞 Support

### 🆘 En cas de problème

1. **Consultez la [FAQ](FAQ-FR.md)**
2. **Exécutez le diagnostic :**
   ```bash
   ./scripts/diagnostic.sh > diagnostic-report.txt
   ```
3. **Créez une issue GitHub** avec :
    - Le fichier `diagnostic-report.txt`
    - Les logs : `docker-compose logs > logs.txt`
    - Votre configuration `.env` (sans les mots de passe)

### 📚 Ressources

- **[FAQ française](FAQ-FR.md)** - Questions fréquentes
- **[Guide technique](TECHNIQUE-FR.md)** - Configuration avancée
- **[Documentation Docker](https://docs.docker.com/)** - Référence officielle

---

**✨ Félicitations ! Votre CardManager est opérationnel !**

> 💡 **Conseil :** Bookmarquez http://localhost:8080 pour un accès rapide

---

*Guide créé avec ❤️ pour les collectionneurs de cartes*