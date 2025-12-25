#!/bin/bash

# ============================================
# Christmas Tree 3D - Restart Script
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_DIR=$(dirname "$(readlink -f "$0")")
PORT=${PORT:-3000}  # Use PORT env var if set, otherwise default to 3000

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Stop PM2 process if running
stop_pm2() {
    print_status "Stopping existing PM2 process..."
    if command -v pm2 &> /dev/null; then
        pm2 delete christmas-tree-3d 2>/dev/null && print_success "PM2 process stopped" || print_warning "No PM2 process found"
    else
        print_warning "PM2 not installed, skipping PM2 stop"
    fi
}

# Stop dev server if running (check for vite process)
stop_dev_server() {
    print_status "Checking for running dev server..."
    VITE_PID=$(pgrep -f "vite.*dev" || true)
    if [ -n "$VITE_PID" ]; then
        print_status "Stopping dev server (PID: $VITE_PID)..."
        kill "$VITE_PID" 2>/dev/null || true
        print_success "Dev server stopped"
    else
        print_status "No dev server running"
    fi
}

# Rebuild the project
rebuild_project() {
    print_status "Rebuilding project..."
    cd "$APP_DIR"
    pnpm install
    pnpm run build
    print_success "Project rebuilt successfully"
}

# Check if port is available
check_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 1  # Port is in use
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            return 1  # Port is in use
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            return 1  # Port is in use
        fi
    fi
    return 0  # Port is available
}

# Find available port starting from given port
find_available_port() {
    local start_port=$1
    local port=$start_port
    local max_attempts=10
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            echo $port
            return 0
        fi
        port=$((port + 1))
        attempt=$((attempt + 1))
    done
    
    # If no port found, return original
    echo $start_port
    return 1
}

# Start with PM2 (preview mode)
start_with_pm2() {
    print_status "Starting application with PM2..."
    cd "$APP_DIR"
    
    if ! command -v pm2 &> /dev/null; then
        print_warning "PM2 not installed. Installing PM2..."
        npm install -g pm2
    fi
    
    # Check if port is available, find alternative if needed
    if ! check_port $PORT; then
        print_warning "Port $PORT is already in use. Finding alternative port..."
        AVAILABLE_PORT=$(find_available_port $PORT)
        if [ "$AVAILABLE_PORT" != "$PORT" ]; then
            print_status "Using port $AVAILABLE_PORT instead of $PORT"
            PORT=$AVAILABLE_PORT
        else
            print_error "Could not find available port. Port $PORT may be in use."
            print_status "You can set a custom port with: PORT=3001 ./restart.sh"
        fi
    else
        print_success "Port $PORT is available"
    fi
    
    # Stop existing instance if running
    pm2 delete christmas-tree-3d 2>/dev/null || true
    
    # Update ecosystem config with current port if it exists
    if [ -f "$APP_DIR/ecosystem.config.cjs" ]; then
        # Update port in ecosystem config
        sed -i "s/--port [0-9]*/--port $PORT/g" "$APP_DIR/ecosystem.config.cjs" 2>/dev/null || true
        pm2 start ecosystem.config.cjs
    elif [ -f "$APP_DIR/ecosystem.config.js" ]; then
        # Update port in ecosystem config
        sed -i "s/--port [0-9]*/--port $PORT/g" "$APP_DIR/ecosystem.config.js" 2>/dev/null || true
        pm2 start ecosystem.config.js
    else
        # Fallback: use direct command with proper format
        pm2 start pnpm --name christmas-tree-3d -- run preview -- --host 0.0.0.0 --port $PORT
    fi
    pm2 save
    
    print_success "Application started on port $PORT"
    print_status "Access at: http://localhost:$PORT"
    print_status "Check status with: pm2 list"
    print_status "View logs with: pm2 logs christmas-tree-3d"
}

# Start dev server
start_dev() {
    print_status "Starting development server..."
    cd "$APP_DIR"
    pnpm run dev -- --host 0.0.0.0 &
    print_success "Development server started"
}

# Main restart function
restart() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Christmas Tree 3D - Restart Script        ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    
    # Stop existing processes
    stop_pm2
    stop_dev_server
    
    echo ""
    
    # Rebuild project
    rebuild_project
    
    echo ""
    
    # Determine restart mode
    MODE="${1:-preview}"
    
    case "$MODE" in
        preview)
            start_with_pm2
            echo ""
            echo -e "${GREEN}Application restarted in preview mode${NC}"
            echo -e "View at: ${BLUE}http://localhost:$PORT${NC}"
            ;;
        dev)
            start_dev
            echo ""
            echo -e "${GREEN}Development server restarted${NC}"
            ;;
        *)
            print_error "Unknown mode: $MODE"
            echo "Usage: ./restart.sh [preview|dev]"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Restart Complete!                         ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
}

# Show help
show_help() {
    echo "Usage: ./restart.sh [MODE]"
    echo ""
    echo "Modes:"
    echo "  preview     Restart in preview mode with PM2 (default)"
    echo "  dev         Restart development server"
    echo "  help        Show this help message"
    echo ""
    echo "The script will:"
    echo "  1. Stop any running processes"
    echo "  2. Rebuild the project"
    echo "  3. Start the application in the specified mode"
}

# Parse command line arguments
case "${1:-preview}" in
    preview|dev)
        restart "$1"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

