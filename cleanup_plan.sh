#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📋 Plan de nettoyage et mise à jour CardManager${NC}"
echo "=============================================="

echo -e "${YELLOW}🧹 PHASE 1: NETTOYAGE DU CODE${NC}"
echo "=============================="

echo "1. Nettoyage des fichiers temporaires et de test"
echo "   • Supprimer les docker-compose-*.yml temporaires"
echo "   • Nettoyer les scripts de diagnostic"
echo "   • Organiser les sauvegardes"

echo ""
echo "2. Optimisation de la configuration finale"
echo "   • Valider docker-compose.yml définitif"
echo "   • Nettoyer le fichier .env"
echo "   • Vérifier les Dockerfiles"

echo ""
echo "3. Structure des fichiers"
echo "   • Créer dossiers docs/, scripts/"
echo "   • Organiser les fichiers de configuration"
echo "   • Ajouter .gitignore approprié"

echo ""
echo -e "${YELLOW}📝 PHASE 2: MISE À JOUR DOCUMENTATION${NC}"
echo "====================================="

echo "1. Documentation française (docs/)"
echo "   • README-FR.md - Guide principal"
echo "   • DEPLOIEMENT-FR.md - Installation détaillée"
echo "   • FAQ-FR.md - Questions fréquentes"
echo "   • TECHNIQUE-FR.md - Configuration avancée"

echo ""
echo "2. Documentation anglaise (docs/)"
echo "   • README-EN.md - Main guide"
echo "   • DEPLOYMENT-EN.md - Detailed installation"
echo "   • FAQ-EN.md - Frequently asked questions"
echo "   • TECHNICAL-EN.md - Advanced configuration"

echo ""
echo "3. Fichiers de configuration"
echo "   • .env.template - Modèle de configuration"
echo "   • docker-compose.yml - Configuration finale"
echo "   • Scripts d'automatisation"

echo ""
echo -e "${YELLOW}🚀 PHASE 3: SCRIPTS D'AUTOMATISATION${NC}"
echo "==================================="

echo "1. Scripts de gestion"
echo "   • start.sh / start.bat - Démarrage"
echo "   • stop.sh / stop.bat - Arrêt"
echo "   • diagnostic.sh - Diagnostic automatique"
echo "   • backup.sh - Sauvegarde"

echo ""
echo "2. Scripts de maintenance"
echo "   • update.sh - Mise à jour"
echo "   • clean.sh - Nettoyage"
echo "   • reset.sh - Réinitialisation"

echo ""
echo -e "${GREEN}✨ RÉSULTAT FINAL${NC}"
echo "================="

echo "Structure de projet propre et professionnelle :"
echo ""
echo "docker-cardmanager-bitbucket/"
echo "├── README.md (liens vers docs/)"
echo "├── docker-compose.yml"
echo "├── .env.template"
echo "├── .gitignore"
echo "├── docs/"
echo "│   ├── FR/"
echo "│   │   ├── README-FR.md"
echo "│   │   ├── DEPLOIEMENT-FR.md"
echo "│   │   ├── FAQ-FR.md"
echo "│   │   └── TECHNIQUE-FR.md"
echo "│   └── EN/"
echo "│       ├── README-EN.md"
echo "│       ├── DEPLOYMENT-EN.md"
echo "│       ├── FAQ-EN.md"
echo "│       └── TECHNICAL-EN.md"
echo "├── scripts/"
echo "│   ├── start.sh"
echo "│   ├── stop.sh"
echo "│   ├── diagnostic.sh"
echo "│   ├── backup.sh"
echo "│   └── clean.sh"
echo "├── docker/"
echo "│   ├── painter/"
echo "│   ├── gestioncarte/"
echo "│   └── nginx/"
echo "└── init-db/"

echo ""
read -p "Voulez-vous commencer le nettoyage et la mise à jour ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}🚀 Démarrage du processus de nettoyage...${NC}"

    # Phase 1: Nettoyage
    echo -e "${YELLOW}Phase 1: Nettoyage des fichiers temporaires...${NC}"

    # Créer les dossiers
    mkdir -p docs/{FR,EN} scripts docker/{nginx,ssh-keys} init-db

    # Déplacer les fichiers existants
    if [ -f "docker-compose-final.yml" ]; then
        mv docker-compose-final.yml docker-compose.yml
    fi

    # Supprimer les fichiers temporaires
    rm -f docker-compose-*.yml
    rm -f fix_*.sh
    rm -f *_diagnostic.sh
    rm -f working_config_fix.sh
    rm -f deep_debug_painter_url.sh
    rm -f final_fix_solution.sh
    rm -f mariadb_ultimate_fix.sh
    rm -f quick_fix_mariadb.sh

    echo "✅ Nettoyage terminé"

    # Phase 2: Documentation
    echo -e "${YELLOW}Phase 2: Génération de la documentation...${NC}"
    echo "📝 Prêt pour la génération des fichiers de documentation"

    echo ""
    echo -e "${GREEN}🎯 Prochaines étapes :${NC}"
    echo "1. Je vais générer les fichiers de documentation"
    echo "2. Créer les scripts d'automatisation"
    echo "3. Finaliser la structure du projet"

else
    echo -e "${YELLOW}ℹ️  Nettoyage annulé.${NC}"
fi