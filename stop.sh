#!/bin/bash
set -e

echo "🛑 Arrêt de CardManager..."
echo "=========================="

# Arrêter les services
docker-compose down

echo ""
echo "✅ CardManager arrêté"
echo ""
echo "💡 Pour redémarrer : ./start.sh"
echo "🗑️ Pour supprimer les données : docker-compose down --volumes"
