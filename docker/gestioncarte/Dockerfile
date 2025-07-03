FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
ARG GESTIONCARTE_BRANCH=feature/card-manager-511

# Installer git, openssh-client et Node.js pour le frontend
RUN apt-get update && apt-get install -y openssh-client git curl && rm -rf /var/lib/apt/lists/*

# Installer Node.js pour le frontend
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

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

# Cloner tous les projets
RUN git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason
RUN git clone --depth 1 --branch ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter
RUN git clone --depth 1 --branch ${GESTIONCARTE_BRANCH} ${GESTIONCARTE_REPO_URL} gestioncarte

# Construire le parent
RUN mvn install -N

# Construire Mason (dépendance)
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Construire Painter (dépendance)
WORKDIR /usr/src/app/painter
RUN mvn clean install -DskipTests -B

# Construire GestionCarte
WORKDIR /usr/src/app/gestioncarte
RUN mvn clean package -DskipTests -B

# Image finale pour l'exécution
FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="cardmanager@example.com"
LABEL description="GestionCarte - Main CardManager Application"

# Installer wget pour le health check
RUN apk add --no-cache wget

# Répertoire de travail
WORKDIR /app

# Copier le JAR de GestionCarte
COPY --from=builder /usr/src/app/gestioncarte/target/*.jar app.jar

# Configuration JVM optimisée
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Variables d'environnement pour GestionCarte
ENV SPRING_PROFILES_ACTIVE="docker"

# Port d'exposition
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
