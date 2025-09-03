#!/bin/bash

set -e

echo "TAK Server Docker Runtime Script"
echo "================================"

# Configuration
IMAGE_NAME="tak-server"
TAG="latest"
CONTAINER_NAME="tak-server"

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        echo "Docker is not running or not accessible."
        echo "Please make sure Docker is installed and running."
        exit 1
    fi
}

# Function to check if image exists
check_image() {
    if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}:${TAG}$"; then
        echo "Docker image ${IMAGE_NAME}:${TAG} not found."
        echo "Please run: ./docker-build.sh build"
        exit 1
    fi
}

# Function to start container
start_container() {
    echo ""
    echo "Starting TAK Server container..."
    
    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container already exists. Starting existing container..."
        docker start ${CONTAINER_NAME}
    else
        echo "Creating and starting new container..."
        docker run -d \
            --name ${CONTAINER_NAME} \
            -p 8080:8080 \
            -p 8087:8087 \
            -p 5432:5432 \
            -v tak_data:/opt/takserver/tak-server/src/takserver-core/files \
            -v tak_logs:/opt/takserver/tak-server/src/takserver-core/logs \
            -v postgres_data:/var/lib/postgresql/14/main \
            --restart unless-stopped \
            ${IMAGE_NAME}:${TAG}
    fi
    
    echo ""
    echo "Container started successfully!"
    
    # Wait for services to be ready
    echo "Waiting for services to start up (this may take 1-2 minutes)..."
    
    # Wait for API to be ready
    for i in {1..120}; do
        if docker exec ${CONTAINER_NAME} lsof -i :8080 &> /dev/null; then
            echo "TAK Server API is ready!"
            break
        fi
        sleep 1
        if [[ $i -eq 120 ]]; then
            echo "Timeout waiting for TAK Server to start. Check logs."
        fi
    done
    
    show_status
}

# Function to stop container
stop_container() {
    echo ""
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Stopping TAK Server container..."
        docker stop ${CONTAINER_NAME}
        echo "Container stopped."
    else
        echo "Container is not running."
    fi
}

# Function to show container status
show_status() {
    echo ""
    echo "TAK Server Container Status:"
    echo "============================"
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Status: RUNNING"
        
        # Show port mappings
        echo ""
        echo "Port Mappings:"
        docker port ${CONTAINER_NAME} 2>/dev/null || echo "No port mappings found"
        
        # Check service health
        echo ""
        echo "Service Health:"
        echo "==============="
        
        # Check API with timeout
        if timeout 5 docker exec ${CONTAINER_NAME} lsof -i :8080 &> /dev/null; then
            echo "HTTP API (8080): RUNNING"
        elif timeout 2 docker exec ${CONTAINER_NAME} pgrep -f "spring.profiles.active=api" &> /dev/null; then
            echo "HTTP API (8080): STARTING (service running, port not bound yet)"
        else
            echo "HTTP API (8080): NOT RUNNING"
        fi
        
        # Check TCP Input with timeout
        if timeout 5 docker exec ${CONTAINER_NAME} lsof -i :8087 &> /dev/null; then
            echo "TCP Input (8087): RUNNING"
        elif timeout 2 docker exec ${CONTAINER_NAME} pgrep -f "spring.profiles.active=messaging" &> /dev/null; then
            echo "TCP Input (8087): STARTING (service running, port not bound yet)"
        else
            echo "TCP Input (8087): NOT RUNNING"
        fi
        
        # Check PostgreSQL
        if docker exec ${CONTAINER_NAME} sudo -u postgres pg_isready -q &> /dev/null; then
            echo "PostgreSQL (5432): RUNNING"
        else
            echo "PostgreSQL (5432): NOT RUNNING"
        fi
        
        echo ""
        echo "Access Information:"
        echo "=================="
        echo "Web UI: http://localhost:8080"
        echo "Swagger API: http://localhost:8080/swagger-ui.html"
        echo "Default credentials: admin/admin"
        echo ""
        echo "Client Connections:"
        echo "TCP: localhost:8087"
        echo ""
        echo "Database Access:"
        echo "Host: localhost:5432"
        echo "Database: cot"
        echo "User: tak"
        echo "Password: tak123"
        
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Status: STOPPED"
        echo "Run '$0 start' to start the container."
    else
        echo "Status: NOT CREATED"
        echo "Run '$0 start' to create and start the container."
    fi
}

# Function to show logs
show_logs() {
    local service=${1:-container}
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container does not exist."
        exit 1
    fi
    
    case $service in
        container|all)
            echo "Showing container logs (Ctrl+C to exit)..."
            docker logs -f ${CONTAINER_NAME}
            ;;
        api|messaging|config)
            echo "Showing $service service logs (Ctrl+C to exit)..."
            docker exec ${CONTAINER_NAME} tail -f /opt/takserver/tak-server/src/takserver-core/logs/$service.log
            ;;
        postgres|postgresql)
            echo "Showing PostgreSQL logs (Ctrl+C to exit)..."
            docker exec ${CONTAINER_NAME} tail -f /var/log/postgresql/postgresql.log
            ;;
        *)
            echo "Unknown log type: $service"
            echo "Available logs: container, api, messaging, config, postgres"
            exit 1
            ;;
    esac
}

# Function to open shell in container
shell() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container is not running."
        exit 1
    fi
    
    echo "Opening shell in TAK Server container..."
    docker exec -it ${CONTAINER_NAME} /bin/bash
}

# Parse command line arguments
case "${1:-status}" in
    start)
        check_docker
        check_image
        start_container
        ;;
        
    stop)
        check_docker
        stop_container
        ;;
        
    restart)
        check_docker
        stop_container
        sleep 2
        start_container
        ;;
        
    status)
        check_docker
        show_status
        ;;
        
    logs)
        check_docker
        show_logs ${2:-container}
        ;;
        
    shell)
        check_docker
        shell
        ;;
        
    remove)
        check_docker
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            stop_container
        fi
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "Removing container..."
            docker rm ${CONTAINER_NAME}
            echo "Container removed."
        else
            echo "Container does not exist."
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|shell|remove}"
        echo ""
        echo "Commands:"
        echo "  start          - Start the TAK Server container"
        echo "  stop           - Stop the TAK Server container"
        echo "  restart        - Restart the TAK Server container"
        echo "  status         - Show container and service status"
        echo "  logs [service] - Show logs (container, api, messaging, config, postgres)"
        echo "  shell          - Open shell in container"
        echo "  remove         - Stop and remove the container"
        exit 1
        ;;
esac