#!/bin/bash

# CardManager - Script de diagnostic complet
# Version: 2.0.0
# Auteur: CardManager Team

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Fonctions utilitaires
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║ $1${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "\n${BLUE}🔍 $1${NC}"
    echo "================================================================"
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
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Fonction d'informations système
system_info() {
    print_section "INFORMATIONS SYSTÈME"

    echo "Date du diagnostic : $TIMESTAMP"
    echo "Système d'exploitation : $(uname -s)"
    echo "Architecture : $(uname -m)"

    if command -v lsb_release &> /dev/null; then
        echo "Distribution : $(lsb_release -d -s)"
    elif [[ -f /etc/os-release ]]; then
        echo "Distribution : $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    fi

    echo "Utilisateur : $(whoami)"
    echo "Répertoire de travail : $(pwd)"
    echo "Répertoire du projet : $PROJECT_DIR"
}

# Fonction de vérification Docker
check_docker() {
    print_section "VÉRIFICATION DOCKER"

    # Version Docker
    if command -v docker &> /dev/null; then
        print_success "Docker installé : $(docker --version)"

        # Test de fonctionnement
        if docker info &> /dev/null; then
            print_success "Docker daemon opérationnel"

            # Informations Docker
            echo "Version Docker Engine : $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'N/A')"
            echo "Espace disque Docker :"
            docker system df 2>/dev/null || echo "  Impossible de récupérer les informations d'espace"

        else
            print_error "Docker daemon non accessible"
            print_info "Démarrez Docker Desktop ou le service Docker"
        fi
    else
        print_error "Docker non installé"
        print_info "Installez Docker Desktop depuis https://docker.com"
    fi

    # Version Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose installé : $(docker-compose --version)"
    else
        print_error "Docker Compose non installé"
    fi
}

# Fonction de vérification de la configuration
check_configuration() {
    print_section "VÉRIFICATION CONFIGURATION"

    # Fichiers de configuration
    local files=("docker-compose.yml" ".env" "nginx-images.conf")

    for file in "${files[@]}"; do
        if [[ -f "$PROJECT_DIR/$file" ]]; then
            print_success "Fichier $file présent"
        else
            print_error "Fichier $file manquant"
        fi
    done

    # Configuration SSH Bitbucket
    if [[ -d "$PROJECT_DIR/docker/ssh-keys" ]]; then
        if [[ -f "$PROJECT_DIR/docker/ssh-keys/bitbucket_ed25519" ]]; then
            print_success "Clés SSH Bitbucket configurées"
        else
            print_warning "Clés SSH Bitbucket manquantes"
        fi
    else
        print_warning "Dossier ssh-keys non trouvé"
    fi

    # Variables d'environnement
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        echo ""
        echo "Variables d'environnement principales :"
        grep -E "^(MASON_|PAINTER_|GESTION|DB_|MYSQL_)" "$PROJECT_DIR/.env" | head -10 || echo "Aucune variable trouvée"
    fi
}

# Fonction de vérification des ports
check_ports() {
    print_section "VÉRIFICATION PORTS"

    local ports=("8080:Application" "8081:Painter" "8082:Images" "3308:MariaDB")

    for port_info in "${ports[@]}"; do
        local port=$(echo $port_info | cut -d: -f1)
        local service=$(echo $port_info | cut -d: -f2)

        if command -v lsof &> /dev/null; then
            if lsof -i :$port &> /dev/null; then
                local process=$(lsof -i :$port | tail -1 | awk '{print $1, $2}')
                print_warning "Port $port ($service) occupé par : $process"
            else
                print_success "Port $port ($service) libre"
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -an 2>/dev/null | grep -q ":$port "; then
                print_warning "Port $port ($service) probablement occupé"
            else
                print_success "Port $port ($service) libre"
            fi
        else
            print_info "Port $port ($service) - impossible de vérifier (lsof/netstat manquants)"
        fi
    done
}

# Fonction de vérification des services Docker
check_services() {
    print_section "ÉTAT DES SERVICES DOCKER"

    cd "$PROJECT_DIR" || return 1

    if [[ -f "docker-compose.yml" ]] && command -v docker-compose &> /dev/null; then
        echo "État des conteneurs :"
        docker-compose ps 2>/dev/null || echo "Impossible de récupérer l'état des services"

        echo ""
        echo "Images Docker :"
        docker images | grep -E "(cardmanager|mariadb|nginx)" || echo "Aucune image CardManager trouvée"

        echo ""
        echo "Volumes Docker :"
        docker volume ls | grep cardmanager || echo "Aucun volume CardManager trouvé"

        echo ""
        echo "Réseaux Docker :"
        docker network ls | grep cardmanager || echo "Aucun réseau CardManager trouvé"
    else
        print_warning "Impossible de vérifier les services (docker-compose.yml manquant ou Docker Compose non disponible)"
    fi
}

# Fonction de test des endpoints
test_endpoints() {
    print_section "TEST DES ENDPOINTS"

    local endpoints=(
        "http://localhost:8080:Application principale"
        "http://localhost:8081:API Painter"
        "http://localhost:8081/actuator/health:Health check Painter"
        "http://localhost:8082:Serveur d'images"
    )

    for endpoint_info in "${endpoints[@]}"; do
        local url=$(echo $endpoint_info | cut -d: -f1-2)
        local description=$(echo $endpoint_info | cut -d: -f3)

        if command -v curl &> /dev/null; then
            local status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)

            case $status_code in
                200|201|202)
                    print_success "$description : OK (HTTP $status_code)"
                    ;;
                302|404)
                    print_success "$description : Service répond (HTTP $status_code)"
                    ;;
                000)
                    print_error "$description : Service inaccessible"
                    ;;
                *)
                    print_warning "$description : Réponse inattendue (HTTP $status_code)"
                    ;;
            esac
        else
            print_info "$description : Impossible de tester (curl manquant)"
        fi
    done
}

# Fonction de test de la base de données
test_database() {
    print_section "TEST BASE DE DONNÉES"

    # Test de connexion MariaDB
    if docker ps --format "table {{.Names}}" | grep -q "cardmanager-mariadb"; then
        print_success "Conteneur MariaDB en cours d'exécution"

        # Test de connexion
        if docker exec cardmanager-mariadb mariadb -u ia -pfoufafou -e "SELECT 1 as test;" dev &> /dev/null; then
            print_success "Connexion base de données : OK"

            # Informations sur la base
            echo ""
            echo "Informations base de données :"
            docker exec cardmanager-mariadb mariadb -u ia -pfoufafou -e "
                SELECT @@version as 'Version MariaDB';
                SELECT COUNT(*) as 'Nombre de tables' FROM information_schema.tables WHERE table_schema='dev';
            " dev 2>/dev/null || echo "Impossible de récupérer les informations de la base"

        else
            print_error "Impossible de se connecter à la base de données"
        fi
    else
        print_error "Conteneur MariaDB non trouvé ou arrêté"
    fi
}

# Fonction de test de communication inter-services
test_communication() {
    print_section "TEST COMMUNICATION INTER-SERVICES"

    if docker ps --format "table {{.Names}}" | grep -q "cardmanager-gestioncarte"; then
        # Test communication GestionCarte → Painter
        echo "Test GestionCarte → Painter :"
        if docker exec cardmanager-gestioncarte wget -qO- --timeout=5 "http://painter:8081/actuator/health" 2>/dev/null | grep -q "UP\|status"; then
            print_success "Communication GestionCarte → Painter : OK"
        else
            print_error "Communication GestionCarte → Painter : ÉCHEC"
        fi

        # Variables d'environnement Painter dans GestionCarte
        echo ""
        echo "Variables Painter dans GestionCarte :"
        docker exec cardmanager-gestioncarte env | grep -i painter | head -5 || echo "Aucune variable Painter trouvée"

    else
        print_warning "Conteneur GestionCarte non disponible pour les tests"
    fi
}

# Fonction d'analyse des logs
analyze_logs() {
    print_section "ANALYSE DES LOGS"

    cd "$PROJECT_DIR" || return 1

    local services=("mariadb-standalone" "painter" "gestioncarte" "nginx-images")

    for service in "${services[@]}"; do
        echo ""
        echo "📋 Logs récents $service :"
        echo "----------------------------------------"

        if docker-compose logs --tail=5 "$service" 2>/dev/null; then
            # Recherche d'erreurs
            local errors=$(docker-compose logs --tail=20 "$service" 2>/dev/null | grep -i -E "(error|exception|failed|refused)" | wc -l)
            if [[ $errors -gt 0 ]]; then
                print_warning "$service : $errors erreur(s) détectée(s) dans les logs récents"
            else
                print_success "$service : Aucune erreur détectée dans les logs récents"
            fi
        else
            print_warning "Impossible de récupérer les logs de $service"
        fi
    done
}

# Fonction de recommandations
show_recommendations() {
    print_section "RECOMMANDATIONS"

    local issues=0

    # Vérifications système
    if ! command -v docker &> /dev/null; then
        print_error "Installez Docker Desktop"
        ((issues++))
    fi

    if ! docker info &> /dev/null; then
        print_error "Démarrez Docker Desktop"
        ((issues++))
    fi

    # Vérifications configuration
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        print_error "Créez le fichier .env à partir de .env.template"
        ((issues++))
    fi

    if [[ ! -f "$PROJECT_DIR/docker/ssh-keys/bitbucket_ed25519" ]]; then
        print_warning "Configurez les clés SSH Bitbucket (voir guide de déploiement)"
        ((issues++))
    fi

    # Vérifications services
    if ! curl -s --connect-timeout 3 http://localhost:8080 >/dev/null 2>&1; then
        print_warning "Application principale non accessible - Démarrez avec: ./scripts/start.sh"
        ((issues++))
    fi

    # Résumé
    echo ""
    if [[ $issues -eq 0 ]]; then
        print_success "Aucun problème majeur détecté !"
        echo ""
        echo "🎉 CardManager semble correctement configuré et opérationnel"
    else
        print_warning "$issues problème(s) détecté(s)"
        echo ""
        echo "📚 Consultez la documentation :"
        echo "  • Guide de