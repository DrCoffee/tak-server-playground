# TAK Server Management Scripts

This directory contains scripts to easily manage TAK server Docker containers for testing the CoT applications.

## Scripts

### `manage_takserver.sh`
Comprehensive TAK server management script with full functionality:

**Usage:** `./manage_takserver.sh [COMMAND] [OPTIONS]`

**Commands:**
- `start` - Start TAK server containers (builds if needed)
- `stop` - Stop TAK server containers (preserves data)
- `restart` - Restart TAK server containers
- `remove` - Remove containers (but preserve volumes)
- `status` - Show container status (including stopped containers)
- `logs [service]` - Show logs (optionally for specific service: `tak`, `db`)
- `test` - Test connectivity to TAK server
- `cleanup` - Remove containers and volumes (DESTRUCTIVE)
- `help` - Show help message

**Examples:**
```bash
./manage_takserver.sh start          # Start TAK server
./manage_takserver.sh logs tak       # Show TAK server logs
./manage_takserver.sh test           # Test connectivity
```

### `tak`
Quick wrapper script for common operations:

**Usage:** `./tak [COMMAND]`

**Quick Commands:**
- `up`, `start` - Start TAK server
- `down`, `stop` - Stop TAK server (preserves data)
- `remove`, `rm` - Remove containers (preserve volumes)
- `restart`, `reload` - Restart TAK server
- `ps`, `status` - Show container status
- `logs [service]` - Show logs
- `test`, `ping` - Test connectivity
- `clean`, `cleanup` - Clean up containers and volumes

**Examples:**
```bash
./tak up                # Start TAK server
./tak ps                # Show status
./tak logs              # Show all logs
./tak test              # Test connectivity
```

## Features

- **Architecture Detection**: Automatically detects ARM64 vs x86_64 and uses appropriate Docker Compose file
- **Connectivity Testing**: Tests both TCP (port 8089) and HTTPS (port 8443) connectivity
- **Colored Output**: Easy-to-read status messages with color coding
- **Error Handling**: Comprehensive error checking and user-friendly messages
- **Service-Specific Logs**: View logs for individual services (TAK server or database)

## TAK Server Ports

When running, the TAK server exposes these ports:
- **8443** - HTTPS Web UI
- **8444** - HTTPS API  
- **8446** - Additional HTTPS port
- **8089** - CoT TCP port (used by our applications)
- **9000, 9001** - Federation ports

## Prerequisites

- Docker and Docker Compose installed
- The `cloud-rf-tak-server` directory must exist in the parent directory
- Appropriate Docker Compose files must be present

## Directory Structure

```
tak-testing/
├── cloud-rf-tak-server/          # TAK server Docker setup
│   ├── docker-compose.yml        # x86_64 configuration
│   ├── docker-compose.arm.yml    # ARM64 configuration  
│   └── ...
└── tak-wrapper/                   # CoT applications
    ├── manage_takserver.sh        # Full management script
    ├── tak                        # Quick wrapper script
    ├── cot_injector              # CoT message injector
    ├── cot_listener              # CoT message listener
    └── ...
```

## Integration with CoT Applications

Once the TAK server is running, you can test the CoT applications:

```bash
# Start TAK server
./tak up

# Test connectivity  
./tak test

# In another terminal, run the CoT listener
./cot_listener --host localhost --port 8089

# In another terminal, inject CoT messages
./cot_injector --host localhost --port 8089 --count 5
```