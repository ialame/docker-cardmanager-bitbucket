#!/bin/bash
echo "🔍 Diagnostic CardManager"
echo "========================="

echo ""
echo "🐳 Version Docker :"
docker --version
docker-compose --version 2>/dev/null || docker compose version

echo ""
echo "📊 État des services :"
docker-compose ps

echo ""
echo "🔌 Ports utilisés :"
if command -v lsof &> /dev/null; then
    lsof -i :8080,:8081,:8082,:3307 2>/dev/null || echo "Aucun conflit de port détecté"
else
    netstat -ano 2>/dev/null | grep -E ":8080|:8081|:8082|:3307" || echo "Commande netstat non disponible"
fi

echo ""
echo "💾 Espace disque :"
df -h 2>/dev/null || echo "Commande df non disponible"

echo ""
echo "🐳 Espace Docker :"
docker system df 2>/dev/null || echo "Impossible de vérifier l'espace Docker"

echo ""
echo "📋 Volumes CardManager :"
docker volume ls | grep cardmanager || echo "Aucun volume CardManager trouvé"

echo ""
echo "🌐 Tests de connectivité :"
echo -n "   Application (8080) : "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "Non accessible"

echo -n "   Images (8082)      : "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8082 2>/dev/null || echo "Non accessible"

echo -n "   API Painter (8081) : "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/health 2>/dev/null || echo "Non accessible"

echo ""
echo ""
echo "🎯 Diagnostic terminé"

if docker-compose ps | grep -q "Up"; then
    echo "✅ CardManager semble fonctionner correctement"
else
    echo "❌ Des services semblent arrêtés - essayez ./start.sh"
fi
