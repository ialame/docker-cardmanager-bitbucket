#!/bin/bash
set -e

echo "🚀 Démarrage de CardManager..."
echo "==============================="

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    echo "💡 Installez Docker Desktop depuis https://www.docker.com/"
    exit 1
fi

# Vérifier Docker Compose
if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
    echo "❌ Docker Compose n'est pas disponible"
    exit 1
fi

echo "✅ Docker détecté"

# Créer les volumes s'ils n'existent pas
echo "📦 Préparation des volumes..."
docker volume create cardmanager_db_data 2>/dev/null || true
docker volume create cardmanager_images 2>/dev/null || true

# Démarrer les services
echo "🔄 Démarrage des services..."
docker-compose up -d

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 10

# Vérifier l'état
echo ""
echo "📊 État des services :"
docker-compose ps

echo ""
echo "🎉 CardManager démarré avec succès !"
echo ""
echo "📱 URLs d'accès :"
echo "   • Application principale : http://localhost:8080"
echo "   • Galerie d'images       : http://localhost:8082/images/"
echo "   • API Painter            : http://localhost:8081"
echo ""
echo "🔍 Commandes utiles :"
echo "   • Voir les logs : docker-compose logs -f"
echo "   • Arrêter       : ./stop.sh"
echo "   • Diagnostic    : ./diagnostic.sh"
