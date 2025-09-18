#!/bin/sh
if [ $# -eq 0 ]
  then
    ps -ef | grep takserver | grep -v grep | awk '{print $2}' | xargs kill
fi

cd /opt/tak
. ./setenv.sh

echo "=== Checking available files ==="
ls -la *.war *.jar 2>/dev/null || echo "No WAR or JAR files found"

# Check if files exist before starting services
if [ -f "takserver.war" ]; then
  echo "Starting TAK Server Config service..."
  java -jar -Xmx${CONFIG_MAX_HEAP}m -Dspring.profiles.active=config takserver.war &
  sleep 5
  
  echo "Starting TAK Server Messaging service..."  
  java -jar -Xmx${MESSAGING_MAX_HEAP}m -Dspring.profiles.active=messaging takserver.war &
  sleep 5
  
  echo "Starting TAK Server API service..."
  java -jar -Xmx${API_MAX_HEAP}m -Dspring.profiles.active=api -Dkeystore.pkcs12.legacy takserver.war &
  sleep 5
else
  echo "ERROR: takserver.war not found!"
  ls -la /opt/tak/
  exit 1
fi

if [ -f "takserver-retention.jar" ]; then
  echo "Starting TAK Server Retention service..."
  java -jar -Xmx${RETENTION_MAX_HEAP}m takserver-retention.jar &
else
  echo "WARNING: takserver-retention.jar not found, skipping retention service"
fi

if [ -f "takserver-pm.jar" ]; then
  echo "Starting TAK Server Plugin Manager..."
  java -jar -Xmx${PLUGIN_MANAGER_MAX_HEAP}m -Dloader.path=WEB-INF/lib-provided,WEB-INF/lib,WEB-INF/classes,file:lib/ takserver-pm.jar &
else
  echo "WARNING: takserver-pm.jar not found, skipping plugin manager"
fi

if ! [ $# -eq 0 ]
  then
    tail -f /dev/null
fi
