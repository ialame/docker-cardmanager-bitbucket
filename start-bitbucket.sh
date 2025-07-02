#!/bin/bash

# =============================================================================
# Script de démarrage CardManager pour dépôts Bitbucket
# =============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleur
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# En-tête
echo "🚀 Démarrage de CardManager - Version Bitbucket"
echo "=================================================="

# Vérification des prérequis
print_status "Vérification des prérequis..."

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker n'est pas installé"
    print_error "💡 Installez Docker Desktop depuis https://www.docker.com/"
    exit 1
fi

# Vérifier Docker Compose
if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
    print_error "Docker Compose n'est pas disponible"
    exit 1
fi

print_success "Docker détecté - $(docker --version)"

# Vérifier Docker BuildKit
print_status "Activation de Docker BuildKit..."
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Vérifier la connectivité SSH vers Bitbucket
print_status "Vérification de la connectivité SSH vers Bitbucket..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>/dev/null | grep -q "authenticated via ssh"; then
    print_success "Connexion SSH vers Bitbucket OK"
elif ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>&1 | grep -q "authenticated via ssh"; then
    print_success "Connexion SSH vers Bitbucket OK"
else
    print_warning "⚠️  Connexion SSH vers Bitbucket non vérifiée"
    print_warning "   Assurez-vous que votre clé SSH est configurée pour Bitbucket"
    print_warning "   Test manuel : ssh -T git@bitbucket.org"

    read -p "Continuer malgré tout ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Arrêt du script"
        exit 1
    fi
fi

# Vérifier que le fichier .env existe
if [ ! -f ".env" ]; then
    print_warning "Fichier .env non trouvé"
    print_status "Création du fichier .env avec les valeurs par défaut..."

    cat > .env << 'EOF'
# Configuration CardManager pour Bitbucket
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

LOCAL_DB_HOST=localhost
LOCAL_DB_PORT=3306
LOCAL_DB_NAME=dev
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou

DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
EOF

    print_success "Fichier .env créé avec les valeurs par défaut"
    print_warning "⚠️  Vérifiez et adaptez le fichier .env si nécessaire"
fi

# Charger les variables d'environnement
source .env

# Vérifier SSH Agent (pour l'authentification)
print_status "Vérification de SSH Agent..."
if [ -z "$SSH_AUTH_SOCK" ]; then
    print_warning "SSH Agent n'est pas actif"
    print_status "Tentative de démarrage de SSH Agent..."

    if command -v ssh-agent &> /dev/null; then
        eval "$(ssh-agent -s)"

        # Ajouter la clé SSH par défaut
        if [ -f "$HOME/.ssh/id_rsa" ]; then
            ssh-add "$HOME/.ssh/id_rsa"
            print_success "Clé SSH ajoutée à l'agent"
        elif [ -f "$HOME/.ssh/id_ed25519" ]; then
            ssh-add "$HOME/.ssh/id_ed25519"
            print_success "Clé SSH ajoutée à l'agent"
        else
            print_warning "Aucune clé SSH trouvée dans ~/.ssh/"
        fi
    fi
else
    print_success "SSH Agent actif"
fi

# Créer les répertoires nécessaires
print_status "Préparation des répertoires..."
mkdir -p init-db
mkdir -p docker/nginx

# Créer un fichier nginx.conf minimal si il n'existe pas
if [ ! -f "docker/nginx/nginx.conf" ]; then
    print_status "Création de la configuration Nginx..."
    cat > docker/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
        }

        location /images/ {
            alias /usr/share/nginx/html/images/;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
        }
    }
}
EOF
fi

# Créer les volumes Docker s'ils n'existent pas
print_status "📦 Préparation des volumes Docker..."
docker volume create cardmanager_db_data 2>/dev/null || true
docker volume create cardmanager_images 2>/dev/null || true
docker volume create maven_cache 2>/dev/null || true

print_success "Volumes Docker créés"

# Nettoyage préalable (optionnel)
read -p "Voulez-vous nettoyer les images Docker existantes ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Nettoyage des images Docker..."
    docker-compose down --remove-orphans 2>/dev/null || true
    docker system prune -f
fi

# Construction et démarrage
print_status "🔨 Construction des images Docker avec SSH..."
print_warning "⏳ Cela peut prendre 10-15 minutes lors du premier build..."

# Construire avec SSH forwarding
if ! DOCKER_BUILDKIT=1 docker-compose build --ssh default; then
    print_error "Échec de la construction des images"
    print_error "Vérifiez:"
    print_error "  1. Votre connectivité SSH vers Bitbucket"
    print_error "  2. Les URLs des dépôts dans le fichier .env"
    print_error "  3. Les permissions sur les dépôts Bitbucket"
    exit 1
fi

print_success "Images construites avec succès"

# Démarrage des services
print_status "🚀 Démarrage des services..."
docker-compose up -d

# Attendre que les services soient prêts
print_status "⏳ Attente du démarrage des services..."

# Attendre la base de données
print_status "Attente de la base de données..."
timeout=60
while [ $timeout -gt 0 ]; do
    if docker-compose exec -T mariadb-standalone mysqladmin ping -h localhost -u ia -pfoufafou &>/dev/null; then
        print_success "Base de données prête"
        break
    fi
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -eq 0 ]; then
    print_warning "La base de données met du temps à démarrer"
fi

# Attendre les services applicatifs
sleep 10

# Vérification de l'état des services
print_status "📊 État des services:"
echo
docker-compose ps

# Tests de connectivité
print_status "🔍 Test de connectivité..."
echo

# Test application principale
if curl -s http://localhost:8080/actuator/health >/dev/null 2>&1; then
    print_success "✅ GestionCarte (http://localhost:8080) - OK"
else
    print_warning "⏳ GestionCarte (http://localhost:8080) - En cours de démarrage..."
fi

# Test Painter
if curl -s http://localhost:8081/actuator/health >/dev/null 2>&1; then
    print_success "✅ Painter (http://localhost:8081) - OK"
else
    print_warning "⏳ Painter (http://localhost:8081) - En cours de démarrage..."
fi

# Test serveur d'images
if curl -s http://localhost:8082/ >/dev/null 2>&1; then
    print_success "✅ Serveur d'images (http://localhost:8082) - OK"
else
    print_warning "⏳ Serveur d'images (http://localhost:8082) - En cours de démarrage..."
fi

echo
print_success "🎉 CardManager démarré avec succès !"
echo
echo "📱 URLs d'accès :"
echo "   • Application principale : http://localhost:8080"
echo "   • API Painter            : http://localhost:8081"
echo "   • Galerie d'images       : http://localhost:8082/images/"
echo "   • Base de données        : localhost:3307"
echo
echo "🔍 Commandes utiles :"
echo "   • Voir les logs          : docker-compose logs -f"
echo "   • Logs d'un service      : docker-compose logs -f gestioncarte"
echo "   • Arrêter               : docker-compose down"
echo "   • Redémarrer            : docker-compose restart"
echo "   • État des services     : docker-compose ps"
echo
echo "⚠️  Si les services mettent du temps à démarrer, c'est normal."
echo "   Attendez 2-3 minutes et vérifiez http://localhost:8080"
echo
print_success "Installation terminée ! 🚀"