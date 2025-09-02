#!/bin/bash

set -e

echo "TAK Server Dependencies Setup Script"
echo "===================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root for security reasons."
   echo "Please run as a regular user with sudo privileges."
   exit 1
fi

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo "Unsupported OS: $OSTYPE"
    echo "TAK Server requires Linux or macOS (x86-64 architecture)"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    echo "Unsupported architecture: $ARCH"
    echo "TAK Server requires x86-64 architecture"
    if [[ "$ARCH" == "arm64" ]] && [[ "$OS" == "macos" ]]; then
        echo "M1/M2 Apple silicon is not supported"
    fi
    exit 1
fi

echo "Detected OS: $OS"
echo "Architecture: $ARCH"

# Install Java 17
echo ""
echo "Installing Java 17..."
if [[ "$OS" == "linux" ]]; then
    # Detect Linux distribution
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y openjdk-17-jdk
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS/Fedora (older)
        sudo yum install -y java-17-openjdk-devel
    elif command -v dnf &> /dev/null; then
        # Fedora (newer)
        sudo dnf install -y java-17-openjdk-devel
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -S jdk17-openjdk
    else
        echo "Unsupported Linux distribution. Please install Java 17 manually."
        exit 1
    fi
elif [[ "$OS" == "macos" ]]; then
    if command -v brew &> /dev/null; then
        brew install openjdk@17
        # Add to PATH
        echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
        echo 'export JAVA_HOME="/usr/local/opt/openjdk@17"' >> ~/.zshrc
    else
        echo "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

# Verify Java installation
echo ""
echo "Verifying Java installation..."
java -version
javac -version

# Install PostgreSQL and PostGIS
echo ""
echo "Installing PostgreSQL and PostGIS..."
if [[ "$OS" == "linux" ]]; then
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get install -y postgresql postgresql-contrib postgis postgresql-*-postgis-*
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS/Fedora (older)
        sudo yum install -y postgresql-server postgresql-contrib postgis
        sudo postgresql-setup initdb
    elif command -v dnf &> /dev/null; then
        # Fedora (newer)
        sudo dnf install -y postgresql-server postgresql-contrib postgis
        sudo postgresql-setup --initdb
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -S postgresql postgis
        sudo -u postgres initdb -D /var/lib/postgres/data
    fi
elif [[ "$OS" == "macos" ]]; then
    if command -v brew &> /dev/null; then
        brew install postgresql postgis
        brew services start postgresql
    fi
fi

# Install Git
echo ""
echo "Installing Git..."
if [[ "$OS" == "linux" ]]; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y git
    elif command -v yum &> /dev/null; then
        sudo yum install -y git
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git
    elif command -v pacman &> /dev/null; then
        sudo pacman -S git
    fi
elif [[ "$OS" == "macos" ]]; then
    # Git should be available via Xcode Command Line Tools
    if ! command -v git &> /dev/null; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
    fi
fi

# Install Docker (optional, for PostgreSQL container)
echo ""
echo "Installing Docker (optional for PostgreSQL container)..."
if [[ "$OS" == "linux" ]]; then
    if command -v apt-get &> /dev/null; then
        # Install Docker on Ubuntu/Debian
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
        # Install Docker on RHEL/CentOS/Fedora
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        sudo systemctl start docker
        sudo systemctl enable docker
        rm get-docker.sh
    fi
elif [[ "$OS" == "macos" ]]; then
    echo "Please install Docker Desktop for Mac from: https://docs.docker.com/desktop/mac/install/"
fi

echo ""
echo "Dependencies installation complete!"
echo ""
echo "Next steps:"
echo "1. Start PostgreSQL service"
echo "2. Create TAK Server database and user"
echo "3. Run the build script to clone and compile TAK Server"
echo ""
echo "Note: You may need to log out and log back in for Docker group membership to take effect."