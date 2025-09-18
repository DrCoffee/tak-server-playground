#!/usr/bin/env bash

set -e

TR=/opt/tak
CONFIG=${TR}/CoreConfig.xml

echo "=== TAK Server 5.2-RELEASE-16 Startup ==="
echo "Version: $(cat /opt/tak/scripts/../tak/version.txt 2>/dev/null || echo '5.2-RELEASE-16')"

cd ${TR}
. ./setenv.sh

echo "=== Checking WAR file structure ==="
java -jar takserver.war --version 2>/dev/null || echo "WAR version check failed"

echo "=== Starting TAK Server services in correct order ==="

# Try to start just the config service first to see the actual error
echo "Attempting to start Config service..."
java -jar -Xmx${CONFIG_MAX_HEAP}m -Dspring.profiles.active=config takserver.war 2>&1 | head -50