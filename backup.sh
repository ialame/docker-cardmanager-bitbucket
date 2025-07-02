#!/bin/bash
set -e

backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
echo "💾 Sauvegarde CardManager vers $backup_dir..."
echo "============================================="

mkdir -p "$backup_dir"

# Sauvegarde de la base de données
echo "📊 Sauvegarde de la base de données..."
docker-compose exec -T mariadb-standalone mysqldump -u ia -p'foufafou' dev > "$backup_dir/database.sql"

# Sauvegarde des images
echo "🖼️ Sauvegarde des images..."
docker run --rm -v cardmanager_images:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/images.tar.gz /data

# Sauvegarde de la configuration
echo "⚙️ Sauvegarde de la configuration..."
cp docker-compose.yml "$backup_dir/"
cp -r init-db "$backup_dir/" 2>/dev/null || true

echo ""
echo "✅ Sauvegarde terminée dans $backup_dir/"
echo ""
echo "📁 Contenu de la sauvegarde :"
ls -la "$backup_dir/"

echo ""
echo "📋 Pour restaurer :"
echo "   1. Placez database.sql dans init-db/"
echo "   2. Supprimez les volumes : docker-compose down --volumes"
echo "   3. Redémarrez : ./start.sh"
