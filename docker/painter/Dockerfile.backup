FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG PAINTER_BRANCH=feature/card-manager-511

# Installer git et openssh-client pour SSH
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Copier les clés SSH depuis le contexte de build
COPY ./docker/ssh-keys/ /root/.ssh/

# Configurer les permissions SSH
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    chmod 644 /root/.ssh/bitbucket_ed25519.pub && \
    chmod 644 /root/.ssh/config && \
    ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts && \
    chmod 644 /root/.ssh/known_hosts

# Répertoire de travail
WORKDIR /usr/src/app

# Créer la structure Maven parent
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Cloner Mason d'abord (dépendance)
RUN git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Cloner Painter
RUN git clone --depth 1 --branch ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter

# Construire le parent
RUN mvn install -N

# Construire Mason (dépendance de Painter)
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Construire Painter
WORKDIR /usr/src/app/painter
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
COPY --from=builder /usr/src/app/painter/painter/target/*.jar app.jar

# Créer le dossier pour les images
RUN mkdir -p /app/images

# Configuration JVM optimisée
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Variables d'environnement pour Painter
ENV PAINTER_IMAGE_STORAGE_PATH="/app/images"
ENV SPRING_PROFILES_ACTIVE="docker"

# Port d'exposition
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
