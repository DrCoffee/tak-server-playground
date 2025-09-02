#!/bin/bash

set -e

echo "TAK Server Complete Setup Script"
echo "================================"
echo ""
echo "This script will set up TAK Server from scratch."
echo "The process includes:"
echo "1. Installing system dependencies (Java 17, PostgreSQL, Git, Docker)"
echo "2. Cloning and building TAK Server"
echo "3. Setting up PostgreSQL database"
echo "4. Configuring TAK Server"
echo "5. Starting TAK Server services"
echo ""

# Make all scripts executable
chmod +x setup-dependencies.sh
chmod +x clone-and-build.sh
chmod +x setup-database.sh
chmod +x configure-server.sh
chmod +x start-server.sh

echo "Step 1: Installing dependencies..."
echo "=================================="
./setup-dependencies.sh

echo ""
echo "Step 2: Cloning and building TAK Server..."
echo "=========================================="
./clone-and-build.sh

echo ""
echo "Step 3: Setting up database..."
echo "=============================="
./setup-database.sh

echo ""
echo "Step 4: Configuring TAK Server..."
echo "=================================="
./configure-server.sh

echo ""
echo "Step 5: Starting TAK Server..."
echo "==============================="
./start-server.sh start

echo ""
echo "TAK Server setup complete!"
echo "=========================="
echo ""
echo "TAK Server is now running and accessible at:"
echo "  - Web UI: https://localhost:8443"
echo "  - Swagger API: https://localhost:8443/swagger-ui.html"
echo "  - Default credentials: admin/admin"
echo ""
echo "Client connections:"
echo "  - TLS (secure): port 8089"
echo "  - TCP (insecure): port 8087"
echo ""
echo "Management commands:"
echo "  - Check status: ./start-server.sh status"
echo "  - View logs: ./start-server.sh logs"
echo "  - Stop server: ./start-server.sh stop"
echo "  - Restart server: ./start-server.sh restart"
echo ""
echo "Important notes:"
echo "- Change default passwords before production use"
echo "- Configure firewall rules for client access"
echo "- Review TAK Server Configuration Guide for advanced settings"
echo "- Logs are stored in TAK-Server/src/takserver-core/logs/"