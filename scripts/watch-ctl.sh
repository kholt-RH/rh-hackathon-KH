#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$ROOT_DIR/.watch-code.pid"
LOG_FILE="$ROOT_DIR/.watch-code.log"

case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo -e "${YELLOW}Watcher is already running (PID: $(cat $PID_FILE))${NC}"
            exit 0
        fi

        NAMESPACE="${2:-$(oc project -q 2>/dev/null)}"
        if [ -z "$NAMESPACE" ]; then
            echo -e "${RED}Error: No namespace specified${NC}"
            echo "Usage: $0 start <namespace>"
            exit 1
        fi

        echo -e "${CYAN}Starting code watcher for namespace: ${NAMESPACE}${NC}"
        nohup "$SCRIPT_DIR/watch-code.sh" --namespace "$NAMESPACE" > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo -e "${GREEN}✓ Watcher started (PID: $(cat $PID_FILE))${NC}"
        echo -e "${CYAN}Logs: tail -f $LOG_FILE${NC}"
        ;;

    stop)
        if [ ! -f "$PID_FILE" ]; then
            echo -e "${YELLOW}Watcher is not running${NC}"
            exit 0
        fi

        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f "$PID_FILE"
            echo -e "${GREEN}✓ Watcher stopped${NC}"
        else
            echo -e "${YELLOW}Watcher was not running (stale PID file removed)${NC}"
            rm -f "$PID_FILE"
        fi
        ;;

    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            PID=$(cat "$PID_FILE")
            echo -e "${GREEN}✓ Watcher is running (PID: $PID)${NC}"
            echo -e "${CYAN}Logs: $LOG_FILE${NC}"

            # Show namespace if we can detect it
            NAMESPACE=$(oc project -q 2>/dev/null)
            if [ -n "$NAMESPACE" ]; then
                echo -e "${CYAN}Namespace: $NAMESPACE${NC}"
            fi
        else
            echo -e "${YELLOW}Watcher is not running${NC}"
            if [ -f "$PID_FILE" ]; then
                rm -f "$PID_FILE"
            fi
        fi
        ;;

    logs)
        if [ ! -f "$LOG_FILE" ]; then
            echo -e "${YELLOW}No logs found${NC}"
            exit 0
        fi

        tail -f "$LOG_FILE"
        ;;

    restart)
        $0 stop
        sleep 2
        $0 start "$2"
        ;;

    *)
        echo "Usage: $0 {start|stop|status|logs|restart} [namespace]"
        echo ""
        echo "Examples:"
        echo "  $0 start gng-admin    # Start watcher for namespace"
        echo "  $0 status             # Check if running"
        echo "  $0 logs               # View logs"
        echo "  $0 stop               # Stop watcher"
        echo "  $0 restart gng-admin  # Restart watcher"
        exit 1
        ;;
esac
