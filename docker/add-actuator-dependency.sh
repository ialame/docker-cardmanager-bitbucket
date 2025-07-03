#!/bin/bash
# Script exécuté pendant le build Docker pour ajouter Actuator

PAINTER_POM="/usr/src/app/painter/painter/pom.xml"

if [ -f "$PAINTER_POM" ]; then
    echo "Ajout de la dépendance Actuator au pom.xml de Painter..."

    # Créer une copie de sauvegarde
    cp "$PAINTER_POM" "${PAINTER_POM}.backup"

    # Ajouter la dépendance Actuator avant la dernière balise </dependencies>
    sed -i '/<\/dependencies>/i \
\t\t<!-- Spring Boot Actuator pour endpoints de monitoring -->\
\t\t<dependency>\
\t\t\t<groupId>org.springframework.boot</groupId>\
\t\t\t<artifactId>spring-boot-starter-actuator</artifactId>\
\t\t</dependency>' "$PAINTER_POM"

    echo "✅ Dépendance Actuator ajoutée avec succès"
else
    echo "❌ Fichier pom.xml non trouvé : $PAINTER_POM"
    exit 1
fi
