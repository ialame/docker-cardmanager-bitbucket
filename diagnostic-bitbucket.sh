#!/bin/bash

# =============================================================================
# Script de diagnostic CardManager - Version Bitbucket
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}$1${NC}"
    echo "$(printf '%*s' ${#1} '' | tr ' ' '=')"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

test_connectivity() {
    local url=$1
    local name=$2

    if curl -s --max-time 10 "$url" >/dev/null 2>&1; then
        print_success "$name accessible"
        return 0
    else
        print_error "$name non accessible"
        return 1
    fi
}

# En-tête
echo
print_header "🔍 DIAGNOSTIC CARDMANAGER - BITBUCKET"
echo "Date: $(date)"
echo "Utilisateur: $(whoami)"
echo

# 1. ENVIRONNEMENT SYSTÈME
print_header "1. ENVIRONNEMENT SYSTÈME"

print_info "Version Docker:"
if command -v docker &> /dev/null; then
    docker --version
    print_success "Docker installé"
else
    print_error "Docker non installé"
fi

print_info "Version Docker Compose:"
if docker compose version &> /dev/null; then
    docker compose version
    print_success "Docker Compose v2 disponible"
elif docker-compose --version &> /dev/null; then
    docker-compose --version
    print_success "Docker Compose v1 disponible"
else
    print_error "Docker Compose non disponible"
fi

print_info "Espace disque Docker:"
docker system df 2>/dev/null || print_warning "Impossible de vérifier l'espace Docker"

echo

# 2. CONFIGURATION SSH
print_header "2. CONFIGURATION SSH"

print_info "SSH Agent:"
if [ -n "$SSH_AUTH_SOCK" ]; then
    print_success "SSH Agent actif"
    print_info "Clés chargées:"
    ssh-add -l 2>/dev/null || print_warning "Aucune clé dans l'agent SSH"
else
    print_warning "SSH Agent non actif"
fi

print_info "Test de connexion Bitbucket:"
if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>&1 | grep -q "authenticated via ssh"; then
    print_success "Connexion SSH vers Bitbucket OK"
elif ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>&1 | grep -q "Permission denied"; then
    print_error "Connexion SSH vers Bitbucket échouée - Vérifiez vos clés SSH"
else
    print_warning "Connexion SSH vers Bitbucket incertaine"
fi

print_info "Clés SSH disponibles:"
if [ -d "$HOME/.ssh" ]; then
    ls -la "$HOME/.ssh"/*.pub 2>/dev/null || print_warning "Aucune clé publique trouvée"
else
    print_warning "Dossier ~/.ssh non trouvé"
fi

echo

# 3. CONFIGURATION PROJET
print_header "3. CONFIGURATION PROJET"

print_info "Fichier .env:"
if [ -f ".env" ]; then
    print_success "Fichier .env présent"
    echo "Contenu (sans les mots de passe):"
    grep -v "PASS\|PASSWORD\|TOKEN" .env | head -10
else
    print_error "Fichier .env manquant"
fi

print_info "Répertoires nécessaires:"
for dir in "docker" "docker/nginx" "init-db"; do
    if [ -d "$dir" ]; then
        print_success "$dir existe"
    else
        print_warning "$dir manquant"
    fi
done

print_info "Variables d'environnement Docker:"
echo "DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-non défini}"
echo "COMPOSE_DOCKER_CLI_BUILD=${COMPOSE_DOCKER_CLI_BUILD:-non défini}"

echo

# 4. SERVICES DOCKER
print_header "4. SERVICES DOCKER"

print_info "État des services Docker Compose:"
if docker-compose ps 2>/dev/null; then
    print_success "Services Docker Compose trouvés"
else
    print_warning "Aucun service Docker Compose en cours"
fi

print_info "Images Docker CardManager:"
docker images | grep -E "(cardmanager|mason|painter|gestioncarte)" || print_warning "Aucune image CardManager trouvée"

print_info "Volumes Docker:"
docker volume ls | grep cardmanager || print_warning "Aucun volume CardManager trouvé"

print_info "Réseaux Docker:"
docker network ls | grep cardmanager || print_warning "Aucun réseau CardManager trouvé"

echo

# 5. CONNECTIVITÉ SERVICES
print_header "5. CONNECTIVITÉ SERVICES"

print_info "Test des endpoints de service:"

# Test GestionCarte
test_connectivity "http://localhost:8080/actuator/health" "GestionCarte (port 8080)"

# Test Painter
test_connectivity "http://localhost:8081/actuator/health" "Painter (port 8081)"

# Test Nginx
test_connectivity "http://localhost:8082/" "Nginx Images (port 8082)"

# Test base de données
print_info "Test base de données:"
if docker-compose exec -T mariadb-standalone mysqladmin ping -h localhost -u ia -pfoufafou 2>/dev/null; then
    print_success "Base de données accessible"
else
    print_error "Base de données non accessible"
fi

echo

# 6. LOGS DES SERVICES
print_header "6. LOGS DES SERVICES (dernières lignes)"

for service in gestioncarte painter mariadb-standalone nginx-images; do
    print_info "Logs $service:"
    if docker-compose logs --tail=3 "$service" 2>/dev/null; then
        echo
    else
        print_warning "Impossible de récupérer les logs de $service"
    fi
done

echo

# 7. RESSOURCES SYSTÈME
print_header "7. RESSOURCES SYSTÈME"

print_info "Utilisation mémoire Docker:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || print_warning "Impossible de récupérer les stats Docker"

print_info "Ports utilisés:"
if command -v netstat &> /dev/null; then
    netstat -tulpn 2>/dev/null | grep -E ":(8080|8081|8082|3307)" || print_info "Aucun port CardManager en écoute"
elif command -v ss &> /dev/null; then
    ss -tulpn 2>/dev/null | grep -E ":(8080|8081|8082|3307)" || print_info "Aucun port CardManager en écoute"
else
    print_warning "Impossible de vérifier les ports (netstat/ss non disponible)"
fi

echo

# 8. RECOMMANDATIONS
print_header "8. RECOMMANDATIONS"

# Vérifications et recommandations
issues_found=0

if ! command -v docker &> /dev/null; then
    print_error "Docker non installé - Installez Docker Desktop"
    issues_found=$((issues_found + 1))
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
    print_warning "SSH Agent non actif - Exécutez: eval \$(ssh-agent -s) && ssh-add"
    issues_found=$((issues_found + 1))
fi

if [ ! -f ".env" ]; then
    print_error "Fichier .env manquant - Copiez .env.template vers .env"
    issues_found=$((issues_found + 1))
fi

if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>&1 | grep -q "authenticated"; then
    print_warning "Configurer l'accès SSH à Bitbucket - Ajoutez votre clé publique"
    issues_found=$((issues_found + 1))
fi

if ! curl -s --max-time 5 http://localhost:8080/actuator/health >/dev/null 2>&1; then
    print_warning "Application principale non accessible - Vérifiez les logs: docker-compose logs gestioncarte"
    issues_found=$((issues_found + 1))
fi

if [ $issues_found -eq 0 ]; then
    print_success "Aucun problème majeur détecté !"
else
    print_warning "$issues_found problème(s) détecté(s) - Voir les recommandations ci-dessus"
fi

echo
print_header "COMMANDES UTILES"
echo "🚀 Démarrer:           ./start-bitbucket.sh"
echo "⏹️  Arrêter:            docker-compose down"
echo "🔄 Redémarrer:         docker-compose restart"
echo "📋 État services:      docker-compose ps"
echo "📄 Logs temps réel:    docker-compose logs -f"
echo "🔧 Logs service:       docker-compose logs -f [service]"
echo "🧹 Nettoyer:          docker system prune -f"
echo "💾 Sauvegarder DB:    docker-compose exec mariadb-standalone mysqldump -u ia -pfoufafou dev > backup.sql"

echo
print_success "Diagnostic terminé"
echo "📋 Pour signaler un problème, copiez ce diagnostic complet"