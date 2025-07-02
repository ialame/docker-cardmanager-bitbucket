#!/bin/bash
echo "🧹 Nettoyage et organisation du projet CardManager..."

# Créer un dossier de sauvegarde pour les anciens fichiers
BACKUP_DIR=".cleanup-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📁 Sauvegarde des anciens fichiers dans $BACKUP_DIR..."

# Sauvegarder les scripts de test/debug existants
for file in debug_*.sh fix_*.sh test_*.sh monitor_*.sh create_test_*.sh; do
    if [ -f "$file" ]; then
        mv "$file" "$BACKUP_DIR/"
    fi
done

# Sauvegarder les anciennes configurations
for file in docker-compose.*.yml *.backup; do
    if [ -f "$file" ]; then
        mv "$file" "$BACKUP_DIR/"
    fi
done

echo "✅ Anciens fichiers sauvegardés"

# Créer la structure organisée
echo "📂 Création de la structure organisée..."

# Créer les dossiers nécessaires
mkdir -p docs/guides
mkdir -p scripts
mkdir -p docker/{mason,painter,gestioncarte}

echo "✅ Structure créée"

# Nettoyer les volumes Docker (images de test)
echo "🗑️ Nettoyage des images de test..."
docker run --rm -v cardmanager_images:/images alpine sh -c "
    rm -rf /images/test /images/uploads /images/README.txt 2>/dev/null || true
    echo 'Images de test supprimées'
" 2>/dev/null || echo "Volume non trouvé (normal si premier démarrage)"

echo "✅ Nettoyage terminé"

echo ""
echo "📋 Résumé du nettoyage :"
echo "├── 📁 $BACKUP_DIR/           (anciens fichiers sauvegardés)"
echo "├── 📁 docs/guides/          (guides de déploiement)"
echo "├── 📁 scripts/              (scripts utilitaires)"
echo "├── 📁 docker/               (Dockerfiles)"
echo "└── 🗑️ Images de test supprimées"
echo ""
echo "🚀 Prêt pour la création des nouveaux guides !"