# 🚀 Guide de Déploiement CardManager

**Version :** 1.0.0
**Date :** Juillet 2025
**Niveau :** Débutant à Avancé

---

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation express](#installation-express)
3. [Installation détaillée](#installation-détaillée)
4. [Vérification](#vérification)
5. [Première utilisation](#première-utilisation)
6. [Maintenance](#maintenance)
7. [Dépannage](#dépannage)

---

## 🔧 Prérequis

### Configuration système minimale
- **RAM :** 4 GB minimum (8 GB recommandé)
- **Stockage :** 10 GB d'espace libre
- **OS :** Windows 10+, macOS 10.15+, ou Linux moderne
- **Réseau :** Connexion internet pour le téléchargement initial

### Logiciels requis

#### Docker Desktop (obligatoire)

**Windows/macOS :**
1. Téléchargez depuis [docker.com](https://www.docker.com/products/docker-desktop)
2. Installez et redémarrez votre ordinateur
3. Démarrez Docker Desktop

**Linux (Ubuntu/Debian) :**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```
*Déconnectez-vous et reconnectez-vous après cette commande*

#### Git (optionnel)
Si Git n'est pas installé :
- **Windows :** [git-scm.com](https://git-scm.com/)
- **macOS :** `xcode-select --install`
- **Linux :** `sudo apt install git` (Ubuntu) ou équivalent

---

## ⚡ Installation express (5 minutes)

### Option 1 : Avec Git
```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
docker-compose up -d
```

### Option 2 : Sans Git
1. Téléchargez le ZIP depuis GitHub
2. Décompressez dans un dossier
3. Ouvrez un terminal dans ce dossier
4. Exécutez : `docker-compose up -d`

### ⏳ Temps d'attente
- **Premier lancement :** 10-15 minutes (téléchargement des images)
- **Lancements suivants :** 1-2 minutes

### ✅ Vérification rapide
Ouvrez http://localhost:8080 - Vous devriez voir l'interface CardManager

---

## 🔧 Installation détaillée

### Étape 1 : Téléchargement du projet

**Avec Git :**
```bash
git clone https://github.com/ialame/docker-cardmanager-github.git
cd docker-cardmanager-github
```

**Sans Git :**
1. Allez sur https://github.com/ialame/docker-cardmanager-github
2. Cliquez sur "Code" → "Download ZIP"
3. Décompressez dans un dossier de votre choix
4. Ouvrez un terminal/invite de commandes dans ce dossier

### Étape 2 : Vérification de Docker

```bash
# Vérifier que Docker fonctionne
docker --version
docker-compose --version

# Tester Docker
docker run hello-world
```

Si ces commandes échouent, redémarrez Docker Desktop.

### Étape 3 : Configuration (optionnelle)

**Ports personnalisés :**
Si les ports par défaut sont occupés, modifiez `docker-compose.yml` :
```yaml
ports:
  - "8080:8080"  # Application → "9080:8080" par exemple
  - "8081:8081"  # Painter → "9081:8081"
  - "8082:80"    # Images → "9082:80"
  - "3307:3306"  # Base → "3308:3306"
```

**Données existantes :**
Pour importer une base de données existante :
1. Placez votre fichier SQL dans `init-db/`
2. Le fichier sera importé automatiquement au premier démarrage

### Étape 4 : Lancement des services

```bash
# Lancement en arrière-plan
docker-compose up -d

# OU lancement avec logs visibles
docker-compose up
```

### Étape 5 : Monitoring du démarrage

```bash
# Voir l'état des services
docker-compose ps

# Suivre les logs
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f gestioncarte
```

---

## ✅ Vérification du déploiement

### Tests automatiques

1. **Application principale :**
   - URL : http://localhost:8080
   - ✅ Vous devriez voir l'interface CardManager

2. **Service d'images :**
   - URL : http://localhost:8082/images/
   - ✅ Vous devriez voir un index des images

3. **API Painter :**
   - URL : http://localhost:8081/actuator/health
   - ✅ Vous devriez voir `{"status":"UP"}`

### Tests manuels

```bash
# Vérifier tous les services
docker-compose ps

# Tester la base de données
docker-compose exec mariadb-standalone mysql -u ia -p'foufafou' -e "SELECT 'DB OK';"

# Vérifier les volumes
docker volume ls | grep cardmanager
```

### En cas d'erreur

```bash
# Voir les logs d'erreur
docker-compose logs

# Redémarrer un service spécifique
docker-compose restart painter

# Redémarrer complètement
docker-compose down
docker-compose up -d
```

---

## 🎯 Première utilisation

### Connexion à l'application

1. Ouvrez http://localhost:8080
2. L'interface CardManager s'affiche
3. Commencez par explorer les fonctionnalités

### Upload d'images

1. Utilisez la fonction d'upload dans l'interface
2. Les images sont automatiquement :
   - Sauvegardées sur disque
   - Indexées en base de données
   - Visibles sur http://localhost:8082/images/

### Import de données existantes

Si vous avez des données à importer :
1. Arrêtez les services : `docker-compose down`
2. Placez vos fichiers SQL dans `init-db/`
3. Redémarrez : `docker-compose up -d`

---

## 🛠️ Maintenance

### Commandes de base

```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Redémarrer
docker-compose restart

# Voir les logs
docker-compose logs -f

# Mise à jour
git pull
docker-compose pull
docker-compose up -d --build
```

### Sauvegarde

**Sauvegarde de la base de données :**
```bash
docker-compose exec mariadb-standalone mysqldump -u ia -p'foufafou' dev > backup-$(date +%Y%m%d).sql
```

**Sauvegarde des images :**
```bash
docker run --rm -v cardmanager_images:/data -v $(pwd):/backup alpine tar czf /backup/images-backup-$(date +%Y%m%d).tar.gz /data
```

### Nettoyage

```bash
# Arrêter et supprimer les conteneurs
docker-compose down

# Supprimer aussi les volumes (ATTENTION : perte de données)
docker-compose down --volumes

# Nettoyer les images Docker inutilisées
docker system prune -f
```

---

## 🚨 Dépannage

### Problèmes courants

#### "Port already in use"
```bash
# Trouver quel processus utilise le port
lsof -i :8080
# ou sur Windows
netstat -ano | findstr :8080

# Changer le port dans docker-compose.yml
ports:
  - "9080:8080"  # Au lieu de 8080:8080
```

#### "Cannot connect to Docker daemon"
- Démarrez Docker Desktop
- Sur Linux : `sudo systemctl start docker`

#### Services qui ne démarrent pas
```bash
# Voir les logs détaillés
docker-compose logs service_name

# Redémarrer proprement
docker-compose down
docker-compose up -d
```

#### "No space left on device"
```bash
# Nettoyer Docker
docker system prune -a -f
docker volume prune -f
```

#### Images qui ne s'affichent pas
```bash
# Vérifier le service nginx
docker-compose logs nginx-images

# Vérifier les permissions du volume
docker-compose exec nginx-images ls -la /usr/share/nginx/html/images/
```

### Diagnostic automatique

Créez ce script pour diagnostiquer automatiquement :

```bash
#!/bin/bash
echo "🔍 Diagnostic CardManager"
echo "========================="

echo "Docker version:"
docker --version

echo -e "\nServices status:"
docker-compose ps

echo -e "\nPorts usage:"
lsof -i :8080,:8081,:8082,:3307 || netstat -ano | findstr ":8080 :8081 :8082 :3307"

echo -e "\nDisk space:"
df -h

echo -e "\nDocker space:"
docker system df
```

### Contacts support

1. **Documentation :** Relisez ce guide et la [FAQ](FAQ-FR.md)
2. **Issues GitHub :** [Signaler un bug](https://github.com/ialame/docker-cardmanager-github/issues)
3. **Logs :** Joignez toujours les logs avec `docker-compose logs`

---

## 📞 Support et ressources

### Ressources utiles
- **[FAQ française](FAQ-FR.md)** - Questions fréquentes
- **[Guide technique](TECHNIQUE-FR.md)** - Configuration avancée
- **[Docker documentation](https://docs.docker.com/)** - Documentation officielle Docker

### Communauté
- **GitHub Issues :** Pour les bugs et demandes de fonctionnalités
- **GitHub Discussions :** Pour les questions générales

---

**🎉 Félicitations ! Votre installation CardManager est prête !**

*Développé avec ❤️ pour les collectionneurs de cartes*
