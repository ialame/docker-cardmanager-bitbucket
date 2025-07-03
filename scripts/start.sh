# CardManager - Startup script
# Version: 2.0.0
# Author: CardManager Team

# Colors for display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Prerequisites check function
check_prerequisites() {
    log_header "🔍 Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        log_info "Install Docker Desktop from https://docker.com"
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        log_info "Docker Compose is included with Docker Desktop"
        exit 1
    fi

    # Check that Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not started"
        log_info "Start Docker Desktop and try again"
        exit 1
    fi

    log_success "Docker and Docker Compose are available"
}

# Configuration check function
check_configuration() {
    log_header "⚙️  Checking configuration..."

    # Check docker-compose.yml file
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "docker-compose.yml file not found in $PROJECT_DIR"
        exit 1
    fi

    # Check .env file
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning ".env file not found"

        if [[ -f "$PROJECT_DIR/.env.template" ]]; then
            log_info "Copying .env.template to .env..."
            cp "$PROJECT_DIR/.env.template" "$ENV_FILE"
            log_success ".env file created from template"
        else
            log_error ".env.template file not found"
            exit 1
        fi
    fi

    # Check SSH keys for Bitbucket
    if [[ ! -d "$PROJECT_DIR/docker/ssh-keys" ]] || [[ ! -f "$PROJECT_DIR/docker/ssh-keys/bitbucket_ed25519" ]]; then
        log_warning "Bitbucket SSH keys not configured"
        log_info "Consult the deployment guide to configure Bitbucket access"
        log_info "Guide: docs/EN/DEPLOYMENT-EN.md#bitbucket-configuration"

        read -p "Do you want to continue without SSH keys? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "SSH key configuration cancelled"
            exit 1
        fi
    fi

    log_success "Configuration verified"
}

# Port check function
check_ports() {
    log_header "🔌 Checking ports..."

    local ports=("8080" "8081" "8082" "3308")
    local occupied_ports=()

    for port in "${ports[@]}"; do
        if lsof -i :$port &> /dev/null || netstat -an 2>/dev/null | grep -q ":$port "; then
            occupied_ports+=($port)
        fi
    done

    if [[ ${#occupied_ports[@]} -gt 0 ]]; then
        log_warning "Occupied ports: ${occupied_ports[*]}"
        log_info "Docker services will use these ports. Make sure they are free."

        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Startup cancelled"
            log_info "Free the ports or modify configuration in docker-compose.yml"
            exit 1
        fi
    else
        log_success "All ports are available"
    fi
}

# Build and startup function
start_services() {
    log_header "🚀 Starting CardManager..."

    cd "$PROJECT_DIR" || exit 1

    # Stop existing services
    log_info "Stopping existing services..."
    docker-compose down --remove-orphans &> /dev/null

    # Build images (first start or --build)
    if [[ "$1" == "--build" ]] || ! # The rest of the script would be translated similarly...