# TAK Wrapper Applications

This directory contains C++ applications for interacting with the TAK Server via CoT (Cursor on Target) messages.

## Applications

### CoT Injector (`cot_injector`)
Sends predefined CoT messages to TAK Server with sample military units.

### CoT Listener (`cot_listener`)  
Receives and displays CoT messages from TAK Server in real-time with parsing and filtering capabilities.

## Quick Start

### Build Applications
```bash
make
```

### Send CoT Messages
```bash
./run_cot_injector.sh --count 3
```

### Listen to CoT Messages
```bash
./run_cot_listener.sh --compact
```

## Files

- `cot_injector.cpp` - CoT message injector source code
- `cot_listener.cpp` - CoT message listener source code  
- `cot_injector` - Compiled injector executable
- `cot_listener` - Compiled listener executable
- `run_cot_injector.sh` - Convenience script for injector
- `run_cot_listener.sh` - Convenience script for listener
- `Makefile` - Build configuration
- `CMakeLists.txt` - CMake build configuration
- `README_CoT_Applications.md` - Comprehensive documentation

## Requirements

- TAK Server running (in `../cloud-rf-tak-server/`)
- OpenSSL development libraries
- C++17 compatible compiler
- Admin certificates (automatically referenced from TAK server)

## Testing Workflow

1. **Terminal 1**: Start listener
   ```bash
   ./run_cot_listener.sh --compact
   ```

2. **Terminal 2**: Send messages
   ```bash
   ./run_cot_injector.sh --count 5 --interval 1.0
   ```

3. **Observe**: Real-time CoT message display in Terminal 1

## Documentation

See `README_CoT_Applications.md` for comprehensive documentation including:
- Detailed usage examples
- Command-line options
- CoT message types and formats
- Troubleshooting guides
- Integration examples

## Certificate Configuration

Applications automatically use the admin certificates from the TAK server:
- Certificate path: `../cloud-rf-tak-server/tak/certs/files/`
- Passphrase: `atakatak` (configured in convenience scripts)

## Build from Source

```bash
# Using Make (recommended)
make

# Using CMake
mkdir build && cd build
cmake ..
make
```

Both applications support SSL/TLS authentication with the TAK server and provide professional-grade CoT message handling capabilities.