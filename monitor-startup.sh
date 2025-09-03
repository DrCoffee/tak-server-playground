#!/bin/bash

set -e

echo "TAK Server Startup Monitor"
echo "=========================="
echo ""

if ! docker ps --format '{{.Names}}' | grep -q "^tak-server$"; then
    echo "TAK Server container is not running. Please start it first:"
    echo "  ./docker-run.sh start"
    exit 1
fi

echo "Monitoring TAK Server startup progress..."
echo "This may take 5-15 minutes for initial startup."
echo ""

start_time=$(date +%s)

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    elapsed_min=$((elapsed / 60))
    elapsed_sec=$((elapsed % 60))
    
    echo "== Status at ${elapsed_min}m ${elapsed_sec}s =="
    
    # Check if processes are running
    config_running=$(docker exec tak-server pgrep -f "spring.profiles.active=config" &>/dev/null && echo "✓" || echo "✗")
    messaging_running=$(docker exec tak-server pgrep -f "spring.profiles.active=messaging" &>/dev/null && echo "✓" || echo "✗")
    api_running=$(docker exec tak-server pgrep -f "spring.profiles.active=api" &>/dev/null && echo "✓" || echo "✗")
    
    # Check if ports are bound
    messaging_port=$(timeout 5 docker exec tak-server lsof -i :8087 &>/dev/null && echo "✓" || echo "✗")
    api_port=$(timeout 5 docker exec tak-server lsof -i :8080 &>/dev/null && echo "✓" || echo "✗")
    
    echo "Processes: Config[$config_running] Messaging[$messaging_running] API[$api_running]"
    echo "Ports:     Messaging:8087[$messaging_port] API:8080[$api_port]"
    
    # Check if fully ready
    if [[ "$messaging_port" == "✓" ]] && [[ "$api_port" == "✓" ]]; then
        echo ""
        echo "🎉 TAK Server is fully ready!"
        echo ""
        echo "Access points:"
        echo "  - Web UI: http://localhost:8080"
        echo "  - Swagger API: http://localhost:8080/swagger-ui.html"
        echo "  - Default credentials: admin/admin"
        echo ""
        echo "Client connections:"
        echo "  - TCP: localhost:8087"
        break
    fi
    
    # Show progress if at least one service is bound
    if [[ "$messaging_port" == "✓" ]] || [[ "$api_port" == "✓" ]]; then
        echo "Progress: Services are binding to ports..."
    elif [[ "$config_running" == "✓" ]] && [[ "$messaging_running" == "✓" ]] && [[ "$api_running" == "✓" ]]; then
        echo "Progress: All services running, waiting for port binding..."
    else
        echo "Progress: Services still starting..."
    fi
    
    # Timeout after 20 minutes
    if [[ $elapsed -gt 1200 ]]; then
        echo ""
        echo "⚠️  Timeout after 20 minutes. Services may need more time."
        echo "Check logs manually:"
        echo "  ./docker-run.sh logs messaging"
        echo "  ./docker-run.sh logs api"
        break
    fi
    
    echo ""
    sleep 30
done