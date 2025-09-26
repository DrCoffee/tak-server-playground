# TAK Server CoT Injector (C++)

A C++ application for injecting Cursor on Target (CoT) objects into a running TAK Server via SSL/TCP connection.

## Features

- SSL/TCP connection to TAK Server
- XML generation for CoT objects
- Sample military units (friendly, hostile, neutral)
- Configurable host, port, and timing
- Multiple unit types and affiliations

## Prerequisites

- C++17 compatible compiler (GCC 7+ or Clang 5+)
- OpenSSL development libraries
- CMake 3.10+ (optional, for CMake build)
- Make (for Makefile build)

### Installing Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install build-essential libssl-dev cmake
```

**CentOS/RHEL/Fedora:**
```bash
# CentOS/RHEL
sudo yum install gcc-c++ openssl-devel cmake make

# Fedora
sudo dnf install gcc-c++ openssl-devel cmake make
```

**macOS:**
```bash
# Install Xcode command line tools
xcode-select --install

# Install OpenSSL via Homebrew
brew install openssl cmake

# You may need to set PKG_CONFIG_PATH
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
```

## Building

### Option 1: Using Make (Recommended)
```bash
make
```

### Option 2: Using CMake
```bash
mkdir build
cd build
cmake ..
make
```

### Build Options
```bash
# Debug build with symbols
make debug

# Clean build files
make clean

# Install to system
sudo make install
```

## Usage

### Basic Usage
```bash
# Send sample units to localhost TAK server
./cot_injector

# Specify custom host and port
./cot_injector --host 192.168.1.100 --port 8087

# Send multiple batches with delays
./cot_injector --count 5 --interval 2.0
```

### Command Line Options
- `--host <hostname>`: TAK server hostname (default: localhost)
- `--port <port>`: TAK server TCP port (default: 8087)
- `--count <number>`: Number of iterations (default: 1)
- `--interval <seconds>`: Interval between sends (default: 1.0)
- `--help`: Show help message

### Example Commands
```bash
# Connect to remote TAK server
./cot_injector --host tak.example.com --port 8087

# Send 10 batches with 5-second intervals
./cot_injector --count 10 --interval 5.0

# Quick test with short intervals
./cot_injector --count 3 --interval 0.5
```

## Sample Units Generated

The application creates four sample military units:

1. **Alpha-1** (Friendly Ground Unit - Blue Team)
   - Location: Denver, CO (39.7392, -104.9903)
   - Type: `a-f-G-U-C` (Friendly ground unit civilian)

2. **Bravo-2** (Friendly Vehicle - Blue Team)
   - Location: Near Denver (39.7292, -104.9803)
   - Type: `a-f-G-E-V-C` (Friendly ground equipment vehicle civilian)

3. **Enemy-1** (Hostile Unit - Red Team)
   - Location: South of Denver (39.7192, -104.9703)
   - Type: `a-h-G-U-C` (Hostile ground unit civilian)

4. **Neutral-1** (Neutral Unit - White Team)
   - Location: West of Denver (39.7492, -105.0003)
   - Type: `a-n-G-U-C` (Neutral ground unit civilian)

## CoT XML Format

The application generates standard MIL-STD-2525 compatible CoT XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<event version="2.0" uid="12345678-1234-4123-8123-123456789012" 
       type="a-f-G-U-C" how="h-g-i-g-o"
       time="2024-01-01T12:00:00.000Z"
       start="2024-01-01T12:00:00.000Z"
       stale="2024-01-01T12:10:00.000Z">
  <point lat="39.739200" lon="-104.990300" hae="1609.00" ce="10.0" le="10.0"/>
  <detail>
    <contact callsign="Alpha-1"/>
    <__group name="Blue" role="Team Member"/>
  </detail>
</event>
```

## TAK Server Configuration

### Default TAK Server Ports
- **8087**: SSL/TCP streaming port (used by this application)
- **8089**: SSL/TCP streaming port (alternative)
- **8443**: HTTPS API port
- **8444**: HTTPS federation port
- **8446**: HTTPS subscription management port

### SSL/TLS Notes
- The application disables certificate verification for demo purposes
- For production use, implement proper certificate validation
- TAK Server typically requires client certificates for authentication

## Troubleshooting

### Connection Issues
```bash
# Check if TAK server is running
docker compose ps

# Check if ports are accessible
telnet localhost 8087
```

### SSL/TLS Errors
- Ensure OpenSSL is properly installed
- Verify TAK server is accepting SSL connections
- Check firewall settings

### Build Issues
```bash
# Install missing dependencies
sudo apt install build-essential libssl-dev

# Check compiler version
g++ --version

# Verify OpenSSL installation
pkg-config --modversion openssl
```

## Customization

### Adding New Unit Types
Modify the `create_sample_units()` function to add new CoT objects:

```cpp
// Add a new friendly aircraft
units.emplace_back("a-f-A-C-F", "h-g-i-g-o", 39.7500, -104.9900, 3000.0, "Eagle-1", "Blue");
```

### CoT Type Codes
- `a-f-*`: Friendly units
- `a-h-*`: Hostile units  
- `a-n-*`: Neutral units
- `a-u-*`: Unknown units

### Second Level (Platform)
- `G`: Ground
- `A`: Air
- `S`: Surface (naval)
- `U`: Subsurface

## License

This software is provided for educational and demonstration purposes.