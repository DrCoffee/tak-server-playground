#!/bin/bash

# TAK Server Container Management Script
# This script helps start, stop, and manage TAK server containers

set -e

# Configuration
COMPOSE_DIR="../cloud-rf-tak-server"
COMPOSE_FILE="docker-compose.yml"
COMPOSE_ARM_FILE="docker-compose.arm.yml"
ENV_FILE=".env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker-compose directory exists
check_compose_dir() {
    if [[ ! -d "$COMPOSE_DIR" ]]; then
        print_error "Docker compose directory not found: $COMPOSE_DIR"
        print_info "Please ensure the cloud-rf-tak-server directory exists"
        exit 1
    fi
}

# Detect architecture and set appropriate compose file
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        aarch64|arm64)
            COMPOSE_FILE="$COMPOSE_ARM_FILE"
            print_info "ARM architecture detected, using $COMPOSE_FILE"
            ;;
        x86_64|amd64)
            COMPOSE_FILE="docker-compose.yml"
            print_info "x86_64 architecture detected, using $COMPOSE_FILE"
            ;;
        *)
            print_warning "Unknown architecture: $arch, defaulting to x86_64"
            COMPOSE_FILE="docker-compose.yml"
            ;;
    esac
}

# Check if required files exist
check_requirements() {
    cd "$COMPOSE_DIR"
    
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        print_error "Docker compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    if [[ ! -f "$ENV_FILE" ]]; then
        print_warning "Environment file not found: $ENV_FILE"
        print_info "You may need to create a .env file with required variables"
    fi
    
    cd - > /dev/null
}

# Start TAK server containers
start_server() {
    print_info "Starting TAK server containers..."
    cd "$COMPOSE_DIR"
    
    print_info "Building and starting containers with $COMPOSE_FILE"
    docker compose -f "$COMPOSE_FILE" up -d --build
    
    print_success "TAK server containers started"
    print_info "Database will be available on internal network"
    print_info "TAK server will be available on:"
    print_info "  - HTTPS Web UI: https://localhost:8443"
    print_info "  - HTTPS API: https://localhost:8444"
    print_info "  - CoT TCP: localhost:8089"
    print_info "  - Federation: localhost:9000, 9001"
    
    cd - > /dev/null
}

# Stop TAK server containers (preserves containers and data)
stop_server() {
    print_info "Stopping TAK server containers (preserving data)..."
    cd "$COMPOSE_DIR"
    
    docker compose -f "$COMPOSE_FILE" stop
    
    print_success "TAK server containers stopped (containers preserved)"
    print_info "Use 'start' to resume or 'cleanup' to remove containers"
    cd - > /dev/null
}

# Remove TAK server containers (more destructive than stop)
remove_containers() {
    print_info "Removing TAK server containers..."
    cd "$COMPOSE_DIR"
    
    docker compose -f "$COMPOSE_FILE" down
    
    print_success "TAK server containers removed"
    cd - > /dev/null
}

# Restart TAK server containers
restart_server() {
    print_info "Restarting TAK server containers..."
    stop_server
    start_server
}

# Show container status
show_status() {
    print_info "TAK server container status:"
    cd "$COMPOSE_DIR"
    
    docker compose -f "$COMPOSE_FILE" ps -a
    
    cd - > /dev/null
}

# Show container logs
show_logs() {
    local service=${1:-}
    cd "$COMPOSE_DIR"
    
    if [[ -n "$service" ]]; then
        print_info "Showing logs for service: $service"
        docker compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        print_info "Showing logs for all services (use Ctrl+C to exit)"
        docker compose -f "$COMPOSE_FILE" logs -f
    fi
    
    cd - > /dev/null
}

# Clean up containers and volumes (most destructive)
cleanup() {
    print_warning "This will remove all TAK server containers, volumes, and data!"
    print_warning "This is DESTRUCTIVE and will delete all database data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning up TAK server containers, volumes, and data..."
        cd "$COMPOSE_DIR"
        
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
        docker system prune -f
        
        print_success "Complete cleanup completed (all data removed)"
        cd - > /dev/null
    else
        print_info "Cleanup cancelled"
    fi
}

# Test connectivity to TAK server
test_connection() {
    print_info "Testing connectivity to TAK server..."
    
    # Test if containers are running
    cd "$COMPOSE_DIR"
    if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q .; then
        print_error "No TAK server containers are running"
        cd - > /dev/null
        return 1
    fi
    cd - > /dev/null
    
    # Test TCP connection to CoT port
    print_info "Testing TCP connection to localhost:8089..."
    if timeout 5 bash -c '</dev/tcp/localhost/8089' 2>/dev/null; then
        print_success "TCP connection to port 8089 successful"
    else
        print_warning "TCP connection to port 8089 failed (may still be starting)"
    fi
    
    # Test HTTPS connection
    print_info "Testing HTTPS connection to localhost:8443..."
    if timeout 5 curl -k -s https://localhost:8443 >/dev/null 2>&1; then
        print_success "HTTPS connection to port 8443 successful"
    else
        print_warning "HTTPS connection to port 8443 failed (may still be starting)"
    fi
}

# Show usage information
show_usage() {
    echo "TAK Server Container Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start       Start TAK server containers"
    echo "  stop        Stop TAK server containers (preserves data)"
    echo "  restart     Restart TAK server containers"
    echo "  remove      Remove containers (but preserve volumes)"
    echo "  status      Show container status"
    echo "  logs [svc]  Show logs (optionally for specific service: tak, db)"
    echo "  test        Test connectivity to TAK server"
    echo "  cleanup     Remove containers and volumes (DESTRUCTIVE)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                 # Start TAK server"
    echo "  $0 logs                  # Show all logs"
    echo "  $0 logs tak             # Show only TAK server logs"
    echo "  $0 logs db              # Show only database logs"
    echo "  $0 test                 # Test connectivity"
}

# Main script logic
main() {
    local command=${1:-help}
    
    case $command in
        start)
            check_compose_dir
            detect_architecture
            check_requirements
            start_server
            ;;
        stop)
            check_compose_dir
            detect_architecture
            stop_server
            ;;
        restart)
            check_compose_dir
            detect_architecture
            check_requirements
            restart_server
            ;;
        remove)
            check_compose_dir
            detect_architecture
            remove_containers
            ;;
        status)
            check_compose_dir
            detect_architecture
            show_status
            ;;
        logs)
            check_compose_dir
            detect_architecture
            show_logs "$2"
            ;;
        test)
            test_connection
            ;;
        cleanup)
            check_compose_dir
            detect_architecture
            cleanup
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"