#!/bin/bash
# Griot & Grits - Check Status of All Services

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_running() { echo -e "  ${GREEN}[RUNNING]${NC} $1"; }
print_stopped() { echo -e "  ${RED}[STOPPED]${NC} $1"; }
print_status() { echo -e "${BLUE}[*]${NC} $1"; }

# Container names
MONGO_CONTAINER="gng-mongodb"
MINIO_CONTAINER="gng-minio"

echo ""
echo "=========================================="
echo "  Griot & Grits - Service Status"
echo "=========================================="
echo ""

# Infrastructure Services
print_status "Infrastructure Services:"

if docker ps --format '{{.Names}}' | grep -q "^${MONGO_CONTAINER}$"; then
    print_running "MongoDB     → mongodb://localhost:27017"
else
    print_stopped "MongoDB"
fi

if docker ps --format '{{.Names}}' | grep -q "^${MINIO_CONTAINER}$"; then
    print_running "MinIO       → http://localhost:9000 (console: 9001)"
else
    print_stopped "MinIO"
fi

echo ""

# Application Services
print_status "Application Services:"

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    print_running "Backend     → http://localhost:8000"
else
    print_stopped "Backend"
fi

# Check if frontend is running
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    print_running "Frontend    → http://localhost:3000"
else
    print_stopped "Frontend"
fi

echo ""

# Docker volumes
print_status "Data Volumes:"
if docker volume ls --format '{{.Name}}' | grep -q "gng-mongodb-data"; then
    echo "  - gng-mongodb-data (MongoDB)"
fi
if docker volume ls --format '{{.Name}}' | grep -q "gng-minio-data"; then
    echo "  - gng-minio-data (MinIO)"
fi

echo ""
