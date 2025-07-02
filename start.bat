@echo off
echo 🚀 Démarrage de CardManager...
echo ==============================

REM Vérifier Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker n'est pas installé ou pas disponible
    echo 💡 Installez Docker Desktop depuis https://www.docker.com/
    pause
    exit /b 1
)

echo ✅ Docker détecté

echo 📦 Démarrage des services...
docker-compose up -d

echo ⏳ Attente du démarrage...
timeout /t 10 /nobreak >nul

echo.
echo 📊 État des services :
docker-compose ps

echo.
echo 🎉 CardManager démarré !
echo.
echo 📱 URLs d'accès :
echo    • Application : http://localhost:8080
echo    • Images      : http://localhost:8082/images/
echo.
echo 🔍 Commandes utiles :
echo    • Voir les logs : docker-compose logs -f
echo    • Arrêter      : stop.bat
echo.
pause
