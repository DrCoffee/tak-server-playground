#!/bin/bash
echo "=== TAK Server WAR Analysis ==="
cd /opt/tak
echo "WAR file size: $(ls -lh takserver.war)"
echo ""
echo "=== WAR Manifest ==="
unzip -q takserver.war META-INF/MANIFEST.MF -d /tmp/
cat /tmp/META-INF/MANIFEST.MF 2>/dev/null || echo "No manifest found"
echo ""
echo "=== Looking for Server classes ==="
jar tf takserver.war | grep -i "server" | grep -v "test" | head -10
echo ""
echo "=== Looking for Configuration classes ==="  
jar tf takserver.war | grep -i "config" | grep -v "test" | head -10