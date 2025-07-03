#!/bin/bash

# =============================================================================
# FIX RAPIDE DOCKERFILE GESTIONCARTE
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 FIX RAPIDE DOCKERFILE GESTIONCARTE${NC}"
echo "===================================="

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. RESTAURER LE DOCKERFILE ORIGINAL
print_step "1. Restauration du Dockerfile original"

# Trouver la dernière sauvegarde
if ls docker/gestioncarte/Dockerfile.backup-* 1> /dev/null 2>&1; then
    latest_backup=$(ls docker/gestioncarte/Dockerfile.backup-* | tail -1)
    cp "$latest_backup" docker/gestioncarte/Dockerfile
    print_success "Dockerfile restauré depuis $latest_backup"
else
    print_error "Aucune sauvegarde trouvée"

    # Créer un Dockerfile minimal s'il n'existe pas
    if [ ! -f "docker/gestioncarte/Dockerfile" ]; then
        echo "🔨 Création d'un Dockerfile minimal..."
        cat > docker/gestioncarte/Dockerfile << 'EOF'
# Utiliser le même Dockerfile que Painter mais pour GestionCarte
FROM maven:3.9.6-eclipse-temurin-21 as builder

# Installation des outils nécessaires
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Configuration SSH pour Bitbucket
COPY ./docker/ssh-keys/ /root/.ssh/
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    chmod 644 /root/.ssh/bitbucket_ed25519.pub && \
    chmod 644 /root/.ssh/config && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# Répertoire de travail
WORKDIR /usr/src/app

# Copier le POM parent
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Cloner les dépôts
RUN git clone --depth 1 --branch feature/RETRIEVER-511 git@bitbucket.org:pcafxc/mason.git mason
RUN git clone --depth 1 --branch feature/card-manager-511 git@bitbucket.org:pcafxc/painter.git painter
RUN git clone --depth 1 --branch feature/card-manager-511 git@bitbucket.org:pcafxc/gestioncarte.git gestioncarte

# Configuration application.properties pour GestionCarte
COPY ./config/application-docker.properties gestioncarte/src/main/resources/application-docker.properties

# Installation du parent
RUN mvn install -N

# Build Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Build Painter
WORKDIR /usr/src/app/painter
RUN mvn clean install -DskipTests -B

# Build GestionCarte
WORKDIR /usr/src/app/gestioncarte
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine

# Installation des outils de diagnostic
RUN apk add --no-cache wget

# Répertoire de travail
WORKDIR /app

# Copier le JAR depuis le builder
COPY --from=builder /usr/src/app/gestioncarte/target/*.jar app.jar

# Exposer le port
EXPOSE 8080

# Démarrage avec profil docker
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dspring.profiles.active=docker -jar app.jar"]
EOF
        print_success "Dockerfile minimal créé"
    fi
fi

# 2. SOLUTION ALTERNATIVE - UTILISER DOCKER-COMPOSE SANS REBUILD
print_step "2. Solution alternative - Variables d'environnement"

echo "🔧 Modification directe des variables d'environnement..."

# Créer un fichier .env local pour forcer les bonnes URLs
cat > .env.painter.override << 'EOF'
# Override pour forcer la bonne URL Painter
PAINTER_SERVICE_URL=http://painter:8081
PAINTER_BASE_URL=http://painter:8081
PAINTER_API_URL=http://painter:8081
EOF

print_success "Fichier d'override créé"

# 3. MODIFIER DOCKER-COMPOSE POUR FORCER LES VARIABLES
print_step "3. Modification docker-compose pour forcer les variables"

# Backup du docker-compose
cp docker-compose.yml docker-compose.yml.backup-$(date +%Y%m%d-%H%M%S)

# Modifier la section gestioncarte pour forcer toutes les variables Painter
cat > temp_gestioncarte_env.txt << 'EOF'
      # CORRECTION CRITIQUE - URLs Painter
      - PAINTER_SERVICE_URL=http://painter:8081
      - PAINTER_BASE_URL=http://painter:8081
      - PAINTER_API_BASE_URL=http://painter:8081
      - SPRING_WEBFLUX_BASE_URL_PAINTER=http://painter:8081

      # Configuration client Painter
      - PAINTER_CLIENT_BASE_URL=http://painter:8081
      - PAINTER_CLIENT_URL=http://painter:8081

      # Debug WebClient
      - LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_WEB_REACTIVE_FUNCTION_CLIENT=DEBUG
      - LOGGING_LEVEL_COM_PCAGRADE_PAINTER_CLIENT=DEBUG
EOF

# Injecter dans docker-compose.yml
awk '
/gestioncarte:/{in_gestioncarte=1}
in_gestioncarte && /environment:/{
    print
    while ((getline line < "temp_gestioncarte_env.txt") > 0) print line
    close("temp_gestioncarte_env.txt")
    next
}
/^  [a-zA-Z]/ && in_gestioncarte && !/gestioncarte/{in_gestioncarte=0}
{print}
' docker-compose.yml > docker-compose.yml.new

mv docker-compose.yml.new docker-compose.yml
rm temp_gestioncarte_env.txt

print_success "Variables Painter ajoutées à docker-compose.yml"

# 4. REDÉMARRAGE SANS REBUILD
print_step "4. Redémarrage sans rebuild"

echo "🚀 Redémarrage des services avec nouvelles variables..."
docker-compose up -d painter gestioncarte

# Attendre le démarrage
echo "⏳ Attente du démarrage..."
for i in {1..60}; do
    painter_status=$(curl -s http://localhost:8081/actuator/health 2>/dev/null | grep -o "UP" || echo "DOWN")
    gestion_status=$(curl -s http://localhost:8080/actuator/health 2>/dev/null | grep -o "UP" || echo "DOWN")

    if [[ "$painter_status" == "UP" && "$gestion_status" == "UP" ]]; then
        print_success "Services redémarrés avec succès"
        break
    fi
    echo -n "."
    sleep 2
done

# 5. VÉRIFICATION COMPLÈTE
print_step "5. Vérification complète"

echo "🧪 Vérification des variables d'environnement :"
docker exec cardmanager-gestioncarte env | grep -i painter | head -10

echo ""
echo "🔗 Test communication :"
comm_result=$(docker exec cardmanager-gestioncarte wget -qO- --timeout=5 "http://painter:8081/actuator/health" 2>/dev/null)
if echo "$comm_result" | grep -q "UP"; then
    print_success "Communication GestionCarte → Painter : OK"
else
    print_error "Communication GestionCarte → Painter : FAIL"
    echo "Résultat: $comm_result"
fi

# 6. TEST D'UPLOAD FINAL
print_step "6. Test d'upload final"

echo "🧪 Test d'upload depuis GestionCarte..."

# Créer un fichier de test dans GestionCarte
docker exec cardmanager-gestioncarte sh -c 'echo "test upload final" > /tmp/test-final.txt'

# Test upload via l'endpoint
upload_result=$(docker exec cardmanager-gestioncarte sh -c '
curl -s -X POST \
  -F "file=@/tmp/test-final.txt" \
  http://painter:8081/upload
')

if echo "$upload_result" | grep -q "success"; then
    print_success "Upload test réussi !"
    echo "Réponse: $upload_result" | head -3
else
    print_error "Upload test échoué"
    echo "Réponse: $upload_result"
fi

# 7. MONITORING SIMPLE
print_step "7. Script de monitoring simple"

cat > quick_monitor.sh << 'EOF'
#!/bin/bash

echo "🎯 MONITORING SIMPLE"
echo "==================="

echo "📊 État des services :"
docker-compose ps | grep -E "(painter|gestioncarte)"

echo ""
echo "🔗 Variables Painter dans GestionCarte :"
docker exec cardmanager-gestioncarte env | grep PAINTER_SERVICE_URL

echo ""
echo "📁 Fichiers dans /app/images :"
docker exec cardmanager-painter ls -la /app/images/ | grep -v "^total"

echo ""
echo "🧪 Test de communication :"
if docker exec cardmanager-gestioncarte wget -qO- --timeout=3 "http://painter:8081/actuator/health" 2>/dev/null | grep -q "UP"; then
    echo "✅ Communication OK"
else
    echo "❌ Communication FAIL"
fi

echo ""
echo "🎯 Testez maintenant l'upload via http://localhost:8080"
EOF

chmod +x quick_monitor.sh
print_success "Monitoring simple créé : ./quick_monitor.sh"

# 8. RÉSUMÉ
print_step "8. Résumé"

echo ""
print_success "🎉 Fix alternatif appliqué !"
echo ""
echo "✅ Variables d'environnement corrigées"
echo "✅ Communication inter-services testée"
echo "✅ Services redémarrés sans rebuild"
echo ""
echo "🧪 Actions suivantes :"
echo "   1. ./quick_monitor.sh (vérification rapide)"
echo "   2. http://localhost:8080 (test interface)"
echo "   3. Tentez un upload d'image"
echo ""
print_success "La communication devrait maintenant fonctionner !"