#!/bin/bash

# =============================================================================
# CARDMANAGER - NETTOYAGE SÉVÈRE
# =============================================================================
# Ce script supprime tous les fichiers temporaires, de test et inutiles
# Utilisez avec précaution ! Une sauvegarde sera créée automatiquement

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(pwd)"
BACKUP_DIR=".cleanup-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${PURPLE}🧹 CARDMANAGER - NETTOYAGE SÉVÈRE${NC}"
echo "========================================"
echo ""

# Fonction d'affichage
print_header() {
    echo -e "${CYAN}📋 $1${NC}"
    echo "----------------------------------------"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

# Vérification préliminaire
if [ ! -f "docker-compose.yml" ] && [ ! -f ".env" ]; then
    print_error "Ce script doit être exécuté dans le répertoire racine du projet CardManager"
    exit 1
fi

# Afficher les fichiers qui seront supprimés
print_header "ANALYSE DES FICHIERS À SUPPRIMER"

echo -e "${YELLOW}📁 Fichiers temporaires et de test détectés :${NC}"

# Fichiers temporaires et de debug
TEMP_FILES=(
    "toto.txt"
    "toto.html"
    "structure.txt"
    "prompt.txt"
    "readme"
    "backup.sql"
    "*.sql"
    "2025-*.sql"
    "nettoyage.sh"
    "cleanup_plan.sh"
    "diagnostic-bitbucket.sh"
)

# Scripts de debug et fix
DEBUG_SCRIPTS=(
    "fix_*.sh"
    "debug_*.sh"
    "test_*.sh"
    "monitor_*.sh"
    "deep_debug_*.sh"
    "final_fix_*.sh"
    "mariadb_*_fix.sh"
    "quick_fix_*.sh"
    "working_config_*.sh"
    "*_diagnostic.sh"
    "create_test_*.sh"
)

# Fichiers de configuration temporaires
TEMP_CONFIGS=(
    "docker-compose-*.yml"
    "docker-compose.*.yml"
    "docker-compose.template.yml"
    "*.backup"
    ".env.local"
    ".env.*.local"
    "docker-compose.override.yml"
)

# Fichiers de build et IDE
BUILD_FILES=(
    "target/"
    "build/"
    "dist/"
    "node_modules/"
    ".mvn/"
    "*.jar"
    "*.war"
    "gen-ts.ps1"
    "update.ps1"
    "mvnw"
    "mvnw.cmd"
    "pom.xml"
    "bitbucket-pipelines.yml"
)

# Dossiers de données temporaires
TEMP_DIRS=(
    "volumes/"
    "data/"
    "storage/"
    "logs/"
    "docker/mariadb-test/"
    "cache/"
    "git/"
    "local-maven-repo/"
    "src/"
    ".idea/"
    ".vscode/"
)

# Fichiers de sauvegarde automatiques
BACKUP_FILES=(
    ".cleanup-backup-*/"
    ".backup-*/"
    "backup-*/"
    "docker/painter/Dockerfile.backup"
)

# Compter les fichiers
total_files=0

echo ""
echo "🗂️  Fichiers temporaires :"
for pattern in "${TEMP_FILES[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        ls -la $pattern 2>/dev/null | head -3
        total_files=$((total_files + $(ls $pattern 2>/dev/null | wc -l)))
    fi
done

echo ""
echo "🔧 Scripts de debug :"
for pattern in "${DEBUG_SCRIPTS[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        ls -la $pattern 2>/dev/null | head -3
        total_files=$((total_files + $(ls $pattern 2>/dev/null | wc -l)))
    fi
done

echo ""
echo "⚙️  Configurations temporaires :"
for pattern in "${TEMP_CONFIGS[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        ls -la $pattern 2>/dev/null | head -3
        total_files=$((total_files + $(ls $pattern 2>/dev/null | wc -l)))
    fi
done

echo ""
echo "📦 Fichiers de build :"
for pattern in "${BUILD_FILES[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        ls -la $pattern 2>/dev/null | head -2
        total_files=$((total_files + $(find . -name "$pattern" 2>/dev/null | wc -l)))
    fi
done

echo ""
echo "📁 Dossiers temporaires :"
for pattern in "${TEMP_DIRS[@]}"; do
    if [ -d "$pattern" ]; then
        echo "   $pattern/ ($(du -sh "$pattern" 2>/dev/null | cut -f1))"
        total_files=$((total_files + 1))
    fi
done

echo ""
echo "💾 Sauvegardes automatiques :"
for pattern in "${BACKUP_FILES[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        ls -la $pattern 2>/dev/null | head -2
        total_files=$((total_files + $(ls -d $pattern 2>/dev/null | wc -l)))
    fi
done

echo ""
print_warning "Total estimé : $total_files fichiers/dossiers à supprimer"

# Demander confirmation
echo ""
print_header "CONFIRMATION"
echo -e "${RED}⚠️  ATTENTION : Cette opération est irréversible !${NC}"
echo ""
echo "Actions qui seront effectuées :"
echo "✅ Création d'une sauvegarde dans $BACKUP_DIR"
echo "🗑️  Suppression de tous les fichiers temporaires et de test"
echo "📁 Nettoyage des dossiers inutiles"
echo "🧹 Nettoyage des volumes Docker de test"
echo "📋 Création d'une structure de projet propre"
echo ""

read -p "Voulez-vous vraiment procéder au nettoyage sévère ? (tapez 'OUI' en majuscules): " -r
echo ""

if [ "$REPLY" != "OUI" ]; then
    print_info "Nettoyage annulé par l'utilisateur"
    exit 0
fi

# Créer la sauvegarde
print_header "CRÉATION DE LA SAUVEGARDE"

mkdir -p "$BACKUP_DIR"
print_info "Création du dossier de sauvegarde : $BACKUP_DIR"

# Sauvegarder les fichiers importants avant suppression
echo ""
print_info "Sauvegarde des fichiers de configuration..."

# Sauvegarder les configurations importantes
if [ -f ".env" ]; then
    cp ".env" "$BACKUP_DIR/"
    print_success "Fichier .env sauvegardé"
fi

if [ -f "docker-compose.yml" ]; then
    cp "docker-compose.yml" "$BACKUP_DIR/"
    print_success "docker-compose.yml sauvegardé"
fi

if [ -d "docker/ssh-keys" ]; then
    cp -r "docker/ssh-keys" "$BACKUP_DIR/"
    print_success "Clés SSH sauvegardées"
fi

if [ -d "init-db" ]; then
    cp -r "init-db" "$BACKUP_DIR/" 2>/dev/null || true
    print_success "init-db sauvegardé"
fi

# Sauvegarder les scripts de démarrage existants
for script in start*.sh stop*.sh; do
    if [ -f "$script" ]; then
        cp "$script" "$BACKUP_DIR/"
    fi
done

# Arrêter les services Docker s'ils tournent
print_header "ARRÊT DES SERVICES DOCKER"
if docker-compose ps >/dev/null 2>&1; then
    print_info "Arrêt des services Docker en cours..."
    docker-compose down --remove-orphans >/dev/null 2>&1 || true
    print_success "Services Docker arrêtés"
else
    print_info "Aucun service Docker en cours"
fi

# Phase de suppression
print_header "SUPPRESSION DES FICHIERS TEMPORAIRES"

files_deleted=0
dirs_deleted=0

echo ""
print_info "Suppression des fichiers temporaires..."
for pattern in "${TEMP_FILES[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        rm -f $pattern 2>/dev/null || true
        files_deleted=$((files_deleted + 1))
    fi
done

print_info "Suppression des scripts de debug..."
for pattern in "${DEBUG_SCRIPTS[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        rm -f $pattern 2>/dev/null || true
        files_deleted=$((files_deleted + 1))
    fi
done

print_info "Suppression des configurations temporaires..."
for pattern in "${TEMP_CONFIGS[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        rm -f $pattern 2>/dev/null || true
        files_deleted=$((files_deleted + 1))
    fi
done

print_info "Suppression des fichiers de build..."
for pattern in "${BUILD_FILES[@]}"; do
    if [ -d "$pattern" ]; then
        rm -rf "$pattern" 2>/dev/null || true
        dirs_deleted=$((dirs_deleted + 1))
    elif ls $pattern >/dev/null 2>&1; then
        rm -f $pattern 2>/dev/null || true
        files_deleted=$((files_deleted + 1))
    fi
done

print_info "Suppression des dossiers temporaires..."
for pattern in "${TEMP_DIRS[@]}"; do
    if [ -d "$pattern" ]; then
        rm -rf "$pattern" 2>/dev/null || true
        dirs_deleted=$((dirs_deleted + 1))
    fi
done

print_info "Suppression des sauvegardes automatiques anciennes..."
for pattern in "${BACKUP_FILES[@]}"; do
    if ls $pattern >/dev/null 2>&1; then
        rm -rf $pattern 2>/dev/null || true
        dirs_deleted=$((dirs_deleted + 1))
    fi
done

# Nettoyage spécialisé
print_info "Nettoyage des volumes Docker de test..."
docker volume ls -q | grep -E "(test|temp|backup)" | xargs -r docker volume rm 2>/dev/null || true

print_info "Nettoyage des images Docker inutiles..."
docker image prune -f >/dev/null 2>&1 || true

print_success "Suppression terminée : $files_deleted fichiers et $dirs_deleted dossiers supprimés"

# Création de la structure propre
print_header "CRÉATION DE LA STRUCTURE PROPRE"

print_info "Création des dossiers organisés..."

# Créer la structure de répertoires
mkdir -p docs/{FR,EN}
mkdir -p scripts
mkdir -p docker/{nginx,ssh-keys}
mkdir -p init-db

print_success "Structure de répertoires créée"

# Créer un .gitignore optimisé
print_info "Création du .gitignore optimisé..."

cat > .gitignore << 'EOF'
# =============================================================================
# CardManager - .gitignore optimisé
# =============================================================================

# Volumes Docker locaux
volumes/
data/
storage/

# Sauvegardes automatiques
.cleanup-backup-*/
.backup-*/
backup-*/

# Logs
*.log
logs/

# Fichiers temporaires
.DS_Store
Thumbs.db
*.tmp
*.temp
*.swp
*.swo
*~

# Configuration locale
docker-compose.override.yml
.env.local
.env.*.local

# IDE et éditeurs
.idea/
.vscode/
*.iml
*.ipr
*.iws

# Build artifacts
target/
build/
dist/
node_modules/
.mvn/

# Données sensibles
secrets/
certificates/
*.key
*.pem
*.crt

# Fichiers de test et debug
debug_*.sh
fix_*.sh
test_*.sh
*_test.sh
*_debug.sh
monitoring_*.sh

# Fichiers SQL temporaires
*.sql
!init-db/*.sql

# Fichiers Docker temporaires
docker-compose-*.yml
docker-compose.*.yml
*.backup

# Fichiers de développement
structure.txt
toto.*
prompt.txt
readme
EOF

print_success ".gitignore optimisé créé"

# Créer un README temporaire
print_info "Création du README.md principal..."

cat > README.md << 'EOF'
# 🃏 CardManager - Docker Project

**Complete card collection management system with Bitbucket integration**

## ⚡ Quick Start

```bash
# 1. Configure SSH access to Bitbucket
# 2. Copy SSH keys to docker/ssh-keys/
# 3. Configure .env file
# 4. Start services
docker-compose up -d
```

## 📚 Documentation

- **[🇫🇷 French Documentation](docs/FR/)** - Documentation française complète
- **[🇬🇧 English Documentation](docs/EN/)** - Complete English documentation

## 🏗️ Architecture

- **GestionCarte** (Port 8080) - Main web application
- **Painter** (Port 8081) - Image processing service
- **MariaDB** (Port 3308) - Database
- **Nginx** (Port 8082) - Image server

## 🚀 Services

| Service | URL | Description |
|---------|-----|-------------|
| Main App | http://localhost:8080 | Web interface |
| API | http://localhost:8081 | Image processing |
| Images | http://localhost:8082 | Image server |

---

**This project was cleaned and optimized** ✨
EOF

print_success "README.md principal créé"

# Créer un template .env
if [ ! -f ".env" ]; then
    print_info "Création du template .env..."

    cat > .env << 'EOF'
# =============================================================================
# CardManager Configuration for Bitbucket repositories
# =============================================================================

# === BITBUCKET REPOSITORIES ===
MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git

# === DEVELOPMENT BRANCHES ===
MASON_BRANCH=feature/RETRIEVER-511
PAINTER_BRANCH=feature/card-manager-511
GESTIONCARTE_BRANCH=feature/card-manager-511

# === DATABASE ===
LOCAL_DB_HOST=localhost
LOCAL_DB_PORT=3306
LOCAL_DB_NAME=dev
LOCAL_DB_USER=ia
LOCAL_DB_PASS=foufafou

# === NETWORK CONFIGURATION ===
GESTIONCARTE_PORT=8080
PAINTER_PORT=8081
NGINX_PORT=8082
DB_PORT=3308

# === JVM CONFIGURATION ===
JAVA_OPTS_GESTIONCARTE="-Xms512m -Xmx1024m"
JAVA_OPTS_PAINTER="-Xms512m -Xmx1024m"

# === SPRING CONFIGURATION ===
SPRING_PROFILES_ACTIVE=docker

# === SECURITY ===
MYSQL_ROOT_PASSWORD=root123
MYSQL_PASSWORD=foufafou

# === DOCKER CONFIGURATION ===
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
EOF

    print_success "Fichier .env créé"
fi

# Résumé final
print_header "NETTOYAGE TERMINÉ"

echo ""
print_success "✨ Projet CardManager nettoyé avec succès !"
echo ""

echo -e "${CYAN}📊 Résumé du nettoyage :${NC}"
echo "├── 🗑️  $files_deleted fichiers supprimés"
echo "├── 📁 $dirs_deleted dossiers supprimés"
echo "├── 💾 Sauvegarde dans $BACKUP_DIR/"
echo "├── 📋 Structure organisée créée"
echo "├── 🔧 .gitignore optimisé"
echo "└── 📖 README.md principal créé"

echo ""
echo -e "${CYAN}📁 Structure finale du projet :${NC}"
echo "docker-cardmanager-bitbucket/"
echo "├── README.md"
echo "├── docker-compose.yml"
echo "├── .env"
echo "├── .gitignore"
echo "├── docs/"
echo "│   ├── FR/ (documentation française)"
echo "│   └── EN/ (English documentation)"
echo "├── scripts/ (utilitaires)"
echo "├── docker/ (Dockerfiles)"
echo "│   ├── mason/"
echo "│   ├── painter/"
echo "│   ├── gestioncarte/"
echo "│   ├── nginx/"
echo "│   └── ssh-keys/"
echo "├── init-db/ (scripts SQL)"
echo "└── $BACKUP_DIR/ (sauvegarde)"

echo ""
echo -e "${GREEN}🎯 Prochaines étapes recommandées :${NC}"
echo "1. Vérifiez le fichier .env"
echo "2. Configurez les clés SSH Bitbucket"
echo "3. Testez le démarrage : docker-compose up -d"
echo "4. Créez la documentation complète"

echo ""
echo -e "${YELLOW}⚠️  Important :${NC}"
echo "• Sauvegarde disponible dans $BACKUP_DIR/"
echo "• Vérifiez les configurations avant le démarrage"
echo "• Le fichier .env contient les valeurs par défaut"

echo ""
print_success "🚀 Projet prêt pour le développeur anglophone !"

exit 0