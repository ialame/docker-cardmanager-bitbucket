# syntax=docker/dockerfile:1

FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
ARG GESTIONCARTE_BRANCH=feature/card-manager-511

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    openssh-client \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installer Node.js pour le frontend (si nécessaire)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

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

# Cloner Mason d'abord (dépendance fondamentale)
RUN --mount=type=ssh,id=default \
    git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Construire Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Cloner Painter (dépendance pour GestionCarte)
WORKDIR /usr/src/app
RUN --mount=type=ssh,id=default \
    git clone --depth 1 --branch ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter

# Construire Painter (pour avoir les dépendances)
WORKDIR /usr/src/app/painter

# Corriger les problèmes de nommage
RUN find . -name "*.java" -type f -exec sed -i 's/com\.pcagrade\.painer/com.pcagrade.painter/g' {} \; || true

RUN mvn clean install -DskipTests -B

# Cloner GestionCarte
WORKDIR /usr/src/app
RUN --mount=type=ssh,id=default \
    git clone --depth 1 --branch ${GESTIONCARTE_BRANCH} ${GESTIONCARTE_REPO_URL} gestioncarte

# Construire GestionCarte
WORKDIR /usr/src/app/gestioncarte

# Si il y a un frontend, l'installer d'abord
RUN if [ -f "src/main/frontend/package.json" ]; then \
        cd src/main/frontend && \
        npm install && \
        npm run build; \
    fi

# Construire l'application principale
RUN mvn clean package -DskipTests -B -U

# Image finale pour l'exécution
FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="cardmanager@example.com"
LABEL description="GestionCarte - Main CardManager Application"

# Installer wget pour le health check
RUN apk add --no-cache wget

# Répertoire de travail
WORKDIR /app

# Copier le JAR de l'application
COPY --from=builder /usr/src/app/gestioncarte/target/*.jar app.jar

# Créer un utilisateur non-root
RUN addgroup -g 1000 cardmanager && \
    adduser -D -s /bin/sh -u 1000 -G cardmanager cardmanager && \
    chown -R cardmanager:cardmanager /app

# Configuration JVM optimisée
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Variables d'environnement
ENV SPRING_PROFILES_ACTIVE="docker"

# Port d'exposition
EXPOSE 8080

# Utilisateur non-root pour la sécurité
USER cardmanager:cardmanager

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]