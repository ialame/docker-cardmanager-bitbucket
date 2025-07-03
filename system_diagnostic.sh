#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🔍 Diagnostic approfondi : URL Painter toujours en localhost${NC}"
echo "================================================================"

echo -e "${YELLOW}1. Analyse du problème...${NC}"
echo "❌ Malgré PAINTER_SERVICE_URL=http://painter:8081"
echo "❌ GestionCarte utilise encore localhost:8081"
echo "💡 Le code Java a probablement une URL hardcodée"

echo ""
echo -e "${YELLOW}2. Investigation dans le conteneur GestionCarte...${NC}"

echo -e "${BLUE}🔍 Fichiers de configuration Spring dans le JAR :${NC}"
docker exec cardmanager-gestioncarte sh -c "
cd /app
echo '=== Configuration application.properties ==='
unzip -p app.jar BOOT-INF/classes/application.properties 2>/dev/null | grep -i painter || echo 'Pas de config painter dans application.properties'

echo ''
echo '=== Configuration application-docker.properties ==='
unzip -p app.jar BOOT-INF/classes/application-docker.properties 2>/dev/null | grep -i painter || echo 'Pas de config painter dans application-docker.properties'

echo ''
echo '=== Recherche de localhost dans les configs ==='
unzip -p app.jar BOOT-INF/classes/application*.properties 2>/dev/null | grep -i localhost || echo 'Pas de localhost trouvé dans les configs'

echo ''
echo '=== Variables d'environnement actuelles ==='
env | grep -i painter
"

echo ""
echo -e "${YELLOW}3. Test de résolution DNS dans le conteneur...${NC}"

echo -e "${BLUE}🌐 Test de résolution DNS :${NC}"
docker exec cardmanager-gestioncarte sh -c "
echo 'Résolution de painter :'
nslookup painter 2>/dev/null || echo 'nslookup non disponible'

echo 'Test ping painter :'
ping -c 1 painter 2>/dev/null || echo 'ping échoué'

echo 'Test port 8081 sur painter :'
nc -zv painter 8081 2>&1 || echo 'netcat non disponible, test avec wget'

echo 'Test HTTP painter :'
wget -qO- --timeout=5 http://painter:8081/ 2>/dev/null | head -5 || echo 'wget échec'
"

echo ""
echo -e "${YELLOW}4. Solution : Override de la configuration par variables d'environnement...${NC}"

# Créer une configuration qui force TOUTES les variantes possibles
cat > docker-compose-force-painter.yml << 'EOF'
services:
  mariadb-standalone:
    image: mariadb:11.2
    container_name: cardmanager-mariadb
    environment:
      MARIADB_ROOT_PASSWORD: root_password
      MARIADB_DATABASE: dev
      MARIADB_USER: ia
      MARIADB_PASSWORD: foufafou
      MARIADB_CHARACTER_SET_SERVER: utf8mb4
      MARIADB_COLLATION_SERVER: utf8mb4_unicode_ci
    ports:
      - "3308:3306"
    volumes:
      - cardmanager_db_data:/var/lib/mysql
      - ./init-db:/docker-entrypoint-initdb.d:ro
    networks:
      - cardmanager-network
    restart: unless-stopped

  painter:
    build:
      context: .
      dockerfile: docker/painter/Dockerfile
    container_name: cardmanager-painter
    depends_on:
      - mariadb-standalone
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - PAINTER_IMAGE_STORAGE_PATH=/app/images
      - MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics
      - SERVER_PORT=8081
      - SERVER_ADDRESS=0.0.0.0
    ports:
      - "8081:8081"
    volumes:
      - cardmanager_images:/app/images
    networks:
      - cardmanager-network
    restart: unless-stopped

  gestioncarte:
    build:
      context: .
      dockerfile: docker/gestioncarte/Dockerfile
    container_name: cardmanager-gestioncarte
    depends_on:
      - mariadb-standalone
      - painter
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker

      # FORCER TOUTES LES VARIANTES POSSIBLES D'URL PAINTER
      - PAINTER_SERVICE_URL=http://painter:8081
      - PAINTER_API_BASE_URL=http://painter:8081
      - PAINTER_BASE_URL=http://painter:8081
      - PAINTER_URL=http://painter:8081
      - PAINTER_HOST=painter
      - PAINTER_PORT=8081
      - PAINTER_ENDPOINT=http://painter:8081
      - PAINTER_API_URL=http://painter:8081
      - PAINTER_SERVICE_HOST=painter
      - PAINTER_SERVICE_PORT=8081

      # Override des configurations Spring qui pourraient utiliser localhost
      - SPRING_PAINTER_SERVICE_URL=http://painter:8081
      - SPRING_PAINTER_BASE_URL=http://painter:8081
      - SPRING_PAINTER_URL=http://painter:8081

      # Configuration générale Spring
      - SPRING_LIQUIBASE_ENABLED=false
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics
      - SERVER_PORT=8080
      - SERVER_ADDRESS=0.0.0.0

      # Force la configuration réseau
      - JAVA_OPTS=-Dpainter.service.url=http://painter:8081 -Dpainter.base.url=http://painter:8081

    ports:
      - "8080:8080"
    networks:
      - cardmanager-network
    restart: unless-stopped

  nginx-images:
    image: nginx:alpine
    container_name: cardmanager-nginx
    ports:
      - "8082:80"
    volumes:
      - cardmanager_images:/usr/share/nginx/html/images:ro
      - ./nginx-images.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - cardmanager-network
    restart: unless-stopped
    depends_on:
      - painter

volumes:
  cardmanager_db_data:
    driver: local
  cardmanager_images:
    driver: local

networks:
  cardmanager-network:
    driver: bridge
EOF

echo -e "${YELLOW}5. Redémarrage avec la configuration forcée...${NC}"

# Arrêter et redémarrer avec la nouvelle config
docker-compose down
docker-compose -f docker-compose-force-painter.yml up -d

echo -e "${YELLOW}6. Attente du redémarrage (90 secondes)...${NC}"
sleep 90

echo -e "${YELLOW}7. Tests post-correction...${NC}"

echo -e "${BLUE}📊 État des services :${NC}"
docker-compose -f docker-compose-force-painter.yml ps

echo ""
echo -e "${BLUE}🔍 Test réseau depuis GestionCarte :${NC}"
docker exec cardmanager-gestioncarte sh -c "
echo 'Test 1: wget painter:8081'
wget -qO- --timeout=5 http://painter:8081/ 2>/dev/null && echo 'SUCCESS' || echo 'FAILED'

echo 'Test 2: Environnement Painter'
env | grep -i painter | head -5
"

echo ""
echo -e "${YELLOW}8. Surveillance des logs pour vérifier la correction...${NC}"
echo -e "${BLUE}Surveillance pendant 15 secondes - si 'localhost:8081' apparaît encore, nous devrons modifier le code source...${NC}"

# Surveiller les logs pour voir si localhost apparaît encore
timeout 15 docker-compose -f docker-compose-force-painter.yml logs -f gestioncarte 2>/dev/null | grep -E "(localhost|painter|8081)" || true

echo ""
echo -e "${YELLOW}9. Test d'upload pour déclencher l'erreur...${NC}"

# Créer un fichier test et essayer l'upload
echo "Test upload CardManager" > /tmp/test_card.txt
echo -n "Test upload API : "
UPLOAD_TEST=$(curl -s -X PUT -F "file=@/tmp/test_card.txt" http://localhost:8080/api/pokemon-cards/1/image 2>&1)
if echo "$UPLOAD_TEST" | grep -q "Connection refused"; then
    echo -e "${RED}ÉCHEC - localhost encore utilisé${NC}"
    echo -e "${YELLOW}💡 Solution alternative nécessaire : modifier le code source ou reconstruire l'image${NC}"
else
    echo -e "${GREEN}SUCCÈS - Plus d'erreur localhost${NC}"
fi

rm -f /tmp/test_card.txt

echo ""
echo -e "${BLUE}💡 ANALYSE DES RÉSULTATS :${NC}"
echo "========================================="

# Vérifier si localhost apparaît encore dans les logs récents
RECENT_LOGS=$(docker-compose -f docker-compose-force-painter.yml logs --tail=20 gestioncarte 2>/dev/null)
if echo "$RECENT_LOGS" | grep -q "localhost.*8081"; then
    echo -e "${RED}❌ PROBLÈME PERSISTANT${NC}"
    echo "Le code Java GestionCarte a une URL hardcodée 'localhost:8081'"
    echo ""
    echo -e "${YELLOW}🔧 SOLUTIONS POSSIBLES :${NC}"
    echo "1. Modifier le code source dans les dépôts Bitbucket"
    echo "2. Reconstruire l'image avec un patch"
    echo "3. Utiliser un proxy réseau interne"
    echo "4. Modifier les fichiers de config dans le conteneur"
else
    echo -e "${GREEN}✅ PROBLÈME RÉSOLU${NC}"
    echo "La configuration forcée fonctionne !"
fi

echo ""
read -p "Voulez-vous appliquer cette configuration définitivement ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp docker-compose.yml "docker-compose.yml.backup-pre-force-$(date +%Y%m%d-%H%M%S)"
    cp docker-compose-force-painter.yml docker-compose.yml
    echo -e "${GREEN}✅ Configuration avec override forcé appliquée${NC}"
    echo -e "${YELLOW}💾 Sauvegarde créée${NC}"
else
    echo -e "${YELLOW}Configuration disponible dans docker-compose-force-painter.yml${NC}"
fi