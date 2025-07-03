# Build arguments
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511
ARG PAINTER_REPO_URL=git@bitbucket.org:pcafxc/painter.git
ARG PAINTER_BRANCH=feature/card-manager-511
ARG GESTIONCARTE_REPO_URL=git@bitbucket.org:pcafxc/gestioncarte.git
ARG GESTIONCARTE_BRANCH=feature/card-manager-511

# Install git, openssh-client and Node.js for frontend
RUN apt-get update && apt-get install -y openssh-client git curl && rm -rf /var/lib/apt/lists/*

# Install Node.js for frontend
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Copy SSH keys from build context
COPY ./docker/ssh-keys/ /root/.ssh/

# Configure SSH permissions
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/bitbucket_ed25519 && \
    chmod 644 /root/.ssh/bitbucket_ed25519.pub && \
    chmod 644 /root/.ssh/config && \
    ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts && \
    chmod 644 /root/.ssh/known_hosts

# Working directory
WORKDIR /usr/src/app

# Create Maven parent structure
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Clone all projects
RUN git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason
RUN git clone --depth 1 --branch ${PAINTER_BRANCH} ${PAINTER_REPO_URL} painter
RUN git clone --depth 1 --branch ${GESTIONCARTE_BRANCH} ${GESTIONCARTE_REPO_URL} gestioncarte

# Build parent
RUN mvn install -N

# Build Mason (dependency)
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Build Painter (dependency)
WORKDIR /usr/src/app/painter
RUN mvn clean install -DskipTests -B

# Build GestionCarte
WORKDIR /usr/src/app/gestioncarte
RUN mvn clean package -DskipTests -B

# Final image for execution
FROM eclipse-temurin:21-jre-alpine

# Install wget for health check
RUN apk add --no-cache wget

# Working directory
WORKDIR /app

# Copy GestionCarte JAR
COPY --from=builder /usr/src/app/gestioncarte/target/*.jar app.jar

# Optimized JVM configuration
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Environment variables for GestionCarte
ENV SPRING_PROFILES_ACTIVE="docker"

# Exposed port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Entry point
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]