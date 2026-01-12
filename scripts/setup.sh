#!/bin/bash
# Griot & Grits - Development Environment Setup
# Run this once to set up your local development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="${FRONTEND_DIR:-$HOME/gng-web}"
BACKEND_DIR="${BACKEND_DIR:-$HOME/griot-and-grits-backend}"

# GitHub repos
FRONTEND_REPO="https://github.com/griot-and-grits/gng-web.git"
BACKEND_REPO="https://github.com/griot-and-grits/griot-and-grits-backend.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

echo ""
echo "=========================================="
echo "  Griot & Grits Development Setup"
echo "=========================================="
echo ""

# Check prerequisites
print_status "Checking prerequisites..."

MISSING_DEPS=()

# Check Git
if command -v git &> /dev/null; then
    print_success "Git: $(git --version | cut -d' ' -f3)"
else
    print_error "Git: not found"
    MISSING_DEPS+=("git")
fi

# Check Docker
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        print_success "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_warning "Docker installed but daemon not running"
        MISSING_DEPS+=("docker-daemon")
    fi
else
    print_error "Docker: not found"
    MISSING_DEPS+=("docker")
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js: $NODE_VERSION"
else
    print_error "Node.js: not found"
    MISSING_DEPS+=("node")
fi

# Check npm
if command -v npm &> /dev/null; then
    print_success "npm: $(npm --version)"
else
    print_error "npm: not found"
    MISSING_DEPS+=("npm")
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python: $PYTHON_VERSION"
else
    print_error "Python3: not found"
    MISSING_DEPS+=("python3")
fi

# Check uv (preferred) or pip
if command -v uv &> /dev/null; then
    print_success "uv: $(uv --version)"
    USE_UV=true
elif command -v pip3 &> /dev/null; then
    print_warning "uv not found, using pip (consider installing uv for faster deps)"
    USE_UV=false
else
    print_error "Neither uv nor pip found"
    MISSING_DEPS+=("uv-or-pip")
fi

# Exit if missing critical dependencies
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    print_error "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Please install missing dependencies:"
    echo "  - Git: https://git-scm.com/downloads"
    echo "  - Docker: https://docs.docker.com/get-docker/"
    echo "  - Node.js: https://nodejs.org/ (v18+ required)"
    echo "  - Python: https://python.org (3.10+ required)"
    echo "  - uv (recommended): curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

echo ""
print_status "All prerequisites found!"
echo ""

# Clone or update project repositories
print_status "Checking project repositories..."

# Clone frontend if needed
if [ ! -d "$FRONTEND_DIR" ]; then
    print_status "Cloning frontend repository..."
    git clone "$FRONTEND_REPO" "$FRONTEND_DIR"
    print_success "Frontend cloned to: $FRONTEND_DIR"
else
    print_success "Frontend exists: $FRONTEND_DIR"
fi

# Clone backend if needed
if [ ! -d "$BACKEND_DIR" ]; then
    print_status "Cloning backend repository..."
    git clone "$BACKEND_REPO" "$BACKEND_DIR"
    print_success "Backend cloned to: $BACKEND_DIR"
else
    print_success "Backend exists: $BACKEND_DIR"
fi

echo ""

# Setup Backend
print_status "Setting up backend..."

cd "$BACKEND_DIR"

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        print_success "Created .env from .env.example"
    else
        # Create minimal .env
        cat > .env << 'EOF'
# Griot & Grits Backend - Local Development
ENVIRONMENT=development
DEBUG=true
APP_NAME=Griot and Grits API
APP_VERSION=0.1.0

# MongoDB (Docker)
DB_URI=mongodb://admin:gngdevpass12@localhost:27017/
DB_NAME=gngdb

# MinIO (Docker)
STORAGE_ENDPOINT=localhost:9000
STORAGE_ACCESS_KEY=minioadmin
STORAGE_SECRET_KEY=minioadmin
STORAGE_BUCKET=artifacts
STORAGE_REGION=us-east-1
STORAGE_SECURE=false

# Globus (disabled for local dev)
GLOBUS_ENABLED=false

# Processing
PROCESSING_MODE=sync
PROCESSING_ENABLE_METADATA_EXTRACTION=true
PROCESSING_ENABLE_TRANSCRIPTION=false
PROCESSING_ENABLE_LLM_ENRICHMENT=false

# CORS - allow local frontend
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS=*
CORS_ALLOW_HEADERS=*
EOF
        print_success "Created .env with local development defaults"
    fi
else
    print_warning ".env already exists, skipping"
fi

# Install Python dependencies
print_status "Installing backend dependencies..."
if [ "$USE_UV" = true ]; then
    uv sync
else
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -e ".[dev]"
fi
print_success "Backend dependencies installed"

echo ""

# Setup Frontend
print_status "Setting up frontend..."

cd "$FRONTEND_DIR"

# Create .env.local if it doesn't exist
if [ ! -f .env.local ]; then
    cat > .env.local << 'EOF'
# Griot & Grits Frontend - Local Development

# Backend API URL
NEXT_PUBLIC_ADMIN_API_BASE_URL=http://localhost:8000
NEXT_PUBLIC_ADMIN_API_TIMEOUT=30000

# Auth (disabled for local dev)
ADMIN_AUTH_DISABLED=true
ADMIN_DEV_BYPASS=true
ADMIN_DEV_TOKEN=dev-token-12345

# Features
FEATURE_ASK_THE_GRIOT=true
FEATURE_GOFUNDME=false
EOF
    print_success "Created .env.local with local development defaults"
else
    print_warning ".env.local already exists, skipping"
fi

# Install Node dependencies
print_status "Installing frontend dependencies..."
npm install
print_success "Frontend dependencies installed"

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Start services:    ./scripts/start-services.sh"
echo "  2. Start backend:     ./scripts/dev-backend.sh"
echo "  3. Start frontend:    ./scripts/dev-frontend.sh"
echo ""
echo "Or run everything:      ./scripts/dev-all.sh"
echo ""
