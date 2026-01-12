#!/bin/bash
# Griot & Grits - Run Frontend with Hot Reload

set -e

FRONTEND_DIR="${FRONTEND_DIR:-$HOME/gng-web}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

if [ ! -d "$FRONTEND_DIR" ]; then
    print_error "Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

# Check for node_modules
if [ ! -d "node_modules" ]; then
    print_error "Dependencies not installed. Run setup.sh first."
    exit 1
fi

print_status "Starting frontend server with hot reload (Turbopack)..."
echo "  Directory: $FRONTEND_DIR"
echo "  URL: http://localhost:3000"
echo "  Admin: http://localhost:3000/admin"
echo ""

npm run dev
