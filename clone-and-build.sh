#!/bin/bash

set -e

echo "TAK Server Clone and Build Script"
echo "================================="

# Configuration variables
TAK_REPO="https://github.com/TAK-Product-Center/Server.git"
TAK_DIR="TAK-Server"
BUILD_DIR="$TAK_DIR/src"

# Check if Java 17 is installed
echo "Checking Java version..."
if ! command -v java &> /dev/null; then
    echo "Java is not installed. Please run setup-dependencies.sh first."
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [[ "$JAVA_VERSION" != "17" ]]; then
    echo "Java 17 is required, but Java $JAVA_VERSION is installed."
    echo "Please install Java 17 or set JAVA_HOME to point to Java 17."
    exit 1
fi

echo "Java 17 detected: OK"

# Check if Git is available
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please run setup-dependencies.sh first."
    exit 1
fi

# Clone TAK Server repository
echo ""
echo "Cloning TAK Server repository..."
if [[ -d "$TAK_DIR" ]]; then
    echo "TAK Server directory already exists. Pulling latest changes..."
    cd "$TAK_DIR"
    git pull
    cd ..
else
    git clone "$TAK_REPO" "$TAK_DIR"
fi

# Navigate to build directory
cd "$BUILD_DIR"

# Set Java options for Java 17 compatibility
export JDK_JAVA_OPTIONS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.util.calendar=ALL-UNNAMED --add-opens=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/java.awt.font=ALL-UNNAMED"

echo ""
echo "Building TAK Server..."
echo "This may take several minutes..."

# Make gradlew executable
chmod +x gradlew

# Clean and build
echo "Running: ./gradlew clean bootWar bootJar shadowJar"
./gradlew clean bootWar bootJar shadowJar

# Check if build was successful
if [[ $? -eq 0 ]]; then
    echo ""
    echo "Build completed successfully!"
    echo ""
    echo "Generated artifacts:"
    find . -name "*.war" -o -name "*.jar" | grep -E "(takserver|TAK)" | head -10
    echo ""
    echo "Next steps:"
    echo "1. Set up PostgreSQL database (run setup-database.sh)"
    echo "2. Configure TAK Server certificates and settings"
    echo "3. Start TAK Server services (run start-server.sh)"
else
    echo ""
    echo "Build failed. Please check the error messages above."
    exit 1
fi