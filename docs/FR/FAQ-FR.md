# ❓ FAQ CardManager - Questions Fréquentes

**Version :** 2.0.0  
**Dernière mise à jour :** Juillet 2025

## 📋 Table des matières

1. [Installation et démarrage](#-installation-et-démarrage)
2. [Configuration Bitbucket](#-configuration-bitbucket)
3. [Utilisation et fonctionnalités](#-utilisation-et-fonctionnalités)
4. [Problèmes techniques](#-problèmes-techniques)
5. [Maintenance et mise à jour](#-maintenance-et-mise-à-jour)
6. [Performance et optimisation](#-performance-et-optimisation)

---

## 🚀 Installation et démarrage

### Q: Docker dit "port déjà utilisé", que faire ?
**R:** Un autre service utilise le port. Solutions :
1. **Identifier le processus :**
   ```bash
   lsof -i :8080  # macOS/Linux
   netstat -ano | findstr :8080  # Windows
   ```
2. **Arrêter le service** ou **modifier les ports** dans `docker-compose.yml`
3. **Changer les ports :**
   ```yaml
   ports:
     - "9080:8080"  # Au lieu de 8080:8080
   ```

### Q: "Cannot connect to Docker daemon"
**R:** Docker n'est pas démarré :
- **Windows/Mac :** Démarrez Docker Desktop
- **Linux :** `sudo systemctl start docker`

### Q: Le démarrage est très lent, est-ce normal ?
**R:** Oui, au premier lancement :
- **Premier build :** 15-20 minutes (compilation Java + téléchargement images)
- **Lancements suivants :** 2-3 minutes
- **Cause :** Compilation des 3 projets Java Maven

### Q: Comment vérifier que tout fonctionne ?
**R:** Plusieurs méthodes :
```bash
# Script automatique
./scripts/diagnostic.sh

# Tests manuels
curl http://localhost:8080  # Application
curl http://localhost:8081/actuator/health  # Painter
curl http://localhost:8082  # Images

# État des services
docker-compose ps
```

---

## 🔑 Configuration Bitbucket

### Q: J'ai une erreur "Permission denied" avec Bitbucket
**R:** Problème d'authentification SSH :
1. **Vérifiez votre connexion :**
   ```bash
   ssh -T git@bitbucket.org
   ```
2. **Si échec, reconfigurez SSH :**
   ```bash
   # Générer nouvelle clé
   ssh-keygen -t ed25519 -C "votre@email.com"
   
   # Ajouter à Bitbucket (Settings → SSH keys)
   cat ~/.ssh/id_ed25519.pub
   
   # Copier dans le projet
   cp ~/.ssh/id_ed25519* docker/ssh-keys/
   ```

### Q: Comment changer les branches utilisées ?
**R:** Modifiez le fichier `.env` :
```bash
MASON_BRANCH=votre-branche
PAINTER_BRANCH=votre-branche
GESTIONCARTE_BRANCH=votre-branche
```
Puis redémarrez : `docker-compose down && docker-compose up -d --build`

### Q: Peut-on utiliser HTTPS au lieu de SSH ?
**R:** Oui, mais moins sécurisé. Modifiez `.env` :
```bash
MASON_REPO_URL=https://bitbucket.org/pcafxc/mason.git
# Ajoutez vos identifiants si dépôt privé
```

### Q: Erreur "Host key verification failed"
**R:** Ajoutez Bitbucket aux hosts connus :
```bash
ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts
```
Ou modifiez `docker/ssh-keys/config` :
```
StrictHostKeyChecking no
```

---

## 🎯 Utilisation et fonctionnalités

### Q: Comment uploader une image ?
**R:** Via l'interface web :
1. Ouvrez http://localhost:8080
2. Créez ou sélectionnez une carte
3. Cliquez sur "Upload Image"
4. Sélectionnez votre fichier
5. L'image est automatiquement traitée par Painter

### Q: Où sont stockées les images ?
**R:** Dans un volume Docker persistant :
- **Volume :** `cardmanager_images`
- **Accessible via :** http://localhost:8082
- **Inspection :** `docker volume inspect cardmanager_images`

### Q: Comment importer une base de données existante ?
**R:** Deux méthodes :
1. **Via init-db (recommandé) :**
   ```bash
   # Placer votre fichier .sql dans init-db/
   cp votre-base.sql init-db/
   docker-compose down --volumes
   docker-compose up -d
   ```

2. **Import manuel :**
   ```bash
   docker exec -i cardmanager-mariadb mariadb -u ia -pfoufafou dev < votre-base.sql
   ```

### Q: Comment accéder à la base de données ?
**R:** Plusieurs options :
```bash
# Ligne de commande
docker exec -it cardmanager-mariadb mariadb -u ia -pfoufafou dev

# Client graphique (port 3308)
# Hôte: localhost, Port: 3308, User: ia, Pass: foufafou

# Export de données
docker exec cardmanager-mariadb mariadb-dump -u ia -pfoufafou dev > export.sql
```

---

## 🔧 Problèmes techniques

### Q: L'application ne se charge pas (erreur 502/503)
**R:** Services encore en cours de démarrage :
1. **Attendez 2-3 minutes** après `docker-compose up -d`
2. **Vérifiez les logs :**
   ```bash
   docker-compose logs gestioncarte
   docker-compose logs painter
   ```
3. **Redémarrez si nécessaire :**
   ```bash
   docker-compose restart gestioncarte
   ```

### Q: Les images ne s'affichent pas
**R:** Problème avec Nginx ou volumes :
1. **Vérifiez Nginx :**
   ```bash
   docker-compose logs nginx-images
   curl http://localhost:8082
   ```
2. **Vérifiez le volume :**
   ```bash
   docker volume ls | grep images
   docker exec cardmanager-nginx ls -la /usr/share/nginx/html/images/
   ```
3. **Redémarrez Nginx :**
   ```bash
   docker-compose restart nginx-images
   ```

### Q: Erreur "Connection refused localhost:8081"
**R:** Problème de communication entre GestionCarte et Painter :
1. **Vérifiez la configuration :**
   ```bash
   docker exec cardmanager-gestioncarte env | grep PAINTER
   ```
2. **Testez la communication :**
   ```bash
   docker exec cardmanager-gestioncarte wget -qO- http://painter:8081/actuator/health
   ```
3. **Si échec, redémarrez :**
   ```bash
   docker-compose restart gestioncarte painter
   ```

### Q: "No space left on device"
**R:** Problème d'espace disque :
```bash
# Vérifier l'espace
df -h
docker system df

# Nettoyer Docker
docker system prune -a -f
docker volume prune -f

# Nettoyer les logs
sudo journalctl --vacuum-time=7d
```

### Q: Un service n'arrête pas de redémarrer
**R:** Erreur dans l'application :
1. **Voir les logs détaillés :**
   ```bash
   docker-compose logs --tail=50 nom_du_service
   ```
2. **Problèmes fréquents :**
    - Configuration Hikari invalide
    - Connexion base de données échouée
    - Port déjà utilisé
    - Erreur dans le code applicatif

---

## 🛠️ Maintenance et mise à jour

### Q: Comment mettre à jour CardManager ?
**R:** Processus standard :
```bash
# 1. Sauvegarder
./scripts/backup.sh

# 2. Récupérer les mises à jour
git pull origin main

# 3. Redémarrer avec reconstruction
docker-compose down
docker-compose up -d --build
```

### Q: Comment sauvegarder mes données ?
**R:** Script automatique :
```bash
./scripts/backup.sh
```
Ou manuellement :
```bash
# Base de données
docker exec cardmanager-mariadb mariadb-dump -u ia -pfoufafou dev > backup-db-$(date +%Y%m%d).sql

# Images
docker run --rm -v cardmanager_images:/data -v $(pwd):/backup alpine tar czf /backup/images-$(date +%Y%m%d).tar.gz /data
```

### Q: Comment supprimer complètement CardManager ?
**R:** Nettoyage complet :
```bash
# Arrêter et supprimer tout
docker-compose down --volumes --remove-orphans

# Supprimer les images Docker
docker system prune -a -f

# Supprimer le dossier (ATTENTION: perte de données)
cd .. && rm -rf docker-cardmanager-bitbucket
```

### Q: Comment changer les mots de passe de la base ?
**R:** Modifier dans `docker-compose.yml` ET `.env` :
```yaml
environment:
  - MARIADB_ROOT_PASSWORD=nouveau_mot_de_passe
  - MARIADB_PASSWORD=nouveau_mot_de_passe
```
Puis : `docker-compose down --volumes && docker-compose up -d`

---

## ⚡ Performance et optimisation

### Q: CardManager est lent, comment optimiser ?
**R:** Plusieurs pistes :
1. **Allouer plus de ressources à Docker :**
    - Docker Desktop → Settings → Resources
    - RAM : 6-8 GB recommandés
    - CPU : 4 cœurs recommandés

2. **Optimiser les images Docker :**
   ```bash
   docker system prune -f
   docker-compose build --no-cache
   ```

3. **Vérifier l'espace disque :**
   ```bash
   docker system df
   ```

### Q: Comment accéder depuis un autre ordinateur ?
**R:** Remplacer `localhost` par l'IP de votre machine :
```bash
# Trouver votre IP
ipconfig  # Windows
ifconfig  # macOS/Linux

# Accès : http://192.168.1.XXX:8080
```
**⚠️ Attention :** Aucune sécurité par défaut !

### Q: Y a-t-il une authentification ?
**R:** Non par défaut. Pour sécuriser :
1. **Reverse proxy** (nginx, traefik)
2. **VPN** ou **tunnel SSH**
3. **Authentification applicative** (modification du code)
4. **Firewall** pour limiter l'accès

### Q: Différences entre macOS, Linux et Windows ?
**R:**
- **Installation Docker** : différente selon l'OS
- **Chemins de fichiers** : automatiquement gérés par Docker
- **Performance** : légèrement meilleure sur Linux
- **Fonctionnalités** : identiques partout

---

## 🆘 Support

### Q: Où demander de l'aide ?
**R:** Plusieurs options :
1. **Consultez cette FAQ** (vous y êtes !)
2. **Relisez le [guide de déploiement](DEPLOIEMENT-FR.md)**
3. **Exécutez le diagnostic :**
   ```bash
   ./scripts/diagnostic.sh > diagnostic.txt
   ```
4. **Créez une issue GitHub** avec :
    - Le fichier `diagnostic.txt`
    - Vos logs : `docker-compose logs > logs.txt`
    - Votre configuration `.env` (sans mots de passe)

### Q: Comment contribuer au projet ?
**R:**
1. **Fork** le projet sur GitHub
2. **Créez une branche** pour votre fonctionnalité
3. **Testez** vos modifications
4. **Créez une Pull Request** avec description détaillée

### Q: CardManager fonctionne-t-il sur Raspberry Pi ?
**R:** Possible mais non officiellement supporté :
- Utiliser des images Docker ARM
- Performance limitée
- Augmenter les timeouts Docker

### Q: Problèmes sur Windows avec WSL ?
**R:** Recommandations :
- **Utiliser Docker Desktop** for Windows (pas Docker dans WSL)
- **Activer WSL2** backend dans Docker Desktop
- **Allouer suffisamment de mémoire** à WSL2

---

## 📚 Ressources supplémentaires

### Documentation
- **[Guide technique](TECHNIQUE-FR.md)** - Configuration avancée
- **[Guide de déploiement](DEPLOIEMENT-FR.md)** - Installation complète

### Liens utiles
- **[Documentation Docker](https://docs.docker.com/)**
- **[Guide Git](https://git-scm.com/doc)**
- **[Documentation Bitbucket SSH](https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/)**

---

**💡 Question non résolue ?**

Créez une [issue GitHub](https://github.com/ialame/docker-cardmanager-bitbucket/issues) avec :
- Votre problème détaillé
- Les logs d'erreur
- Votre configuration système
- Le résultat de `./scripts/diagnostic.sh`

---

*FAQ créée avec ❤️ pour la communauté CardManager*