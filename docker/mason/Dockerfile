# syntax=docker/dockerfile:1

FROM maven:3.9.6-eclipse-temurin-21 AS builder

# Arguments de build
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511

# Installer git et openssh-client pour SSH
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Configurer SSH
RUN mkdir -p ~/.ssh && \
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts && \
    chmod 700 ~/.ssh && \
    chmod 644 ~/.ssh/known_hosts

# Configuration Git pour éviter les warnings
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Répertoire de travail
WORKDIR /usr/src/app

# Cloner le dépôt Mason avec SSH mount
RUN --mount=type=ssh,id=default \
    git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Se placer dans le dossier mason et construire
WORKDIR /usr/src/app/mason

# Construire Mason (sans tests pour accélérer)
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