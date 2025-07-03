#!/bin/bash
echo "🎯 MONITORING SAUVEGARDE IMAGES"
echo "================================"

while true; do
    clear
    echo "⏰ $(date)"
    echo ""

    echo "📊 État des services :"
    docker-compose ps | grep -E "(painter|gestioncarte)"
    echo ""

    echo "📁 Contenu dossier images :"
    docker exec cardmanager-painter find /app/images -type f 2>/dev/null | wc -l | xargs echo "Nombre de fichiers :"
    docker exec cardmanager-painter ls -la /app/images/ 2>/dev/null || echo "Dossier non accessible"
    echo ""

    echo "🌐 Tests de connectivité :"
    curl -s http://localhost:8080/actuator/health | grep -q UP && echo "✅ GestionCarte" || echo "❌ GestionCarte"
    curl -s http://localhost:8081/actuator/health | grep -q UP && echo "✅ Painter" || echo "❌ Painter"
    echo ""

    echo "Appuyez sur Ctrl+C pour arrêter..."
    sleep 5
done
