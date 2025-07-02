@echo off
echo 🛑 Arrêt de CardManager...
echo =========================

docker-compose down

echo.
echo ✅ CardManager arrêté
echo.
echo 💡 Pour redémarrer : start.bat
echo 🗑️ Pour tout supprimer : docker-compose down --volumes
echo.
pause
