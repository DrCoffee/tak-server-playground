# TAK Server Docker Setup

This setup provides TAK Server and PostgreSQL in a single Docker container for easy deployment and testing.

## Quick Start

1. **Build the Docker image:**
   ```bash
   chmod +x *.sh
   ./docker-build.sh build
   ```

2. **Start TAK Server:**
   ```bash
   ./docker-run.sh start
   ```

3. **Access TAK Server:**
   - Web UI: https://localhost:8443
   - Default credentials: `admin` / `admin`

## Files Overview

### Docker Configuration
- `Dockerfile` - Multi-service container definition
- `docker-compose.yml` - Docker Compose configuration
- `docker-entrypoint.sh` - Container startup script

### TAK Server Configuration
- `CoreConfig.xml` - Main TAK Server configuration
- `UserAuthenticationFile.xml` - User authentication settings
- `init-database.sql` - Database initialization script

### Management Scripts
- `docker-build.sh` - Build Docker image
- `docker-run.sh` - Manage container runtime
- `setup-tak-server.sh` - Complete setup (local)

## Usage

### Using Management Scripts

**Build Image:**
```bash
./docker-build.sh build           # Build image
./docker-build.sh build --clean   # Rebuild from scratch
./docker-build.sh clean           # Remove image and container
```

**Manage Container:**
```bash
./docker-run.sh start             # Start container
./docker-run.sh stop              # Stop container
./docker-run.sh restart           # Restart container
./docker-run.sh status            # Show status
./docker-run.sh logs              # View container logs
./docker-run.sh logs api          # View API service logs
./docker-run.sh shell             # Open shell in container
```

### Using Docker Compose

**Start services:**
```bash
docker-compose up -d              # Start in background
docker-compose up                 # Start with logs
```

**Manage services:**
```bash
docker-compose stop               # Stop services
docker-compose down               # Stop and remove containers
docker-compose logs -f            # View logs
docker-compose ps                 # Show status
```

## Services and Ports

| Service | Port | Description |
|---------|------|-------------|
| HTTPS API | 8443 | Web UI and REST API |
| TLS Input | 8089 | Secure client connections |
| TCP Input | 8087 | Insecure client connections |
| PostgreSQL | 5432 | Database (optional external access) |

## Default Credentials

- **Web UI:** admin / admin
- **Database:** tak / tak123

## Data Persistence

Data is stored in Docker volumes:
- `tak_data` - TAK Server files and certificates
- `tak_logs` - Application logs
- `postgres_data` - PostgreSQL database

## Customization

### Environment Variables
- `TAK_USER` - Database username (default: tak)
- `TAK_DB` - Database name (default: cot)
- `TAK_PASSWORD` - Database password (default: tak123)

### Configuration Files
Edit these files before building:
- `CoreConfig.xml` - Server settings, ports, security
- `UserAuthenticationFile.xml` - User accounts

### Memory Settings
Container uses these memory limits:
- Config service: 512MB
- Messaging service: 2048MB
- API service: 1024MB

## Troubleshooting

### Check Service Status
```bash
./docker-run.sh status
```

### View Logs
```bash
# Container logs
./docker-run.sh logs

# Specific service logs
./docker-run.sh logs api
./docker-run.sh logs messaging
./docker-run.sh logs config
./docker-run.sh logs postgres
```

### Access Container Shell
```bash
./docker-run.sh shell
```

### Common Issues

**Services not starting:**
- Check available memory (requires ~4GB RAM)
- Verify ports 8443, 8089, 8087 are available
- Check logs for Java-related errors

**Database connection issues:**
- Wait 1-2 minutes for PostgreSQL to initialize
- Check PostgreSQL logs: `./docker-run.sh logs postgres`

**SSL/Certificate issues:**
- Container generates self-signed certificates
- Browsers will show security warnings (normal)
- Use `--insecure` flag with curl/wget for testing

## Production Considerations

1. **Change default passwords** in `UserAuthenticationFile.xml`
2. **Use proper SSL certificates** (replace generated ones)
3. **Configure firewall** for required ports only
4. **Set resource limits** appropriate for your environment
5. **Enable backups** for data volumes
6. **Monitor logs** and set up log rotation

## Building from Source

The container automatically:
1. Clones TAK Server from GitHub
2. Builds with Gradle and Java 17
3. Configures PostgreSQL with PostGIS
4. Sets up basic SSL certificates
5. Configures all services

Total build time: 15-30 minutes depending on hardware.