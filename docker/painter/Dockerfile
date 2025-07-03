# Stage 1: Builder
FROM maven:3.9.6-eclipse-temurin-21 as builder

# Installation des outils nécessaires
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Configuration Git
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

# Configuration SSH pour Bitbucket
COPY ./docker/ssh-keys/ /root/.ssh/
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    chmod 644 /root/.ssh/bitbucket_ed25519.pub && \
    chmod 644 /root/.ssh/config && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# Répertoire de travail
WORKDIR /usr/src/app

# Copier le POM parent
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Cloner les dépôts
RUN git clone --depth 1 --branch feature/RETRIEVER-511 git@bitbucket.org:pcafxc/mason.git mason
RUN git clone --depth 1 --branch feature/card-manager-511 git@bitbucket.org:pcafxc/painter.git painter

# Ajouter la dépendance Actuator
COPY ./docker/painter/fix/actuator-dependency.xml /tmp/actuator-dependency.xml
RUN cd painter/painter && \
    awk '/<dependencies>/ {print; system("cat /tmp/actuator-dependency.xml"); next} 1' pom.xml > pom.xml.tmp && \
    mv pom.xml.tmp pom.xml

RUN echo "=== Dépendance Actuator ajoutée au pom.xml ===" && \
    grep -A 4 -B 1 "spring-boot-starter-actuator" painter/painter/pom.xml

RUN echo "=== Vérification XML du pom.xml ===" && \
    xmllint --noout painter/painter/pom.xml && echo "XML valide" || echo "XML invalide"

# PATCH CRITIQUE : Ajouter le contrôleur AVANT la compilation
COPY ./docker/painter/patches/SimpleUploadController.java /tmp/SimpleUploadController.java
RUN mkdir -p painter/painter/src/main/java/com/pcagrade/painter/controller/ && \
    cp /tmp/SimpleUploadController.java painter/painter/src/main/java/com/pcagrade/painter/controller/

RUN echo "=== Contrôleur d'upload ajouté ===" && \
    ls -la painter/painter/src/main/java/com/pcagrade/painter/controller/

# Configuration application.properties
COPY ./docker/painter/config/application.properties painter/painter/src/main/resources/application.properties

RUN echo "=== Configuration Actuator dans application.properties ===" && \
    grep -A 5 "management" painter/painter/src/main/resources/application.properties

# Installation du parent
RUN mvn install -N

# Build Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Build Painter AVEC le contrôleur
WORKDIR /usr/src/app/painter
RUN mvn clean package -DskipTests -B

RUN echo "=== Vérification Actuator dans le JAR ===" && \
    jar tf painter/target/*.jar | grep -i actuator | head -5

RUN echo "=== Vérification contrôleur dans le JAR ===" && \
    jar tf painter/target/*.jar | grep -i SimpleUploadController

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine

# Installation des outils de diagnostic
RUN apk add --no-cache wget libxml2-utils

# Répertoire de travail
WORKDIR /app

# Copier le JAR depuis le builder
COPY --from=builder /usr/src/app/painter/painter/target/*.jar app.jar

# Créer le dossier images
RUN mkdir -p /app/images

# Exposer le port
EXPOSE 8081

# Démarrage avec profil docker
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dspring.profiles.active=docker -jar app.jar"]
