#!/bin/bash
echo "=== Testing TAK Server Direct Startup ==="

# First, try starting without Spring profiles to see if the base class works
echo "Testing basic WAR startup..."
timeout 30 java -jar /opt/tak/takserver.war --server.port=8080 2>&1 | head -20

echo ""
echo "=== Testing with explicit classpath ==="
cd /opt/tak
export LOADER_PATH="WEB-INF/lib,WEB-INF/classes"
timeout 30 java -Dloader.path="$LOADER_PATH" -jar takserver.war --server.port=8080 2>&1 | head -20