# syntax=docker/dockerfile:1

FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511

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

# Créer la structure Maven parent comme attendue
# 1. Créer le POM parent cardmanager
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Debug: Vérifier le POM parent
RUN echo "=== POM parent cardmanager ===" && \
    head -20 pom.xml

# 2. Cloner Mason dans le sous-répertoire
RUN git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Debug: Vérifier la structure
RUN echo "=== Structure créée ===" && \
    ls -la && \
    echo "=== POM de Mason ===" && \
    head -20 mason/pom.xml

# 3. Construire d'abord le parent
RUN mvn install -N

# 4. Construire Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Image finale légère pour partager les artefacts
FROM alpine:latest
WORKDIR /app

# Copier les artefacts Maven construits
COPY --from=builder /root/.m2/repository /opt/maven-repo

# Marquer comme volume pour partage avec autres services
VOLUME ["/opt/maven-repo"]

# Point d'entrée factice (ce service sert juste à construire les dépendances)
CMD ["echo", "Mason artifacts built successfully"]
