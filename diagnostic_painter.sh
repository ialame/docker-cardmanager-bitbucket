#!/bin/bash

# =============================================================================
# DIAGNOSTIC COMPLET - SAUVEGARDE IMAGES
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 DIAGNOSTIC COMPLET - SAUVEGARDE IMAGES${NC}"
echo "=========================================="

print_header() {
    echo -e "${CYAN}📋 $1${NC}"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. ÉTAT DU SYSTÈME
print_header "1. ÉTAT DU SYSTÈME"

echo "🏥 État des containers :"
docker-compose ps

echo ""
echo "🌐 Test des endpoints :"
gestion_health=$(curl -s --max-time 5 http://localhost:8080/actuator/health || echo "ERROR")
painter_health=$(curl -s --max-time 5 http://localhost:8081/actuator/health || echo "ERROR")
nginx_status=$(curl -s --max-time 5 http://localhost:8082/ || echo "ERROR")

if echo "$gestion_health" | grep -q "UP"; then
    print_success "GestionCarte health : OK"
else
    print_error "GestionCarte health : KO"
fi

if echo "$painter_health" | grep -q "UP"; then
    print_success "Painter health : OK"
else
    print_error "Painter health : KO"
fi

if echo "$nginx_status" | grep -q "nginx\|Index\|directory"; then
    print_success "Nginx images : OK"
else
    print_error "Nginx images : KO"
fi

# 2. CONFIGURATION DES CHEMINS D'IMAGES
print_header "2. CONFIGURATION DES CHEMINS D'IMAGES"

echo "🔧 Configuration Painter :"
painter_storage=$(docker exec cardmanager-painter env | grep -i image)
if [[ -n "$painter_storage" ]]; then
    print_success "Variables d'images trouvées"
    echo "$painter_storage"
else
    print_error "Aucune variable d'image trouvée"
fi

echo ""
echo "🔧 Configuration GestionCarte :"
gestion_painter_config=$(docker exec cardmanager-gestioncarte env | grep -i painter)
if [[ -n "$gestion_painter_config" ]]; then
    print_success "Configuration Painter trouvée"
    echo "$gestion_painter_config"
else
    print_error "Configuration Painter manquante dans GestionCarte"
fi

# 3. ÉTAT DU SYSTÈME DE FICHIERS
print_header "3. ÉTAT DU SYSTÈME DE FICHIERS"

echo "📁 Dossier images Painter :"
if docker exec cardmanager-painter test -d /app/images; then
    print_success "Dossier /app/images existe"

    # Permissions
    permissions=$(docker exec cardmanager-painter ls -ld /app/images)
    print_info "Permissions : $permissions"

    # Contenu
    image_count=$(docker exec cardmanager-painter find /app/images -type f | wc -l)
    print_info "Nombre de fichiers : $image_count"

    if [[ $image_count -gt 0 ]]; then
        print_info "Fichiers présents :"
        docker exec cardmanager-painter ls -la /app/images/ | head -10
    else
        print_warning "Aucun fichier d'image trouvé"
    fi
else
    print_error "Dossier /app/images n'existe pas"
fi

echo ""
echo "🗄️ Volume Docker :"
volume_info=$(docker volume inspect cardmanager_images 2>/dev/null)
if [[ $? -eq 0 ]]; then
    print_success "Volume cardmanager_images existe"
    mountpoint=$(echo "$volume_info" | grep -o '"Mountpoint": "[^"]*"' | cut -d'"' -f4)
    print_info "Mountpoint : $mountpoint"
else
    print_error "Volume cardmanager_images n'existe pas"
fi

# 4. LOGS ET ERREURS
print_header "4. LOGS ET ERREURS"

echo "📋 Logs récents Painter (recherche d'opérations sur images) :"
painter_image_logs=$(docker-compose logs --tail=50 painter | grep -i -E "(image|upload|save|file|storage)" | tail -10)
if [[ -n "$painter_image_logs" ]]; then
    print_info "Logs d'images trouvés :"
    echo "$painter_image_logs"
else
    print_warning "Aucun log d'opération sur images trouvé"
fi

echo ""
echo "📋 Logs récents GestionCarte (recherche d'appels vers Painter) :"
gestion_painter_logs=$(docker-compose logs --tail=50 gestioncarte | grep -i -E "(painter|8081|image|upload)" | tail -10)
if [[ -n "$gestion_painter_logs" ]]; then
    print_info "Logs d'appels Painter trouvés :"
    echo "$gestion_painter_logs"
else
    print_warning "Aucun log d'appel vers Painter trouvé"
fi

echo ""
echo "🚨 Erreurs récentes :"
recent_errors=$(docker-compose logs --tail=100 painter gestioncarte | grep -i -E "(error|exception|failed)" | tail -5)
if [[ -n "$recent_errors" ]]; then
    print_error "Erreurs trouvées :"
    echo "$recent_errors"
else
    print_success "Aucune erreur récente trouvée"
fi

# 5. TEST DE L'API PAINTER
print_header "5. TEST DE L'API PAINTER"

echo "🧪 Test des endpoints Painter :"

# Test des endpoints API
endpoints_to_test=(
    "/actuator/health"
    "/api/images"
    "/images"
    "/painter/images"
)

for endpoint in "${endpoints_to_test[@]}"; do
    response=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" http://localhost:8081$endpoint)
    if [[ "$response" == "200" ]]; then
        print_success "Endpoint $endpoint : $response (OK)"
    elif [[ "$response" == "404" ]]; then
        print_warning "Endpoint $endpoint : $response (Non trouvé)"
    else
        print_error "Endpoint $endpoint : $response"
    fi
done

# 6. CONFIGURATION APPLICATION.PROPERTIES
print_header "6. CONFIGURATION APPLICATION.PROPERTIES"

echo "📋 Configuration storage dans application.properties :"
app_storage_config=$(docker exec cardmanager-painter unzip -p /app/app.jar BOOT-INF/classes/application.properties | grep -E "(image|storage|upload)")
if [[ -n "$app_storage_config" ]]; then
    print_success "Configuration de stockage trouvée"
    echo "$app_storage_config"
else
    print_error "Configuration de stockage manquante"
fi

# 7. TEST MANUEL DE COMMUNICATION
print_header "7. TEST MANUEL DE COMMUNICATION"

echo "🔗 Test communication GestionCarte → Painter :"

# Test de ping simple
if docker exec cardmanager-gestioncarte ping -c 1 painter >/dev/null 2>&1; then
    print_success "Ping GestionCarte → Painter : OK"
else
    print_error "Ping GestionCarte → Painter : KO"
fi

# Test HTTP simple
gestion_to_painter=$(docker exec cardmanager-gestioncarte wget -qO- --timeout=5 "http://painter:8081/actuator/health" 2>/dev/null)
if echo "$gestion_to_painter" | grep -q "UP"; then
    print_success "HTTP GestionCarte → Painter : OK"
else
    print_error "HTTP GestionCarte → Painter : KO"
fi

# 8. RECOMMANDATIONS
print_header "8. RECOMMANDATIONS"

issues_found=0
recommendations=()

# Vérifier si les images sont uploadées mais pas sauvegardées
if [[ $image_count -eq 0 ]]; then
    print_warning "Aucune image sauvegardée détectée"
    recommendations+=("Testez l'upload d'une image via http://localhost:8080")
    recommendations+=("Surveillez les logs : docker-compose logs -f painter gestioncarte")
    ((issues_found++))
fi

# Vérifier la configuration
if [[ -z "$gestion_painter_config" ]]; then
    print_error "Configuration Painter manquante dans GestionCarte"
    recommendations+=("Vérifiez PAINTER_SERVICE_URL dans docker-compose.yml")
    ((issues_found++))
fi

# Vérifier les logs d'erreurs
if [[ -n "$recent_errors" ]]; then
    print_error "Erreurs récentes détectées"
    recommendations+=("Analysez les erreurs dans les logs")
    ((issues_found++))
fi

echo ""
if [[ $issues_found -eq 0 ]]; then
    print_success "Aucun problème majeur détecté dans la configuration"
    echo ""
    print_info "🎯 Actions recommandées :"
    echo "1. Uploadez une image via http://localhost:8080"
    echo "2. Surveillez les logs : docker-compose logs -f painter"
    echo "3. Vérifiez les images : docker exec cardmanager-painter ls -la /app/images/"
    echo "4. Consultez la galerie : http://localhost:8082/images/"
else
    print_error "$issues_found problème(s) détecté(s)"
    echo ""
    print_info "🔧 Recommandations :"
    for i in "${!recommendations[@]}"; do
        echo "   $((i+1)). ${recommendations[$i]}"
    done
fi

# 9. SCRIPT DE TEST LIVE
print_header "9. SCRIPT DE TEST LIVE"

echo "📝 Script pour tester l'upload en temps réel :"
cat << 'EOF'
# Exécutez ce script dans un autre terminal pendant que vous uploadez :

# Terminal 1 : Surveiller les logs
docker-compose logs -f painter | grep -i -E "(image|upload|save|file)"

# Terminal 2 : Surveiller le dossier images
watch -n 2 "docker exec cardmanager-painter ls -la /app/images/"

# Terminal 3 : Tester l'upload
open http://localhost:8080
EOF

echo ""
print_info "💡 Pour un diagnostic en temps réel :"
echo "1. Ouvrez 2-3 terminaux"
echo "2. Lancez la surveillance des logs et du dossier"
echo "3. Uploadez une image"
echo "4. Observez ce qui se passe"

echo ""
print_success "Diagnostic terminé - Prêt pour le test d'upload"