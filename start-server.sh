#!/bin/bash

set -e

echo "TAK Server Startup Script"
echo "========================="

# Configuration variables
TAK_DIR="TAK-Server"
SERVER_DIR="$TAK_DIR/src/takserver-core"
JAVA_OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.util.calendar=ALL-UNNAMED --add-opens=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED"

# Memory settings
CONFIG_MEMORY="512m"
MESSAGING_MEMORY="2048m"
API_MEMORY="1024m"

# Check if TAK Server is built
if [[ ! -d "$SERVER_DIR" ]]; then
    echo "TAK Server directory not found. Please run clone-and-build.sh first."
    exit 1
fi

# Find the JAR file
cd "$SERVER_DIR"
JAR_FILE=$(find . -name "takserver-core-*.war" | head -1)
if [[ -z "$JAR_FILE" ]]; then
    echo "TAK Server JAR file not found. Please run clone-and-build.sh first."
    exit 1
fi

echo "Found TAK Server JAR: $JAR_FILE"

# Create logs directory
mkdir -p logs

# Function to start a service
start_service() {
    local service_name=$1
    local profile=$2
    local memory=$3
    local port_check=$4
    
    echo ""
    echo "Starting $service_name service..."
    
    # Check if service is already running
    if [[ -n "$port_check" ]] && lsof -i :$port_check &> /dev/null; then
        echo "$service_name service appears to be already running on port $port_check"
        return 0
    fi
    
    # Start service in background
    nohup java -server -Xmx$memory $JAVA_OPTS \
        -Dspring.profiles.active=$profile,duplicatelogs \
        -Dlogging.level.com.bbn.marti=DEBUG \
        -jar "$JAR_FILE" > logs/$service_name.log 2>&1 &
    
    local pid=$!
    echo "$service_name service started with PID: $pid"
    echo "$pid" > logs/$service_name.pid
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if process is still running
    if kill -0 $pid 2>/dev/null; then
        echo "$service_name service is running successfully"
        if [[ -n "$port_check" ]]; then
            echo "Waiting for $service_name to bind to port $port_check..."
            for i in {1..30}; do
                if lsof -i :$port_check &> /dev/null; then
                    echo "$service_name is now listening on port $port_check"
                    break
                fi
                sleep 1
            done
        fi
    else
        echo "$service_name service failed to start. Check logs/$service_name.log for details."
        return 1
    fi
}

# Function to stop services
stop_services() {
    echo ""
    echo "Stopping TAK Server services..."
    
    for service in config messaging api; do
        if [[ -f "logs/$service.pid" ]]; then
            pid=$(cat logs/$service.pid)
            if kill -0 $pid 2>/dev/null; then
                echo "Stopping $service service (PID: $pid)..."
                kill $pid
                # Wait for graceful shutdown
                for i in {1..10}; do
                    if ! kill -0 $pid 2>/dev/null; then
                        break
                    fi
                    sleep 1
                done
                # Force kill if still running
                if kill -0 $pid 2>/dev/null; then
                    kill -9 $pid
                fi
            fi
            rm -f logs/$service.pid
        fi
    done
    
    echo "All services stopped."
}

# Function to show status
show_status() {
    echo ""
    echo "TAK Server Service Status:"
    echo "=========================="
    
    for service in config messaging api; do
        if [[ -f "logs/$service.pid" ]]; then
            pid=$(cat logs/$service.pid)
            if kill -0 $pid 2>/dev/null; then
                echo "$service: RUNNING (PID: $pid)"
            else
                echo "$service: STOPPED (stale PID file)"
                rm -f logs/$service.pid
            fi
        else
            echo "$service: STOPPED"
        fi
    done
    
    echo ""
    echo "Port Status:"
    echo "============"
    lsof -i :8443 &> /dev/null && echo "HTTPS API (8443): LISTENING" || echo "HTTPS API (8443): NOT LISTENING"
    lsof -i :8089 &> /dev/null && echo "TLS Input (8089): LISTENING" || echo "TLS Input (8089): NOT LISTENING" 
    lsof -i :8087 &> /dev/null && echo "TCP Input (8087): LISTENING" || echo "TCP Input (8087): NOT LISTENING"
}

# Parse command line arguments
case "${1:-start}" in
    start)
        echo "Starting TAK Server..."
        
        # Start Configuration service first
        start_service "config" "config" "$CONFIG_MEMORY"
        
        # Wait for config service to be ready
        sleep 5
        
        # Start Messaging service
        start_service "messaging" "messaging" "$MESSAGING_MEMORY" "8089"
        
        # Start API service
        start_service "api" "api" "$API_MEMORY" "8443"
        
        echo ""
        echo "TAK Server startup complete!"
        echo ""
        echo "Services:"
        echo "  - Configuration: Running"
        echo "  - Messaging: Running on port 8089 (TLS), 8087 (TCP)"
        echo "  - API: Running on port 8443 (HTTPS)"
        echo ""
        echo "Access points:"
        echo "  - Web UI: https://localhost:8443"
        echo "  - Swagger API: https://localhost:8443/swagger-ui.html"
        echo "  - Default credentials: admin/admin"
        echo ""
        echo "Logs are available in the logs/ directory"
        echo ""
        echo "To stop the server: $0 stop"
        echo "To check status: $0 status"
        ;;
        
    stop)
        stop_services
        ;;
        
    restart)
        stop_services
        sleep 2
        $0 start
        ;;
        
    status)
        show_status
        ;;
        
    logs)
        service=${2:-messaging}
        if [[ -f "logs/$service.log" ]]; then
            tail -f "logs/$service.log"
        else
            echo "Log file logs/$service.log not found"
            echo "Available logs:"
            ls -la logs/
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop|restart|status|logs [service]}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all TAK Server services"
        echo "  stop    - Stop all TAK Server services"
        echo "  restart - Restart all TAK Server services"
        echo "  status  - Show service status"
        echo "  logs    - Follow logs for a service (default: messaging)"
        echo ""
        echo "Available services for logs: config, messaging, api"
        exit 1
        ;;
esac