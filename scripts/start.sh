#!/bin/bash

# CardManager - Script de démarrage
# Version: 2.0.0
# Auteur: CardManager Team

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Fonction de vérification des prérequis
check_prerequisites() {
    log_header "🔍 Vérification des prérequis..."

    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        log_info "Installez Docker Desktop depuis https://docker.com"
        exit 1
    fi

    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé"
        log_info "Docker Compose est inclus avec Docker Desktop"
        exit 1
    fi

    # Vérifier que Docker fonctionne
    if ! docker info &> /dev/null; then
        log_error "Docker n'est pas démarré"
        log_info "Démarrez Docker Desktop et réessayez"
        exit 1
    fi

    log_success "Docker et Docker Compose sont disponibles"
}

# Fonction de vérification de la configuration
check_configuration() {
    log_header "⚙️  Vérification de la configuration..."

    # Vérifier le fichier docker-compose.yml
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Fichier docker-compose.yml non trouvé dans $PROJECT_DIR"
        exit 1
    fi

    # Vérifier le fichier .env
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning "Fichier .env non trouvé"

        if [[ -f "$PROJECT_DIR/.env.template" ]]; then
            log_info "Copie de .env.template vers .env..."
            cp "$PROJECT_DIR/.env.template" "$ENV_FILE"
            log_success "Fichier .env créé à partir du template"
        else
            log_error "Fichier .env.template non trouvé"
            exit 1
        fi
    fi

    # Vérifier les clés SSH pour Bitbucket
    if [[ ! -d "$PROJECT_DIR/docker/ssh-keys" ]] || [[ ! -f "$PROJECT_DIR/docker/ssh-keys/bitbucket_ed25519" ]]; then
        log_warning "Clés SSH Bitbucket non configurées"
        log_info "Consultez le guide de déploiement pour configurer l'accès Bitbucket"
        log_info "Guide: docs/FR/DEPLOIEMENT-FR.md#configuration-bitbucket"

        read -p "Voulez-vous continuer sans les clés SSH ? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Configuration des clés SSH annulée"
            exit 1
        fi
    fi

    log_success "Configuration vérifiée"
}

# Fonction de vérification des ports
check_ports() {
    log_header "🔌 Vérification des ports..."

    local ports=("8080" "8081" "8082" "3308")
    local occupied_ports=()

    for port in "${ports[@]}"; do
        if lsof -i :$port &> /dev/null || netstat -an 2>/dev/null | grep -q ":$port "; then
            occupied_ports+=($port)
        fi
    done

    if [[ ${#occupied_ports[@]} -gt 0 ]]; then
        log_warning "Ports occupés: ${occupied_ports[*]}"
        log_info "Les services Docker utiliseront ces ports. Assurez-vous qu'ils sont libres."

        read -p "Voulez-vous continuer ? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Démarrage annulé"
            log_info "Libérez les ports ou modifiez la configuration dans docker-compose.yml"
            exit 1
        fi
    else
        log_success "Tous les ports sont disponibles"
    fi
}

# Fonction de construction et démarrage
start_services() {
    log_header "🚀 Démarrage de CardManager..."

    cd "$PROJECT_DIR" || exit 1

    # Arrêter les services existants
    log_info "Arrêt des services existants..."
    docker-compose down --remove-orphans &> /dev/null

    # Construction des images (premier démarrage ou --build)
    if [[ "$1" == "--build" ]] || ! docker images | grep -q "cardmanager"; then
        log_info "Construction des images Docker (cela peut prendre 15-20 minutes au premier démarrage)..."

        if docker-compose build --parallel; then
            log_success "Images construites avec succès"
        else
            log_error "Échec de la construction des images"
            log_info "Vérifiez les logs ci-dessus et la configuration Bitbucket"
            exit 1
        fi
    fi

    # Démarrage des services
    log_info "Démarrage des services..."

    if docker-compose up -d; then
        log_success "Services démarrés"
    else
        log_error "Échec du démarrage des services"
        exit 1
    fi
}

# Fonction de vérification du démarrage
verify_startup() {
    log_header "🔍 Vérification du démarrage..."

    local max_attempts=30
    local attempt=1

    log_info "Attente du démarrage des services (jusqu'à 5 minutes)..."

    while [[ $attempt -le $max_attempts ]]; do
        local healthy_services=0

        # Vérifier chaque service
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302\|404"; then
            ((healthy_services++))
        fi

        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/health | grep -q "200"; then
            ((healthy_services++))
        fi

        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082 | grep -q "200\|403"; then
            ((healthy_services++))
        fi

        # Vérifier MariaDB
        if docker exec cardmanager-mariadb mariadb -u ia -pfoufafou -e "SELECT 1;" dev &> /dev/null; then
            ((healthy_services++))
        fi

        if [[ $healthy_services -eq 4 ]]; then
            log_success "Tous les services sont opérationnels !"
            break
        fi

        echo -n "."
        sleep 10
        ((attempt++))
    done

    echo "" # Nouvelle ligne après les points

    if [[ $attempt -gt $max_attempts ]]; then
        log_warning "Délai d'attente dépassé, mais les services peuvent encore démarrer"
        log_info "Vérifiez manuellement avec: docker-compose ps"
    fi
}

# Fonction d'affichage des informations finales
show_final_info() {
    log_header "🎉 CardManager est démarré !"

    echo ""
    echo -e "${GREEN}📱 URLs d'accès :${NC}"
    echo "  • Application CardManager : http://localhost:8080"
    echo "  • API Painter            : http://localhost:8081"
    echo "  • Serveur d'images       : http://localhost:8082"
    echo ""

    echo -e "${BLUE}🔧 Commandes utiles :${NC}"
    echo "  • État des services      : docker-compose ps"
    echo "  • Logs en temps réel     : docker-compose logs -f"
    echo "  • Arrêter               : ./scripts/stop.sh"
    echo "  • Diagnostic            : ./scripts/diagnostic.sh"
    echo "  • Sauvegarde            : ./scripts/backup.sh"
    echo ""

    echo -e "${YELLOW}📚 Documentation :${NC}"
    echo "  • Guide complet         : docs/FR/DEPLOIEMENT-FR.md"
    echo "  • FAQ                   : docs/FR/FAQ-FR.md"
    echo "  • Support               : GitHub Issues"
    echo ""

    # Vérifier l'état final
    echo -e "${BLUE}📊 État final des services :${NC}"
    docker-compose ps
}

# Fonction principale
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🃏 CardManager v2.0                      ║"
    echo "║              Démarrage automatique des services              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Exécuter les vérifications et le démarrage
    check_prerequisites
    check_configuration
    check_ports
    start_services "$1"
    verify_startup
    show_final_info

    log_success "CardManager est prêt à l'emploi !"
}

# Gestion des paramètres
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--build] [--help]"
        echo ""
        echo "Options:"
        echo "  --build    Force la reconstruction des images Docker"
        echo "  --help     Affiche cette aide"
        echo ""
        exit 0
        ;;
    --build)
        main --build
        ;;
    "")
        main
        ;;
    *)
        log_error "Option inconnue: $1"
        echo "Utilisez --help pour voir les options disponibles"
        exit 1
        ;;
esac