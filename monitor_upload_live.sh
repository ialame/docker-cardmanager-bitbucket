#!/bin/bash

echo "🎯 MONITORING UPLOAD EN TEMPS RÉEL"
echo "=================================="

# Terminal pour surveiller les logs avec focus GestionCarte
echo "📋 Surveillez les logs Painter (focus sur les appels GestionCarte) :"
echo "docker-compose logs -f painter | grep -E '(🎯|✅|Upload|api/images|ERROR)'"
echo ""

# Commande pour voir les fichiers en temps réel
echo "📁 Surveillez les fichiers uploadés :"
echo "watch -n 1 'docker exec cardmanager-painter ls -la /app/images/'"
echo ""

# Test direct de l'interface
echo "🌐 Testez maintenant via l'interface :"
echo "http://localhost:8080"
echo ""

echo "📊 État actuel :"
docker exec cardmanager-painter ls -la /app/images/ | grep -v "^total"
echo ""

echo "⚡ Démarrage du monitoring des logs..."
docker-compose logs -f painter | grep --line-buffered -E "(🎯|✅|Upload|api/images|ERROR|success|failed)"
