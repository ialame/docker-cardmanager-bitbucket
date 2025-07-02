# ❓ CardManager FAQ - Frequently Asked Questions

## 🚀 Installation and startup

### Q: Docker says "port already in use", what to do?
**A:** Another service is using the port. Solutions:
1. Stop the other service
2. Modify ports in `docker-compose.yml`
3. Use `lsof -i :8080` to identify the process

### Q: "Cannot connect to Docker daemon"
**A:** Docker is not started:
- **Windows/Mac:** Start Docker Desktop
- **Linux:** `sudo systemctl start docker`

### Q: Startup is very slow, is this normal?
**A:** Yes, first startup takes 10-15 minutes as Docker downloads all images. Subsequent startups are fast (1-2 minutes).

### Q: How to verify everything works?
**A:** Run `./diagnostic.sh` or check manually:
- http://localhost:8080 (application)
- http://localhost:8082/images/ (images)
- `docker-compose ps` (service status)

## 🔧 Configuration and usage

### Q: How to change default ports?
**A:** Modify `docker-compose.yml`:
```yaml
ports:
  - "9080:8080"  # Instead of 8080:8080
```

### Q: Where are images stored?
**A:** In a Docker volume `cardmanager_images`. Visible via:
- Web interface: http://localhost:8082/images/
- Command: `docker volume inspect cardmanager_images`

### Q: How to import my existing database?
**A:**
1. Place your `.sql` file in the `init-db/` folder
2. Restart: `docker-compose down --volumes && docker-compose up -d`

### Q: How to backup my data?
**A:** Use the script: `./backup.sh`

## 🐛 Common issues

### Q: Application doesn't load (error 502/503)
**A:** Services are still starting. Wait 2-3 minutes and refresh.

### Q: Images don't display
**A:** Check:
1. nginx service: `docker-compose logs nginx-images`
2. Volume: `docker volume ls | grep images`
3. Restart nginx: `docker-compose restart nginx-images`

### Q: "No space left on device"
**A:** Clean Docker:
```bash
docker system prune -a -f
docker volume prune -f
```

### Q: A service fails to start
**A:**
1. Check logs: `docker-compose logs service_name`
2. Restart service: `docker-compose restart service_name`
3. Last resort: `docker-compose down && docker-compose up -d`

### Q: Database won't connect
**A:**
1. Verify MariaDB is started: `docker-compose ps mariadb-standalone`
2. Test connection: `docker-compose exec mariadb-standalone mysql -u ia -p'foufafou' dev`
3. Check logs: `docker-compose logs mariadb-standalone`

## 💾 Maintenance

### Q: How to update CardManager?
**A:**
```bash
git pull
docker-compose pull
docker-compose up -d --build
```

### Q: How to completely remove CardManager?
**A:**
```bash
docker-compose down --volumes --remove-orphans
docker system prune -a -f
```

### Q: How to change database password?
**A:** Modify in `docker-compose.yml` the variables:
- `MYSQL_PASSWORD`
- `SPRING_DATASOURCE_PASSWORD`
Then: `docker-compose down --volumes && docker-compose up -d`

## 🌐 Access and security

### Q: How to access from another computer?
**A:** Replace `localhost` with your machine's IP. Warning: no security by default!

### Q: Is there authentication?
**A:** No by default. Application is accessible to everyone on local network.

### Q: How to secure CardManager?
**A:** Several options:
1. Use a reverse proxy (nginx, traefik)
2. Enable HTTPS
3. Add authentication
4. Configure a firewall

## 📱 Platform-specific

### Q: Differences between macOS and Linux?
**A:** Docker installation differs, but everything else is identical. See [DEPLOYMENT-EN.md](DEPLOYMENT-EN.md).

### Q: Does CardManager work on Raspberry Pi?
**A:** Possible with ARM images, but not officially supported.

### Q: Issues on Windows with WSL?
**A:** Use Docker Desktop for Windows rather than Docker in WSL.

## 🆘 Support

### Q: Where to ask for help?
**A:**
1. Check this FAQ
2. Re-read the [deployment guide](DEPLOYMENT-EN.md)
3. Create a GitHub issue with your logs

### Q: How to attach logs to a bug report?
**A:**
```bash
docker-compose logs > logs-cardmanager.txt
```
Attach this file to your GitHub issue.

### Q: Is CardManager open source?
**A:** Check the project license on GitHub.

---

**💡 Question not resolved?** Create a [GitHub issue](https://github.com/ialame/docker-cardmanager-github/issues) with your logs!
