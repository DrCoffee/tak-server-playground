# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a TAK Server v5.2-RELEASE-16 deployment setup with Docker containerization. The project consists of:

1. **TAK Server Source**: Located in `Server/` directory - complete TAK Server codebase cloned from upstream
2. **Docker Infrastructure**: Custom Docker setup for running TAK Server with PostgreSQL in a single container
3. **Configuration Management**: Multiple XML config files for different deployment scenarios
4. **Management Scripts**: Shell scripts for building, running, and managing the containerized deployment
5. **Automatic Certificate Generation**: Built-in certificate generation using TAK Server's certificate scripts

### Key Components

- **TAK Server Core**: Java-based server application with microservices architecture (Config, Messaging, API, Plugins)
- **PostgreSQL Database**: Database with PostGIS extension for spatial data
- **Docker Container**: Single container running both TAK Server and PostgreSQL using supervisord
- **Certificate Management**: Automatic generation of CA, server, and client certificates using TAK Server's built-in certificate scripts
- **TLS/SSL Security**: Full HTTPS/TLS support with proper certificate infrastructure

## Build Commands

### Docker Build
```bash
# Build Docker image
./docker-build.sh build

# Clean build from scratch
./docker-build.sh build --clean

# Remove image and container
./docker-build.sh clean
```

### TAK Server Build (from Server/src)
```bash
# Build main artifacts
./gradlew clean bootWar bootJar shadowJar

# Build all packages including RPMs
./gradlew clean buildRpm
```

## Development Commands

### Container Management
```bash
# Start container
./docker-run.sh start

# Stop container
./docker-run.sh stop

# Restart container
./docker-run.sh restart

# View status
./docker-run.sh status

# View logs (all services)
./docker-run.sh logs

# View specific service logs
./docker-run.sh logs api
./docker-run.sh logs messaging
./docker-run.sh logs config
./docker-run.sh logs postgres

# Access container shell
./docker-run.sh shell
```

### Docker Compose (Alternative)
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f
```

### Database Setup (Local Development)
```bash
cd Server/src/takserver-schemamanager
java -jar build/libs/schemamanager-<version>-uber.jar upgrade
```

## Testing

No specific test commands are defined in the management scripts. For TAK Server testing:

```bash
cd Server/src
./gradlew test
```

## Configuration Files

- `CoreConfig.xml` - Main TAK Server configuration (HTTP/HTTPS ports, database settings)
- `CoreConfig-*.xml` - Variant configurations (minimal, no-auth, etc.)
- `UserAuthenticationFile.xml` - User authentication settings
- `docker-compose.yml` - Docker Compose configuration
- `supervisord.conf` - Process management within container

## Services and Ports

| Service | Port | Description |
|---------|------|-------------|
| HTTP API | 8080 | Web UI and REST API (insecure) |
| HTTPS API | 8443 | Web UI and REST API (secure) |
| TLS Input | 8089 | Secure client connections |
| TCP Input | 8087 | Insecure client connections |
| PostgreSQL | 5432 | Database (optional external access) |

## Environment Variables

**Database Configuration:**
- `TAK_USER` - Database username (default: tak)
- `TAK_DB` - Database name (default: cot)  
- `TAK_PASSWORD` - Database password (default: tak123)
- `POSTGRES_VERSION` - PostgreSQL version (default: 14)

**Certificate Configuration:**
- `STATE` - Certificate state/province (default: VA)
- `CITY` - Certificate city (default: Vienna)
- `ORGANIZATION` - Certificate organization (default: TAK)
- `ORGANIZATIONAL_UNIT` - Certificate organizational unit (default: TAK-Server)
- `CAPASS` - CA password (default: atakatak)
- `PASS` - Certificate password (default: atakatak)

## TAK Server Microservices

When running locally for development, TAK Server consists of three separate Java processes:

1. **Configuration Service**: Must run first, provides centralized configuration
2. **Messaging Service**: Handles client connections and message routing
3. **API Service**: Provides REST API and web interface
4. **Plugin Manager** (optional): Manages server plugins

Each service requires Java 17 with extensive `--add-opens` JVM arguments for compatibility.

## Data Persistence

Docker volumes used:
- `tak_data` - TAK Server files and certificates
- `tak_logs` - Application logs  
- `postgres_data` - PostgreSQL database

## Certificate Management

The Docker container automatically generates a complete certificate infrastructure using TAK Server's built-in certificate scripts:

- **Root CA**: `tak-ca` certificate authority
- **Server Certificate**: `takserver` for HTTPS/TLS connections
- **Client Certificates**: `admin` and `user` for client authentication

Certificate files are generated in `files/certs/` directory and include both PEM and PKCS12 formats.

## Default Credentials

- **Web UI**: admin / admin
- **Database**: tak / tak123
- **Certificates**: atakatak (password for all certificates)