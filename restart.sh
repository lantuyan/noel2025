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
PORT=3000

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

# Start with PM2 (preview mode)
start_with_pm2() {
    print_status "Starting application with PM2..."
    cd "$APP_DIR"
    
    if ! command -v pm2 &> /dev/null; then
        print_warning "PM2 not installed. Installing PM2..."
        npm install -g pm2
    fi
    
    pm2 start "pnpm run preview -- --host 0.0.0.0 --port $PORT" --name christmas-tree-3d
    pm2 save
    
    print_success "Application started on port $PORT"
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

