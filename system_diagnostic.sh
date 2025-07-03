#!/bin/bash

echo "🔄 Restauration de la configuration fonctionnelle"
echo "=============================================="

# 1. Analyser les différences avec la version qui fonctionne
echo "1. Analyse des différences avec la version fonctionnelle..."

echo "📋 DIFFÉRENCES IDENTIFIÉES :"
echo "=============================="
echo "✅ Version qui marche :"
echo "   • Variable: MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics"
echo "   • Nginx config: ./nginx-images.conf (fichier spécifique)"
echo "   • Volumes: cardmanager_images:/app/images (montage direct)"
echo "   • MariaDB: healthcheck avec healthcheck.sh"
echo ""
echo "❌ Notre version actuelle :"
echo "   • Pas de MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE"
echo "   • Nginx config: ./docker/nginx/nginx.conf (fichier générique)"
echo "   • Volumes: mêmes mais configuration différente"
echo "   • Contrôleurs custom ajoutés manuellement"

# 2. Restaurer la configuration nginx de la version qui marche
echo ""
echo "2. Restauration de la configuration nginx fonctionnelle..."

cat > nginx-images.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location /images/ {
        alias /usr/share/nginx/html/images/;
        add_header Access-Control-Allow-Origin *;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }

    location / {
        return 200 '<!DOCTYPE html><html><head><title>CardManager Images</title></head><body><h1>🖼️ CardManager Images Server</h1><p><a href="/images/">Browse Images</a></p></body></html>';
        add_header Content-Type text/html;
    }

    location /health {
        return 200 '{"status":"ok","service":"images"}';
        add_header Content-Type application/json;
    }
}
EOF

echo "✅ Configuration nginx-images.conf restaurée"

# 3. Créer un docker-compose.yml basé sur la version qui fonctionne
echo ""
echo "3. Restauration du docker-compose.yml fonctionnel..."

cat > docker-compose.yml << 'EOF'
services:
  mariadb-standalone:
    image: mariadb:11.4
    container_name: cardmanager-mariadb
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root123}
      MYSQL_DATABASE: ${LOCAL_DB_NAME:-dev}
      MYSQL_USER: ${LOCAL_DB_USER:-ia}
      MYSQL_PASSWORD: ${LOCAL_DB_PASS:-foufafou}
    ports:
      - "${DB_PORT:-3308}:3306"
    volumes:
      - cardmanager_db_data:/var/lib/mysql
      - ./init-db:/docker-entrypoint-initdb.d:ro
    networks:
      - cardmanager-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "${LOCAL_DB_USER:-ia}", "-p${LOCAL_DB_PASS:-foufafou}"]
      start_period: 120s
      interval: 10s
      timeout: 10s
      retries: 20
    restart: unless-stopped

  painter:
    build:
      context: .
      dockerfile: docker/painter/Dockerfile
      args:
        MASON_REPO_URL: ${MASON_REPO_URL:-git@bitbucket.org:pcafxc/mason.git}
        MASON_BRANCH: ${MASON_BRANCH:-feature/RETRIEVER-511}
        PAINTER_REPO_URL: ${PAINTER_REPO_URL:-git@bitbucket.org:pcafxc/painter.git}
        PAINTER_BRANCH: ${PAINTER_BRANCH:-feature/card-manager-511}
    container_name: cardmanager-painter
    depends_on:
      mariadb-standalone:
        condition: service_healthy
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker
      - PAINTER_IMAGE_STORAGE_PATH=/app/images
      - RETRIEVER_SECURITY_LOGIN_ENABLED=false
      - MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - SPRING_LIQUIBASE_ENABLED=false
    ports:
      - "${PAINTER_PORT:-8081}:8081"
    volumes:
      - cardmanager_images:/app/images
    networks:
      - cardmanager-network
    restart: unless-stopped

  gestioncarte:
    build:
      context: .
      dockerfile: docker/gestioncarte/Dockerfile
      args:
        MASON_REPO_URL: ${MASON_REPO_URL:-git@bitbucket.org:pcafxc/mason.git}
        MASON_BRANCH: ${MASON_BRANCH:-feature/RETRIEVER-511}
        PAINTER_REPO_URL: ${PAINTER_REPO_URL:-git@bitbucket.org:pcafxc/painter.git}
        PAINTER_BRANCH: ${PAINTER_BRANCH:-feature/card-manager-511}
        GESTIONCARTE_REPO_URL: ${GESTIONCARTE_REPO_URL:-git@bitbucket.org:pcafxc/gestioncarte.git}
        GESTIONCARTE_BRANCH: ${GESTIONCARTE_BRANCH:-feature/card-manager-511}
    container_name: cardmanager-gestioncarte
    depends_on:
      mariadb-standalone:
        condition: service_healthy
      painter:
        condition: service_started
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mariadb://mariadb-standalone:3306/dev
      - SPRING_DATASOURCE_USERNAME=ia
      - SPRING_DATASOURCE_PASSWORD=foufafou
      - SPRING_PROFILES_ACTIVE=docker
      - PAINTER_SERVICE_URL=http://painter:8081
      - PAINTER_BASE_URL=http://painter:8081
      - PAINTER_PUBLIC_URL=http://painter:8081
      - RETRIEVER_SECURITY_LOGIN_ENABLED=false
      - MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - SPRING_LIQUIBASE_ENABLED=false
    ports:
      - "${GESTIONCARTE_PORT:-8080}:8080"
    networks:
      - cardmanager-network
    restart: unless-stopped

  nginx-images:
    image: nginx:alpine
    container_name: cardmanager-nginx
    ports:
      - "${NGINX_PORT:-8082}:80"
    volumes:
      - cardmanager_images:/usr/share/nginx/html/images:ro
      - ./nginx-images.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - painter
    networks:
      - cardmanager-network
    restart: unless-stopped

volumes:
  cardmanager_db_data:
    external: false
  cardmanager_images:
    external: false

networks:
  cardmanager-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml restauré selon la version fonctionnelle"

# 4. Restaurer le Dockerfile original (sans nos contrôleurs custom)
echo ""
echo "4. Restauration du Dockerfile Painter original..."

if [ -f "docker/painter/Dockerfile.backup" ]; then
    cp docker/painter/Dockerfile.backup docker/painter/Dockerfile
    echo "✅ Dockerfile original restauré depuis la sauvegarde"
else
    # Créer un Dockerfile basique si pas de sauvegarde
    cat > docker/painter/Dockerfile << 'EOF'
FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG PAINTER_BRANCH=feature/card-manager-511

# Installer git et openssh-client pour SSH
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Copier les clés SSH depuis le contexte de build
COPY ./docker/ssh-keys/ /root/.ssh/

# Configurer les permissions SSH
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    chmod 644 /root/.ssh/bitbucket_ed25519.pub && \
    chmod 644 /root/.ssh/config && \
    ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts && \
    chmod 644 /root/.ssh/known_hosts

# Répertoire de travail
WORKDIR /usr/src/app

# Créer la structure Maven parent
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Cloner Mason d'abord (dépendance)
RUN git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Cloner Painter
RUN git clone --depth 1 --branch ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter

# Construire le parent
RUN mvn install -N

# Construire Mason (dépendance de Painter)
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Construire Painter
WORKDIR /usr/src/app/painter
RUN mvn clean package -DskipTests -B

# Image finale pour l'exécution
FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="cardmanager@example.com"
LABEL description="Painter Service - Original Version"

# Installer wget pour le health check
RUN apk add --no-cache wget

# Répertoire de travail
WORKDIR /app

# Copier le JAR principal de Painter
COPY --from=builder /usr/src/app/painter/painter/target/*.jar app.jar

# Créer le dossier pour les images
RUN mkdir -p /app/images

# Configuration JVM optimisée
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Variables d'environnement pour Painter
ENV PAINTER_IMAGE_STORAGE_PATH="/app/images"
ENV SPRING_PROFILES_ACTIVE="docker"

# Port d'exposition
EXPOSE 8081

# Health check basique
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF

    echo "✅ Dockerfile basique créé"
fi

# 5. Reconstruction avec la configuration originale
echo ""
echo "5. Test avec la configuration originale..."

echo "🛑 Arrêt des services actuels..."
docker-compose down

echo "🔨 Construction avec la configuration originale..."
docker-compose build --no-cache painter

if [ $? -eq 0 ]; then
    echo "✅ Construction réussie"

    echo "🚀 Démarrage avec la configuration originale..."
    docker-compose up -d

    echo "⏳ Attente du démarrage (90 secondes)..."
    sleep 90

    # 6. Tests de la configuration originale
    echo ""
    echo "6. Tests de la configuration originale..."

    echo "📊 État des services :"
    docker-compose ps

    echo ""
    echo "🔍 Tests des endpoints originaux :"

    # Test health check
    HEALTH=$(curl -s --max-time 15 http://localhost:8081/actuator/health 2>/dev/null || echo "ECHEC")
    echo "   Health check: $HEALTH"

    # Test info
    INFO=$(curl -s --max-time 15 http://localhost:8081/actuator/info 2>/dev/null || echo "ECHEC")
    echo "   Info: $INFO"

    # Test metrics
    METRICS=$(curl -s --max-time 15 http://localhost:8081/actuator/metrics 2>/dev/null || echo "ECHEC")
    echo "   Metrics: ${METRICS:0:100}..."

    # Test nginx
    NGINX=$(curl -s --max-time 10 http://localhost:8082/ 2>/dev/null || echo "ECHEC")
    echo "   Nginx: ${NGINX:0:200}..."

    # Test images
    IMAGES=$(curl -s --max-time 10 http://localhost:8082/images/ 2>/dev/null || echo "ECHEC")
    echo "   Images: ${IMAGES:0:200}..."

    echo ""
    echo "🔍 Recherche d'endpoints d'upload natifs..."

    # Tester des endpoints possibles dans le projet original
    for endpoint in "/upload" "/api/upload" "/files/upload" "/image/upload" "/painter/upload"; do
        echo -n "   Testing $endpoint: "
        RESULT=$(curl -s --max-time 5 http://localhost:8081$endpoint 2>/dev/null || echo "ECHEC")
        if echo "$RESULT" | grep -q -v "404"; then
            echo "✅ Endpoint trouvé !"
            echo "      Response: ${RESULT:0:100}..."
        else
            echo "❌ Non disponible"
        fi
    done

    echo ""
    echo "🔍 Test de l'interface GestionCarte..."

    GESTION_APP=$(curl -s --max-time 10 http://localhost:8080 2>/dev/null || echo "ECHEC")
    if echo "$GESTION_APP" | grep -q -E "(html|HTML|upload|Upload)"; then
        echo "✅ Interface GestionCarte accessible"
        echo "💡 Vérifiez http://localhost:8080 pour voir s'il y a une fonction d'upload"
    else
        echo "⚠️ Interface GestionCarte : ${GESTION_APP:0:100}..."
    fi

else
    echo "❌ Échec de construction avec la configuration originale"
    echo "Logs d'erreur :"
    docker-compose logs painter 2>&1 | tail -15
fi

echo ""
echo "🎯 RÉSUMÉ DE LA RESTAURATION :"
echo "============================="

if echo "$HEALTH" | grep -q '"status":"UP"'; then
    echo "✅ Configuration originale restaurée et fonctionnelle"
    echo "✅ Endpoints Actuator disponibles (/actuator/health, /actuator/info, /actuator/metrics)"
    echo "✅ Communication avec Painter opérationnelle"

    if echo "$NGINX" | grep -q -E "(CardManager|Images)"; then
        echo "✅ Nginx Images configuré correctement"
    else
        echo "⚠️ Nginx Images nécessite vérification"
    fi

    echo ""
    echo "🔍 PROCHAINES ÉTAPES :"
    echo "====================="
    echo "1. Vérifiez l'interface : http://localhost:8080"
    echo "2. Cherchez une fonction d'upload dans l'interface web"
    echo "3. Si pas d'upload natif, le projet original n'en a peut-être pas"
    echo "4. Dans ce cas, nos contrôleurs custom étaient la bonne approche"
    echo ""
    echo "💡 HYPOTHÈSE :"
    echo "   Le projet original fonctionne mais n'a peut-être pas d'upload d'images"
    echo "   L'upload se fait peut-être via l'interface GestionCarte directement"

else
    echo "❌ Problème avec la configuration originale"
    echo "💡 Le problème est plus profond qu'une simple configuration"
fi

echo ""
echo "📱 URLs à tester :"
echo "=================="
echo "• Application   : http://localhost:8080"
echo "• Painter Health: http://localhost:8081/actuator/health"
echo "• Painter Info  : http://localhost:8081/actuator/info"
echo "• Images        : http://localhost:8082/images/"

echo ""
echo "✅ Restauration terminée !"