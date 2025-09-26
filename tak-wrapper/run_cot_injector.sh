#!/bin/bash

# TAK Server CoT Injector - Convenience Script
# This script runs the CoT injector with the proper certificates

CERT_DIR="../cloud-rf-tak-server/tak/certs/files"
ADMIN_CERT="$CERT_DIR/admin.pem"
ADMIN_KEY="$CERT_DIR/admin.key"
CA_CERT="$CERT_DIR/ca.pem"
PASSPHRASE="atakatak"

# Check if certificates exist
if [[ ! -f "$ADMIN_CERT" ]]; then
    echo "Error: Admin certificate not found at $ADMIN_CERT"
    exit 1
fi

if [[ ! -f "$ADMIN_KEY" ]]; then
    echo "Error: Admin private key not found at $ADMIN_KEY"
    exit 1
fi

if [[ ! -f "$CA_CERT" ]]; then
    echo "Error: CA certificate not found at $CA_CERT"
    exit 1
fi

# Default parameters
HOST="localhost"
PORT="8089"
COUNT="1"
INTERVAL="1.0"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --count)
            COUNT="$2"
            shift 2
            ;;
        --interval)
            INTERVAL="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --host <hostname>     TAK server hostname (default: localhost)"
            echo "  --port <port>         TAK server TCP port (default: 8089)"
            echo "  --count <number>      Number of iterations (default: 1)"
            echo "  --interval <seconds>  Interval between sends (default: 1.0)"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "This script automatically uses the admin certificate with passphrase."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "Running CoT Injector with admin certificates..."
echo "Target: $HOST:$PORT"
echo "Count: $COUNT, Interval: $INTERVAL"
echo ""

# Check if build directory and executable exist
if [[ ! -d "build" ]]; then
    echo "Error: build/ directory not found. Please run CMake build first:"
    echo "  mkdir build && cd build && cmake .. && make"
    exit 1
fi

if [[ ! -f "build/cot_injector" ]]; then
    echo "Error: cot_injector executable not found in build/ directory"
    echo "Please run CMake build first:"
    echo "  mkdir build && cd build && cmake .. && make"
    exit 1
fi

# Run the CoT injector
build/cot_injector \
    --host "$HOST" \
    --port "$PORT" \
    --cert "$ADMIN_CERT" \
    --key "$ADMIN_KEY" \
    --ca "$CA_CERT" \
    --passphrase "$PASSPHRASE" \
    --count "$COUNT" \
    --interval "$INTERVAL"