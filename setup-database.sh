#!/bin/bash

set -e

echo "TAK Server Database Setup Script"
echo "================================"

# Configuration variables
DB_NAME="cot"
DB_USER="tak"
DB_PASSWORD="tak123"
DB_HOST="localhost"
DB_PORT="5432"

# Check if PostgreSQL is running
echo "Checking PostgreSQL status..."
if ! pg_isready -h $DB_HOST -p $DB_PORT &> /dev/null; then
    echo "PostgreSQL is not running on $DB_HOST:$DB_PORT"
    echo ""
    echo "To start PostgreSQL:"
    echo "  Ubuntu/Debian: sudo systemctl start postgresql"
    echo "  RHEL/CentOS/Fedora: sudo systemctl start postgresql"
    echo "  macOS (Homebrew): brew services start postgresql"
    echo ""
    echo "Attempting to start PostgreSQL service..."
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl start postgresql
        sleep 2
    elif [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew services start postgresql
        sleep 2
    else
        echo "Unable to start PostgreSQL automatically. Please start it manually."
        exit 1
    fi
    
    # Check again
    if ! pg_isready -h $DB_HOST -p $DB_PORT &> /dev/null; then
        echo "PostgreSQL is still not running. Please start it manually."
        exit 1
    fi
fi

echo "PostgreSQL is running: OK"

# Create database user
echo ""
echo "Creating database user '$DB_USER'..."

# Check if user already exists
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    echo "User '$DB_USER' already exists."
else
    sudo -u postgres createuser -S -D -R $DB_USER
    echo "User '$DB_USER' created successfully."
fi

# Set password for user
echo "Setting password for user '$DB_USER'..."
sudo -u postgres psql -c "ALTER USER $DB_USER PASSWORD '$DB_PASSWORD';"

# Create database
echo ""
echo "Creating database '$DB_NAME'..."

# Check if database already exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo "Database '$DB_NAME' already exists."
else
    sudo -u postgres createdb -O $DB_USER $DB_NAME
    echo "Database '$DB_NAME' created successfully."
fi

# Enable PostGIS extension
echo ""
echo "Enabling PostGIS extension..."
sudo -u postgres psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# Grant privileges
echo ""
echo "Granting privileges to user '$DB_USER'..."
sudo -u postgres psql -d $DB_NAME -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO $DB_USER;"

# Test connection
echo ""
echo "Testing database connection..."
if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT version();" &> /dev/null; then
    echo "Database connection test: OK"
else
    echo "Database connection test: FAILED"
    echo "Please check the database configuration."
    exit 1
fi

# Create Docker option information
echo ""
echo "Database setup complete!"
echo ""
echo "Connection details:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo ""
echo "Alternative: Use Docker for PostgreSQL"
echo "If you prefer to use Docker instead:"
echo "  docker run --name tak-postgres -e POSTGRES_DB=$DB_NAME -e POSTGRES_USER=$DB_USER -e POSTGRES_PASSWORD=$DB_PASSWORD -p 5432:5432 -d postgis/postgis:latest"
echo ""
echo "Next step: Configure TAK Server settings and certificates"