# Build arguments
ARG MASON_REPO_URL=git@bitbucket.org:pcafxc/mason.git
ARG MASON_BRANCH=feature/RETRIEVER-511

# Install git and openssh-client for SSH
RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

# Git configuration
RUN git config --global user.email "docker@cardmanager.local" && \
    git config --global user.name "Docker Builder"

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

# Create expected Maven parent structure
# 1. Create cardmanager parent POM
COPY ./docker/cardmanager-parent.xml ./pom.xml

# Debug: Verify parent POM
RUN echo "=== cardmanager parent POM ===" && \
    head -20 pom.xml

# 2. Clone Mason into subdirectory
RUN git clone --depth 1 --branch ${MASON_BRANCH} ${MASON_REPO_URL} mason

# Debug: Verify structure
RUN echo "=== Created structure ===" && \
    ls -la && \
    echo "=== Mason POM ===" && \
    head -20 mason/pom.xml

# 3. Build parent first
RUN mvn install -N

# 4. Build Mason
WORKDIR /usr/src/app/mason
RUN mvn clean install -DskipTests -B

# Lightweight final image for sharing artifacts
FROM alpine:latest
WORKDIR /app

# Copy built Maven artifacts
COPY --from=builder /root/.m2/repository /opt/maven-repo

# Mark as volume for sharing with other services
VOLUME ["/opt/maven-repo"]

# Dummy entry point (this service only builds dependencies)
CMD ["echo", "Mason artifacts built successfully"]