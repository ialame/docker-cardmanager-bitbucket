FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /usr/src/app

# Copier et installer le POM parent cardmanager
COPY docker/cardmanager-parent.xml cardmanager-pom.xml
RUN mvn install:install-file \
    -Dfile=cardmanager-pom.xml \
    -DgroupId=com.pcagrade \
    -DartifactId=cardmanager \
    -Dversion=1.0.0-SNAPSHOT \
    -Dpackaging=pom

# Cloner Mason
RUN git clone --depth 1 --branch main https://github.com/ialame/mason.git mason

# Build Mason avec le POM parent disponible
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests

# Image finale - Mason est une bibliothèque, pas une application
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -g 1000 appgroup && adduser -u 1000 -G appgroup -s /bin/sh -D appuser
USER appuser
EXPOSE 8083
CMD ["java", "-version"]
