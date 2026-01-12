#!/bin/bash
# Griot & Grits - Start Everything for Development
# Runs services, backend, and frontend in parallel

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }

echo ""
echo "=========================================="
echo "  Griot & Grits - Full Development Stack"
echo "=========================================="
echo ""

# Start infrastructure services
print_status "Starting infrastructure services..."
"$SCRIPT_DIR/start-services.sh"

echo ""
print_status "Starting backend and frontend..."
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    print_status "Shutting down..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    "$SCRIPT_DIR/stop-services.sh"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start backend in background
"$SCRIPT_DIR/dev-backend.sh" &
BACKEND_PID=$!

# Give backend a moment to start
sleep 2

# Start frontend in background
"$SCRIPT_DIR/dev-frontend.sh" &
FRONTEND_PID=$!

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
