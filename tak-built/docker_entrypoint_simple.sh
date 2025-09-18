#!/usr/bin/env bash

set -e

TR=/opt/tak
CONFIG=${TR}/CoreConfig.xml

echo "Starting TAK Server with simplified setup..."

cd ${TR}
. ./setenv.sh

# Only start the API service for web UI testing
echo "Starting TAK Server API service only..."
java -jar -Xmx${API_MAX_HEAP}m -Dspring.profiles.active=api -Dkeystore.pkcs12.legacy takserver.war