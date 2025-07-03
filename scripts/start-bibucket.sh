#!/bin/bash

# =============================================================================
# CardManager - Script de démarrage pour dépôts Bitbucket
# =============================================================================
# Version: 2.0.0
# Auteur: Équipe CardManager
# Description: Script optimisé pour le déploiement avec authentification SSH
# =============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}$1${NC}"
    echo "$(printf '%*s' ${#1} '' | tr ' ' '=')"
}

# En-tête du script
echo
print_header "🚀 DÉMARRAGE CARDMANAGER - VERSION BITBUCKET"
echo "Version: 2.0.0"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# Vérification des prérequis
print_status "🔍 Vérification des prérequis..."

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker n'est pas installé"
    print_error "💡 Installez Docker Desktop depuis https://www.docker.com/"
    exit 1
fi

# Vérifier Docker Compose
if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
    print_error "Docker Compose n'est pas disponible"
    print_error "💡 Installez Docker Compose ou utilisez Docker Desktop"
    exit 1
fi

print_success "Docker détecté - $(docker --version | cut -d' ' -f3 | tr -d ',')"

# Vérifier et activer Docker BuildKit
print_status "🔧 Configuration de Docker BuildKit..."
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
print_success "Docker BuildKit activé"

# Vérifier la connectivité SSH vers Bitbucket
print_status "🔐 Vérification de la connectivité SSH vers Bitbucket..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>/dev/null | grep -q "authenticated via ssh"; then
    print_success "Connexion SSH vers Bitbucket OK"
elif ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@bitbucket.org 2>&1 | grep -q "authenticated via ssh"; then
    print_success "Connexion SSH vers Bitbucket OK"
else
    print_warning "⚠️  Connexion SSH vers Bitbucket non vérifiée"
    print_warning "   Assurez-vous que votre clé SSH est configurée pour Bitbucket"
    print_warning "   Test manuel : ssh -T git@bitbucket.org"

    echo
    print_warning "🔑 Guide de configuration SSH rapide :"
    print_warning "   1. ssh-keygen -t ed25519 -C \"votre.email@example.com\""
    print_warning "   2. cat ~/.ssh/id_ed25519.pub  # Copier cette clé"
    print_warning "   3. Ajouter dans Bitbucket → Settings → SSH keys"
    print_warning "   4. ssh -T git@bitbucket.org  # Tester"
    echo

    read -p "Continuer malgré tout ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Arrêt du script - Configurez d'abord l'accès SSH"
        exit 1
    fi
fi

# Créer ou vérifier le fichier .env
print_status "📝 Configuration de l'environnement..."
if [ ! -f ".env" ]; then
    print_warning "Fichier .env non trouvé"
    print_status "Création du fichier .env avec les valeurs par défaut..."

    cat > .env << 'EOF'
# =============================================================================
# Configuration CardManager pour Bitbucket
# =============================================================================

# Dépôts Bitbucket (SSH)
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# Branches de développement
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# Base de données locale (MariaDB sur l'hôte)
LOCAL_DB_HOST=host.docker.internal
LOCAL_DB_PORT=3306
LOCAL_DB_NAME=dev
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou

# Configuration Docker
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1

# Ports d'exposition
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
MARIADB_PORT=3307

# Variables Maven
MAVEN_OPTS=-Xmx2g -XX:+UseG1GC
EOF

    print_success "Fichier .env créé avec les valeurs par défaut"
    print_warning "⚠️  Vérifiez et adaptez le fichier .env si nécessaire"
else
    print_success "Fichier .env trouvé"
fi

# Charger les variables d'environnement
source .env

# Vérifier SSH Agent (pour l'authentification)
print_status "🔑 Vérification de SSH Agent..."
if [ -z "$SSH_AUTH_SOCK" ]; then
    print_warning "SSH Agent n'est pas actif"
    print_status "Tentative de démarrage de SSH Agent..."

    if command -v ssh-agent &> /dev/null; then
        eval "$(ssh-agent -s)"

        # Ajouter la clé SSH par défaut
        if [ -f "$HOME/.ssh/id_rsa" ]; then
            ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null && print_success "Clé SSH RSA ajoutée"
        elif [ -f "$HOME/.ssh/id_ed25519" ]; then
            ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null && print_success "Clé SSH Ed25519 ajoutée"
        else
            print_warning "Aucune clé SSH trouvée dans ~/.ssh/"
            print_warning "Générez une clé : ssh-keygen -t ed25519 -C \"votre.email@domain.com\""
        fi
    fi
else
    print_success "SSH Agent actif"
    print_status "Clés SSH chargées :"
    ssh-add -l 2>/dev/null || print_warning "Aucune clé dans l'agent SSH"
fi

# Créer les répertoires nécessaires
print_status "📁 Préparation des répertoires..."
mkdir -p init-db
mkdir -p docker/nginx
mkdir -p images
mkdir -p logs

# Créer un fichier nginx.conf minimal s'il n'existe pas
if [ ! -f "docker/nginx/nginx.conf" ]; then
    print_status "📄 Création de la configuration Nginx..."
    cat > docker/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Configuration pour les gros fichiers
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript image/svg+xml;

    server {
        listen 80;
        server_name localhost;

        # Page d'accueil
        location / {
            root /usr/share/nginx/html;
            index index.html;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
        }

        # Serveur d'images uploadées
        location /images/ {
            alias /usr/share/nginx/html/images/;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;

            # Headers pour le cache
            expires 1d;
            add_header Cache-Control "public, immutable";
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
    print_success "Configuration Nginx créée"
fi

# Créer une page d'accueil pour Nginx
if [ ! -f "docker/nginx/index.html" ]; then
    cat > docker/nginx/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CardManager - Serveur d'Images</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .status { padding: 15px; background: #d4edda; border: 1px solid #c3e6cb; border-radius: 4px; margin: 20px 0; }
        .links { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin: 20px 0; }
        .link-card { padding: 20px; background: #ecf0f1; border-radius: 6px; text-align: center; text-decoration: none; color: #2c3e50; transition: transform 0.2s; }
        .link-card:hover { transform: translateY(-2px); background: #d5dbdb; }
        .link-card h3 { margin: 0 0 10px 0; color: #3498db; }
        .footer { margin-top: 30px; text-align: center; color: #7f8c8d; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🃏 CardManager - Serveur d'Images</h1>

        <div class="status">
            <strong>✅ Serveur Nginx actif</strong> - Les images uploadées sont accessibles via ce serveur
        </div>

        <div class="links">
            <a href="/images/" class="link-card">
                <h3>📁 Galerie d'Images</h3>
                <p>Parcourir les images uploadées</p>
            </a>

            <a href="http://localhost:8080" class="link-card">
                <h3>🎯 Application Principale</h3>
                <p>Interface CardManager</p>
            </a>

            <a href="http://localhost:8081" class="link-card">
                <h3>🎨 Service Painter</h3>
                <p>API de traitement d'images</p>
            </a>

            <a href="/health" class="link-card">
                <h3>💚 Health Check</h3>
                <p>Statut du serveur</p>
            </a>
        </div>

        <div class="footer">
            <p>CardManager v2.0.0 - Serveur d'images basé sur Nginx</p>
            <p>Port 8082 - Configuration automatique via Docker Compose</p>
        </div>
    </div>
</body>
</html>
EOF
fi

# Créer les volumes Docker s'ils n'existent pas
print_status "📦 Préparation des volumes Docker..."
docker volume create cardmanager_db_data 2>/dev/null || true
docker volume create cardmanager_images 2>/dev/null || true
docker volume create maven_cache 2>/dev/null || true

print_success "Volumes Docker créés/vérifiés"

# Proposer un nettoyage (optionnel)
echo
read -p "🧹 Voulez-vous nettoyer les images Docker existantes ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Nettoyage des images Docker..."
    docker-compose down --remove-orphans 2>/dev/null || true
    docker system prune -f
    print_success "Nettoyage terminé"
fi

# Construction et démarrage
echo
print_header "🔨 CONSTRUCTION DES IMAGES DOCKER"
print_warning "⏳ Premier build : 10-15 minutes (les suivants seront plus rapides)"
print_status "📡 Clonage depuis Bitbucket avec authentification SSH..."

# Vérifier si docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_error "Fichier docker-compose.yml non trouvé !"
    print_error "Assurez-vous d'être dans le bon répertoire"
    exit 1
fi

# Construire avec SSH forwarding
print_status "🏗️  Construction des images avec SSH forwarding..."
if DOCKER_BUILDKIT=1 docker-compose build --ssh default; then
    print_success "✅ Construction des images réussie"
else
    print_error "❌ Échec de la construction des images"
    echo
    print_error "🔍 Points à vérifier :"
    print_error "  1. Connectivité SSH vers Bitbucket : ssh -T git@bitbucket.org"
    print_error "  2. URLs des dépôts dans le fichier .env"
    print_error "  3. Branches existantes sur Bitbucket"
    print_error "  4. Logs détaillés : docker-compose build --no-cache --progress=plain"
    echo
    print_status "🔧 Exécutez './diagnostic-bitbucket.sh' pour un diagnostic complet"
    exit 1
fi

# Démarrage des services
echo
print_header "🚀 DÉMARRAGE DES SERVICES"
print_status "Démarrage de tous les services..."

if docker-compose up -d; then
    print_success "✅ Services démarrés avec succès"
else
    print_error "❌ Échec du démarrage des services"
    print_status "Vérification des logs..."
    docker-compose logs --tail=10
    exit 1
fi

# Attendre que les services soient prêts
echo
print_status "⏳ Attente du démarrage complet des services..."
sleep 5

# Vérification de la santé des services
print_header "🏥 VÉRIFICATION DE LA SANTÉ DES SERVICES"

services_ok=0
total_services=4

# Test de chaque service
echo "Service                    | Status        | URL"
echo "---------------------------|---------------|---------------------------"

# GestionCarte (application principale)
if curl -s --max-time 10 http://localhost:8080/actuator/health >/dev/null 2>&1; then
    echo "✅ GestionCarte           | Running       | http://localhost:8080"
    services_ok=$((services_ok + 1))
else
    echo "❌ GestionCarte           | Not Ready     | http://localhost:8080"
fi

# Painter (service de traitement)
if curl -s --max-time 10 http://localhost:8081/actuator/health >/dev/null 2>&1; then
    echo "✅ Painter                | Running       | http://localhost:8081"
    services_ok=$((services_ok + 1))
else
    echo "❌ Painter                | Not Ready     | http://localhost:8081"
fi

# Nginx (serveur d'images)
if curl -s --max-time 5 http://localhost:8082/health >/dev/null 2>&1; then
    echo "✅ Nginx Images           | Running       | http://localhost:8082"
    services_ok=$((services_ok + 1))
else
    echo "❌ Nginx Images           | Not Ready     | http://localhost:8082"
fi

# MariaDB
if docker-compose exec -T mariadb-standalone mysqladmin ping -h localhost -u"$LOCAL_DB_USER" -p"$LOCAL_DB_PASS" >/dev/null 2>&1; then
    echo "✅ MariaDB                | Running       | localhost:3307"
    services_ok=$((services_ok + 1))
else
    echo "❌ MariaDB                | Not Ready     | localhost:3307"
fi

echo

# Résultat final
if [ $services_ok -eq $total_services ]; then
    print_success "🎉 DÉMARRAGE RÉUSSI ! Tous les services sont opérationnels"
else
    print_warning "⚠️  $services_ok/$total_services services démarrés"
    print_warning "Attendez quelques minutes ou consultez les logs : docker-compose logs"
fi

# Affichage des informations finales
echo
print_header "🎯 ACCÈS AUX SERVICES"
echo "🌐 Application Principale    : http://localhost:8080"
echo "🎨 Service Painter           : http://localhost:8081"
echo "📁 Serveur d'Images          : http://localhost:8082"
echo "🗄️  Base de Données          : localhost:3307"
echo "💚 Health Checks            : http://localhost:8080/actuator/health"

echo
print_header "📋 COMMANDES UTILES"
echo "📊 État des services        : docker-compose ps"
echo "📄 Logs en temps réel       : docker-compose logs -f"
echo "🔄 Redémarrer               : docker-compose restart"
echo "⏹️  Arrêter                 : docker-compose down"
echo "🔍 Diagnostic complet       : ./diagnostic-bitbucket.sh"
echo "🧹 Nettoyer                : docker system prune -f"

echo
print_header "📚 DÉVELOPPEMENT"
echo "• Modifier une branche      : Éditez .env puis docker-compose build --no-cache [service]"
echo "• Base de données locale    : Configurez LOCAL_DB_HOST=host.docker.internal dans .env"
echo "• Hot reload               : Montez le code source en volume dans docker-compose.yml"

echo
if [ $services_ok -eq $total_services ]; then
    print_success "🎊 CardManager est prêt ! Ouvrez http://localhost:8080 pour commencer"
else
    print_warning "⏳ Patientez quelques minutes pour que tous les services démarrent"
    print_warning "🔧 En cas de problème, exécutez : ./diagnostic-bitbucket.sh"
fi

echo
print_status "🔚 Script terminé - $(date '+%H:%M:%S')"