# ❓ FAQ CardManager - Questions Fréquentes

## 🚀 Installation et démarrage

### Q: Docker dit "port already in use", que faire ?
**R:** Un autre service utilise le port. Solutions :
1. Arrêtez l'autre service
2. Modifiez les ports dans `docker-compose.yml`
3. Utilisez `lsof -i :8080` pour identifier le processus

### Q: "Cannot connect to Docker daemon"
**R:** Docker n'est pas démarré :
- **Windows/Mac :** Démarrez Docker Desktop
- **Linux :** `sudo systemctl start docker`

### Q: Le démarrage est très lent, est-ce normal ?
**R:** Oui, le premier démarrage prend 10-15 minutes car Docker télécharge toutes les images. Les démarrages suivants sont rapides (1-2 minutes).

### Q: Comment vérifier que tout fonctionne ?
**R:** Exécutez `./diagnostic.sh` ou vérifiez manuellement :
- http://localhost:8080 (application)
- http://localhost:8082/images/ (images)
- `docker-compose ps` (état des services)

## 🔧 Configuration et utilisation

### Q: Comment changer les ports par défaut ?
**R:** Modifiez `docker-compose.yml` :
```yaml
ports:
  - "9080:8080"  # Au lieu de 8080:8080
```

### Q: Où sont stockées les images ?
**R:** Dans un volume Docker `cardmanager_images`. Visibles via :
- Interface web : http://localhost:8082/images/
- Commande : `docker volume inspect cardmanager_images`

### Q: Comment importer ma base de données existante ?
**R:**
1. Placez votre fichier `.sql` dans le dossier `init-db/`
2. Redémarrez : `docker-compose down --volumes && docker-compose up -d`

### Q: Comment sauvegarder mes données ?
**R:** Utilisez le script : `./backup.sh`

## 🐛 Problèmes courants

### Q: L'application ne se charge pas (erreur 502/503)
**R:** Les services démarrent encore. Attendez 2-3 minutes et rafraîchissez.

### Q: Les images ne s'affichent pas
**R:** Vérifiez :
1. Le service nginx : `docker-compose logs nginx-images`
2. Le volume : `docker volume ls | grep images`
3. Redémarrez nginx : `docker-compose restart nginx-images`

### Q: "No space left on device"
**R:** Nettoyez Docker :
```bash
docker system prune -a -f
docker volume prune -f
```

### Q: Un service n'arrive pas à démarrer
**R:**
1. Consultez les logs : `docker-compose logs service_name`
2. Redémarrez le service : `docker-compose restart service_name`
3. En dernier recours : `docker-compose down && docker-compose up -d`

### Q: La base de données ne se connecte pas
**R:**
1. Vérifiez que MariaDB est démarré : `docker-compose ps mariadb-standalone`
2. Testez la connexion : `docker-compose exec mariadb-standalone mysql -u ia -p'foufafou' dev`
3. Vérifiez les logs : `docker-compose logs mariadb-standalone`

## 💾 Maintenance

### Q: Comment mettre à jour CardManager ?
**R:**
```bash
git pull
docker-compose pull
docker-compose up -d --build
```

### Q: Comment supprimer complètement CardManager ?
**R:**
```bash
docker-compose down --volumes --remove-orphans
docker system prune -a -f
```

### Q: Comment changer le mot de passe de la base ?
**R:** Modifiez dans `docker-compose.yml` les variables :
- `MYSQL_PASSWORD`
- `SPRING_DATASOURCE_PASSWORD`
Puis : `docker-compose down --volumes && docker-compose up -d`

## 🌐 Accès et sécurité

### Q: Comment accéder depuis un autre ordinateur ?
**R:** Remplacez `localhost` par l'IP de votre machine. Attention : aucune sécurité par défaut !

### Q: Y a-t-il une authentification ?
**R:** Non par défaut. L'application est accessible à tous sur le réseau local.

### Q: Comment sécuriser CardManager ?
**R:** Plusieurs options :
1. Utilisez un reverse proxy (nginx, traefik)
2. Activez HTTPS
3. Ajoutez une authentification
4. Configurez un firewall

## 📱 Plateformes spécifiques

### Q: Différences entre macOS et Linux ?
**R:** L'installation Docker diffère, mais tout le reste est identique. Voir [DEPLOYMENT-EN.md](DEPLOYMENT-EN.md).

### Q: CardManager fonctionne-t-il sur Raspberry Pi ?
**R:** Possible avec les images ARM, mais pas officiellement supporté.

### Q: Problèmes sur Windows avec WSL ?
**R:** Utilisez Docker Desktop for Windows plutôt que Docker dans WSL.

## 🆘 Support

### Q: Où demander de l'aide ?
**R:**
1. Consultez cette FAQ
2. Relisez le [guide de déploiement](DEPLOIEMENT-FR.md)
3. Créez une issue sur GitHub avec vos logs

### Q: Comment joindre les logs à un rapport de bug ?
**R:**
```bash
docker-compose logs > logs-cardmanager.txt
```
Joignez ce fichier à votre issue GitHub.

### Q: CardManager est-il open source ?
**R:** Vérifiez la licence du projet sur GitHub.

---

**💡 Question non résolue ?** Créez une [issue GitHub](https://github.com/ialame/docker-cardmanager-github/issues) avec vos logs !
