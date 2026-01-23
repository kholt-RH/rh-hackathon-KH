#!/bin/bash

# Continuous backend sync - syncs on file changes + periodic timer
# For maximum responsiveness during development

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

set -e

# Parse arguments
NAMESPACE=""
BACKEND_DIR=""
INTERVAL=2  # Sync every 2 seconds by default

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAME    Target namespace (auto-detect from .openshift-config)"
    echo "  -d, --dir PATH          Backend directory (default: ../gng-backend)"
    echo "  -i, --interval SECONDS  Sync interval in seconds (default: 2)"
    echo "  -h, --help              Show this help"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--dir)
            BACKEND_DIR="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Auto-detect namespace from config if not provided
if [ -z "$NAMESPACE" ]; then
    if [ -f "$ROOT_DIR/.openshift-config" ]; then
        NAMESPACE=$(grep '^NAMESPACE=' "$ROOT_DIR/.openshift-config" | cut -d= -f2)
    fi

    if [ -z "$NAMESPACE" ]; then
        NAMESPACE=$(oc project -q 2>/dev/null || echo "")
    fi

    if [ -z "$NAMESPACE" ]; then
        echo -e "${YELLOW}No namespace found. Use -n <namespace>${NC}"
        exit 1
    fi
fi

# Set backend directory
if [ -z "$BACKEND_DIR" ]; then
    BACKEND_DIR="$ROOT_DIR/gng-backend"
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${CYAN}Cloning backend repository...${NC}"
        git clone https://github.com/griot-and-grits/gng-backend.git "$BACKEND_DIR"
    fi
fi

if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${YELLOW}Backend directory not found: $BACKEND_DIR${NC}"
    exit 1
fi

echo -e "${CYAN}${BOLD}=== Continuous Backend Sync ===${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Directory: ${BACKEND_DIR}${NC}"
echo -e "${DIM}Interval:  ${INTERVAL}s${NC}"
echo ""

# Function to sync backend
sync_backend() {
    BACKEND_POD=$(oc get pod -l app=backend -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$BACKEND_POD" ]; then
        # Use --delete flag to remove files that were deleted locally
        oc rsync "$BACKEND_DIR/" "$BACKEND_POD:/tmp/app" -n "$NAMESPACE" \
            --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
            --exclude='node_modules' --exclude='.venv' --no-perms \
            --delete 2>/dev/null && \
        echo -e "${MAGENTA}[$(date +%H:%M:%S)]${NC} ${GREEN}✓${NC} Synced" || \
        echo -e "${MAGENTA}[$(date +%H:%M:%S)]${NC} ${YELLOW}⚠${NC} Sync failed"
    else
        echo -e "${MAGENTA}[$(date +%H:%M:%S)]${NC} ${YELLOW}⚠${NC} Backend pod not found"
    fi
}

# Initial sync
echo -e "${CYAN}Performing initial sync...${NC}"
sync_backend
echo ""

echo -e "${GREEN}${BOLD}🔄 Continuous sync active (${INTERVAL}s interval)${NC}"
echo -e "${DIM}Changes sync immediately + periodic sync every ${INTERVAL}s${NC}"
echo -e "${DIM}Press Ctrl+C to stop${NC}"
echo ""

# Track last sync time to avoid duplicate syncs
LAST_SYNC=0

# Sync function with debounce
do_sync() {
    NOW=$(date +%s)
    # Only sync if at least 0.5 seconds have passed since last sync
    if [ $((NOW - LAST_SYNC)) -ge 1 ]; then
        sync_backend
        LAST_SYNC=$(date +%s)
    fi
}

# Background periodic sync
(
    while true; do
        sleep "$INTERVAL"
        do_sync
    done
) &
PERIODIC_PID=$!

# Cleanup on exit
trap "kill $PERIODIC_PID 2>/dev/null; exit 0" INT TERM EXIT

# Detect OS and use appropriate file watcher
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - use fswatch
    if ! command -v fswatch &> /dev/null; then
        echo -e "${YELLOW}Installing fswatch via Homebrew...${NC}"
        brew install fswatch
    fi

    # Watch for changes
    fswatch -o -r -l 0.5 \
        --exclude='\.git' --exclude='__pycache__' --exclude='\.pyc$' \
        --exclude='node_modules' --exclude='\.venv' \
        "$BACKEND_DIR" | while read change; do
        do_sync
    done
else
    # Linux - use inotifywait
    if ! command -v inotifywait &> /dev/null; then
        echo -e "${YELLOW}inotifywait not found. Install: sudo apt install inotify-tools${NC}"
        exit 1
    fi

    # Watch for changes
    inotifywait -m -r -e modify,create,delete,move \
        --exclude '(\.git|__pycache__|\.pyc$|node_modules|\.venv)' \
        "$BACKEND_DIR" 2>/dev/null | while read path action file; do
        do_sync
    done
fi
