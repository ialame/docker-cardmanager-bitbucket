FROM eclipse-temurin:21-jdk-alpine AS builder

# Installer git et maven
RUN apk add --no-cache git maven

# Cloner Mason d'abord
WORKDIR /build
RUN git clone https://github.com/ialame/mason.git mason
WORKDIR /build/mason
RUN git checkout main
RUN mvn clean install -DskipTests

# Cloner Painter pour avoir les bonnes dépendances
WORKDIR /build
RUN git clone https://github.com/ialame/painter.git painter
WORKDIR /build/painter
RUN git checkout main

# CORRIGER le nom du package dans painter-client
# Renommer tous les fichiers painer -> painter
RUN find painter-client/src -name "*.java" -exec sed -i 's/com\.pcagrade\.painer/com.pcagrade.painter/g' {} \;
RUN find painter-client/src -type d -name "*painer*" | while read dir; do
    newdir=$(echo "$dir" | sed 's/painer/painter/g')
    mv "$dir" "$newdir" 2>/dev/null || true
done

# Rebuild Painter avec la correction
RUN mvn clean install -DskipTests

# Cloner et builder GestionCarte
WORKDIR /build
RUN git clone https://github.com/ialame/gestioncarte.git gestioncarte
WORKDIR /build/gestioncarte
RUN git checkout main

# Builder avec les bonnes dépendances
RUN mvn clean install -DskipTests -U

# Image finale
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copier le JAR
COPY --from=builder /build/gestioncarte/target/*.jar app.jar

# Configuration JVM
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

# Démarrage
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
