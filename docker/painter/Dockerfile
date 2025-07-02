# syntax=docker/dockerfile:1

FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG PAINTER_BRANCH=feature/card-manager-511

# Installer git et openssh-client pour SSH
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Configurer SSH
RUN mkdir -p ~/.ssh && \
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts && \
    chmod 700 ~/.ssh && \
    chmod 644 ~/.ssh/known_hosts

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Répertoire de travail
WORKDIR /usr/src/app

# Cloner Mason d'abord (dépendance)
RUN --mount=type=ssh,id=default \
    git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Construire Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Retour au répertoire racine et cloner Painter
WORKDIR /usr/src/app
RUN --mount=type=ssh,id=default \
    git clone --depth 1 --branch ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter

# Construire Painter
WORKDIR /usr/src/app/painter

# Corriger les éventuels problèmes de nommage (painer -> painter)
RUN find . -name "*.java" -type f -exec sed -i 's/com\.pcagrade\.painer/com.pcagrade.painter/g' {} \; || true

# Construire Painter
RUN mvn clean package -DskipTests -B

# Image finale pour l'exécution
FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="cardmanager@example.com"
LABEL description="Painter Service - Image processing for CardManager"

# Installer wget pour le health check
RUN apk add --no-cache wget

# Répertoire de travail
WORKDIR /app

# Copier le JAR principal de Painter
COPY --from=builder /usr/src/app/painter/painter-application/target/*.jar app.jar

# Créer le dossier pour les images
RUN mkdir -p /app/images && \
    chown -R 1000:1000 /app

# Configuration JVM optimisée
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Variables d'environnement pour Painter
ENV PAINTER_IMAGE_STORAGE_PATH="/app/images"
ENV SPRING_PROFILES_ACTIVE="docker"

# Port d'exposition
EXPOSE 8081

# Utilisateur non-root pour la sécurité
USER 1000:1000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]