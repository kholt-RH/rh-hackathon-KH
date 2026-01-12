#!/bin/bash
# Griot & Grits - Stop Infrastructure Services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Container names
MONGO_CONTAINER="gng-mongodb"
MINIO_CONTAINER="gng-minio"

echo ""
echo "=========================================="
echo "  Stopping Griot & Grits Services"
echo "=========================================="
echo ""

# Stop MongoDB
if docker ps --format '{{.Names}}' | grep -q "^${MONGO_CONTAINER}$"; then
    print_status "Stopping MongoDB..."
    docker stop "$MONGO_CONTAINER"
    print_success "MongoDB stopped"
else
    print_warning "MongoDB not running"
fi

# Stop MinIO
if docker ps --format '{{.Names}}' | grep -q "^${MINIO_CONTAINER}$"; then
    print_status "Stopping MinIO..."
    docker stop "$MINIO_CONTAINER"
    print_success "MinIO stopped"
else
    print_warning "MinIO not running"
fi

echo ""
print_success "All services stopped"
echo ""
echo "Data is preserved in Docker volumes."
echo "To remove data: docker volume rm gng-mongodb-data gng-minio-data"
echo ""
