#!/bin/bash

set -e

echo "TAK Server Configuration Script"
echo "==============================="

# Configuration variables
TAK_DIR="TAK-Server"
CONFIG_DIR="$TAK_DIR/src/takserver-core/example"
CERT_DIR="$TAK_DIR/src/takserver-core/certs"

# Check if TAK Server directory exists
if [[ ! -d "$TAK_DIR" ]]; then
    echo "TAK Server directory not found. Please run clone-and-build.sh first."
    exit 1
fi

# Navigate to TAK Server directory
cd "$TAK_DIR"

echo "Setting up TAK Server configuration..."

# Copy example configuration files
echo ""
echo "Copying example configuration files..."
if [[ -d "$CONFIG_DIR" ]]; then
    cp -r "$CONFIG_DIR"/* src/takserver-core/
    echo "Configuration files copied from example directory."
else
    echo "Example configuration directory not found. Using defaults."
fi

# Generate certificates
echo ""
echo "Generating certificates..."
cd src/takserver-core

# Make certificate generation scripts executable
if [[ -f "makeRootCa.sh" ]]; then
    chmod +x makeRootCa.sh
    chmod +x makeCert.sh
fi

# Check if certificates already exist
if [[ -f "files/certs/takserver.jks" ]]; then
    echo "Certificates already exist. Skipping certificate generation."
else
    echo "Generating new certificates..."
    
    # Create certificates directory
    mkdir -p files/certs
    
    # Generate root CA
    if [[ -f "makeRootCa.sh" ]]; then
        ./makeRootCa.sh
    else
        echo "Certificate generation script not found. Manual certificate setup required."
        echo "Please refer to the TAK Server Configuration Guide for certificate setup."
    fi
    
    # Generate server certificate
    if [[ -f "makeCert.sh" ]]; then
        ./makeCert.sh server takserver
    else
        echo "Server certificate generation script not found."
    fi
fi

# Update database configuration
echo ""
echo "Updating database configuration..."

CONFIG_FILE="CoreConfig.xml"
if [[ -f "$CONFIG_FILE" ]]; then
    # Backup original config
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    
    # Update database connection settings
    sed -i 's/<connection url="jdbc:postgresql:\/\/[^"]*"/<connection url="jdbc:postgresql:\/\/localhost:5432\/cot"/g' "$CONFIG_FILE"
    sed -i 's/username="[^"]*"/username="tak"/g' "$CONFIG_FILE"
    sed -i 's/password="[^"]*"/password="tak123"/g' "$CONFIG_FILE"
    
    echo "Database configuration updated in $CONFIG_FILE"
else
    echo "CoreConfig.xml not found. Creating basic configuration..."
    
    cat > "$CONFIG_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Configuration xmlns="http://bbn.com/marti/xml/config">
    <network>
        <input _name="stdssl" auth="file" port="8089" protocol="tls"/>
        <input _name="stdtcp" port="8087" protocol="tcp"/>
        <input _name="httpsapi" auth="file" port="8443" protocol="https"/>
    </network>
    
    <auth>
        <File location="UserAuthenticationFile.xml"/>
    </auth>
    
    <repository enable="true" numDbConnections="16">
        <connection url="jdbc:postgresql://localhost:5432/cot" username="tak" password="tak123"/>
    </repository>
    
    <security>
        <tls keystore="files/certs/takserver.jks" keystorePass="atakatak" 
             truststore="files/certs/takserver.jks" truststorePass="atakatak"/>
    </security>
    
    <federation>
        <federationserver enable="false"/>
    </federation>
    
    <plugins/>
    
    <cluster/>
    
    <vbm enabled="false"/>
    
    <repeater enabled="false"/>
    
    <filter>
        <flowtag enable="false" text=""/>
    </filter>
    
    <buffer>
        <latestSA enable="true"/>
        <queue>
            <priority>5</priority>
        </queue>
    </buffer>
    
    <dissemination smartRetry="false"/>
    
    <certificateSigning CA="TAKServerSigningCA">
        <certificateConfig>
            <nameEntries>
                <nameEntry name="O" value="TAK"/>
                <nameEntry name="OU" value="TAK"/>
            </nameEntries>
        </certificateConfig>
        
        <TAKServerSigningCA validity="30" renewThreshold="7">
            <nameEntries>
                <nameEntry name="CN" value="TAK Server Signing CA"/>
                <nameEntry name="O" value="TAK"/>
                <nameEntry name="OU" value="TAK"/>
            </nameEntries>
        </TAKServerSigningCA>
        
        <TAKServerRootCA validity="3650">
            <nameEntries>
                <nameEntry name="CN" value="TAK Server Root CA"/>
                <nameEntry name="O" value="TAK"/>
                <nameEntry name="OU" value="TAK"/>
            </nameEntries>
        </TAKServerRootCA>
    </certificateSigning>
</Configuration>
EOF
    
    echo "Basic CoreConfig.xml created."
fi

# Create user authentication file
echo ""
echo "Creating user authentication file..."
USER_AUTH_FILE="UserAuthenticationFile.xml"
if [[ ! -f "$USER_AUTH_FILE" ]]; then
    cat > "$USER_AUTH_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<authUsers xmlns="http://bbn.com/marti/xml/config">
    <user identifier="admin" password="admin" groupList="__ANON__"/>
</authUsers>
EOF
    echo "User authentication file created with default admin user."
else
    echo "User authentication file already exists."
fi

# Set appropriate permissions
echo ""
echo "Setting file permissions..."
chmod 600 "$CONFIG_FILE" "$USER_AUTH_FILE" 2>/dev/null || true
chmod -R 700 files/certs/ 2>/dev/null || true

echo ""
echo "Configuration complete!"
echo ""
echo "Configuration files created/updated:"
echo "  - CoreConfig.xml (main configuration)"
echo "  - UserAuthenticationFile.xml (user credentials)"
echo "  - files/certs/ (SSL certificates)"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Important: Change default passwords before production use!"
echo ""
echo "Next step: Start TAK Server (run start-server.sh)"