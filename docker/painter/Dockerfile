FROM eclipse-temurin:21-jdk-alpine AS builder

# Installer git et maven
RUN apk add --no-cache git maven

# Cloner Mason d'abord (dépendance)
WORKDIR /build
RUN git clone https://github.com/ialame/mason.git mason
WORKDIR /build/mason
RUN git checkout main
RUN mvn clean install -DskipTests

# Cloner et builder Painter
WORKDIR /build
RUN git clone https://github.com/ialame/painter.git painter
WORKDIR /build/painter
RUN git checkout main

# Builder avec les endpoints API corrects
RUN mvn clean install -DskipTests

# Image finale
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copier le JAR principal de Painter
COPY --from=builder /build/painter/painter-application/target/*.jar app.jar

# Créer le dossier pour les images
RUN mkdir -p /app/images

# Configuration JVM
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Port
EXPOSE 8081

# Health check corrigé pour le bon endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD wget -qO- http://localhost:8081/actuator/health || exit 1

# Démarrage
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
