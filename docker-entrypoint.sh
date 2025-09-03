#!/bin/bash

set -e

echo "Starting TAK Server Docker Container"
echo "===================================="

# Environment variables with defaults
TAK_USER=${TAK_USER:-tak}
TAK_DB=${TAK_DB:-cot}
TAK_PASSWORD=${TAK_PASSWORD:-tak123}
POSTGRES_VERSION=${POSTGRES_VERSION:-14}

# Configuration paths
TAK_HOME="/opt/takserver/tak-server/src/takserver-core"
JAR_FILE=$(find /opt/takserver/tak-server/src -name "takserver-core-*.jar" | head -1)

cd "$TAK_HOME"

# Function to start PostgreSQL
start_postgresql() {
    echo "Starting PostgreSQL..."
    
    # Ensure PostgreSQL data directory has correct permissions
    chown -R postgres:postgres /var/lib/postgresql
    
    # Start PostgreSQL
    sudo -u postgres /usr/lib/postgresql/$POSTGRES_VERSION/bin/postgres \
        -D /var/lib/postgresql/$POSTGRES_VERSION/main \
        -c config_file=/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf &
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to start..."
    for i in {1..30}; do
        if sudo -u postgres pg_isready -q; then
            echo "PostgreSQL is ready"
            break
        fi
        sleep 1
    done
    
    if ! sudo -u postgres pg_isready -q; then
        echo "PostgreSQL failed to start"
        exit 1
    fi
    
    # Initialize database if needed
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $TAK_DB; then
        echo "Initializing TAK database..."
        sudo -u postgres createdb -O $TAK_USER $TAK_DB
        sudo -u postgres psql -d $TAK_DB -c "CREATE EXTENSION IF NOT EXISTS postgis;"
    fi
}

# Function to start TAK Server service
start_tak_service() {
    local service_name=$1
    local profile=$2
    local memory=$3
    
    echo "Starting TAK Server $service_name service..."
    
    java -server -Xmx$memory $JDK_JAVA_OPTIONS \
        -Dfile.encoding=UTF-8 \
        -Dspring.profiles.active=$profile,duplicatelogs \
        -Dlogging.level.com.bbn.marti=INFO \
        -jar "$JAR_FILE" > logs/$service_name.log 2>&1 &
    
    local pid=$!
    echo "$service_name service started with PID: $pid"
    echo "$pid" > logs/$service_name.pid
    
    return 0
}

# Function to wait for service
wait_for_port() {
    local port=$1
    local service=$2
    local timeout=${3:-300}  # Increased timeout to 5 minutes for TAK Server
    
    echo "Waiting for $service to be ready on port $port (timeout: ${timeout}s)..."
    for i in $(seq 1 $timeout); do
        if timeout 5 lsof -i :$port &> /dev/null; then
            echo "$service is ready on port $port"
            return 0
        fi
        if [ $((i % 30)) -eq 0 ]; then
            echo "Still waiting for $service... (${i}/${timeout}s elapsed)"
        fi
        sleep 1
    done
    
    echo "Warning: Timeout waiting for $service on port $port after ${timeout}s"
    echo "Service may still be starting up. Check logs: docker exec <container> tail -f logs/$service.log"
    return 1
}

# Function to monitor services
monitor_services() {
    while true; do
        # Check PostgreSQL
        if ! sudo -u postgres pg_isready -q; then
            echo "PostgreSQL is down, restarting..."
            start_postgresql
        fi
        
        # Check TAK services
        for service in config messaging api; do
            if [[ -f "logs/$service.pid" ]]; then
                pid=$(cat logs/$service.pid)
                if ! kill -0 $pid 2>/dev/null; then
                    echo "$service service is down, restarting..."
                    case $service in
                        config)
                            start_tak_service "config" "config" "512m"
                            ;;
                        messaging)
                            start_tak_service "messaging" "messaging" "2048m"
                            wait_for_port 8087 "messaging"
                            ;;
                        api)
                            start_tak_service "api" "api" "1024m"
                            wait_for_port 8080 "api"
                            ;;
                    esac
                fi
            fi
        done
        
        sleep 30
    done
}

# Trap signals for graceful shutdown
cleanup() {
    echo "Shutting down services..."
    
    # Stop TAK services
    for service in api messaging config; do
        if [[ -f "logs/$service.pid" ]]; then
            pid=$(cat logs/$service.pid)
            if kill -0 $pid 2>/dev/null; then
                echo "Stopping $service service..."
                kill $pid
                wait $pid 2>/dev/null || true
            fi
            rm -f logs/$service.pid
        fi
    done
    
    # Stop PostgreSQL
    echo "Stopping PostgreSQL..."
    sudo -u postgres pg_ctl stop -D /var/lib/postgresql/$POSTGRES_VERSION/main -m fast || true
    
    exit 0
}

trap cleanup SIGTERM SIGINT

# Create logs directory
mkdir -p logs

# Start PostgreSQL
start_postgresql

# Wait a moment for PostgreSQL to fully initialize
sleep 3

# Start TAK Server services in order
start_tak_service "config" "config" "512m"
sleep 10  # Give config service more time to initialize

start_tak_service "messaging" "messaging" "2048m"
# Don't block on messaging port - let it start in background
echo "Messaging service started. Waiting briefly before starting API service..."
sleep 20

start_tak_service "api" "api" "1024m"

# Wait for services with timeout but don't fail the container startup
echo ""
echo "Services started. Checking readiness (this may take several minutes)..."
wait_for_port 8087 "messaging" 300 || echo "Messaging service still starting..."
wait_for_port 8080 "api" 300 || echo "API service still starting..."

echo ""
echo "TAK Server container startup complete!"
echo "======================================"
echo ""
echo "Services running:"
echo "  - PostgreSQL: localhost:5432"
echo "  - TAK Configuration: Running"
echo "  - TAK Messaging: localhost:8087 (TCP)"
echo "  - TAK API: http://localhost:8080"
echo ""
echo "Access points:"
echo "  - Web UI: http://localhost:8080"
echo "  - Swagger API: http://localhost:8080/swagger-ui.html"
echo "  - Default credentials: admin/admin"
echo ""
echo "Database connection:"
echo "  - Host: localhost"
echo "  - Port: 5432"
echo "  - Database: $TAK_DB"
echo "  - User: $TAK_USER"
echo "  - Password: $TAK_PASSWORD"

# Start monitoring in the background and wait
monitor_services &
monitor_pid=$!

# Wait for monitor process
wait $monitor_pid