#!/bin/bash

# TAK Server CoT Listener - Convenience Script
# This script runs the CoT listener with the proper certificates

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
COMPACT=""
VERBOSE=""
FILTER=""

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
        --compact)
            COMPACT="--compact"
            shift
            ;;
        --verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --filter)
            FILTER="--filter $2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --host <hostname>     TAK server hostname (default: localhost)"
            echo "  --port <port>         TAK server TCP port (default: 8089)"
            echo "  --compact             Use compact display format"
            echo "  --verbose             Show detailed information and raw XML"
            echo "  --filter <type>       Filter messages by type (e.g., 'a-f' for friendly)"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "This script automatically uses the admin certificate with passphrase."
            echo "Press Ctrl+C to stop listening."
            echo ""
            echo "CoT Type Examples:"
            echo "  a-f-*    Friendly units"
            echo "  a-h-*    Hostile units"
            echo "  a-n-*    Neutral units"
            echo "  a-u-*    Unknown units"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "Starting CoT Listener with admin certificates..."
echo "Target: $HOST:$PORT"
if [[ -n "$FILTER" ]]; then
    echo "Filter: $FILTER"
fi
echo "Press Ctrl+C to stop"
echo ""

# Check if build directory and executable exist
if [[ ! -d "build" ]]; then
    echo "Error: build/ directory not found. Please run CMake build first:"
    echo "  mkdir build && cd build && cmake .. && make"
    exit 1
fi

if [[ ! -f "build/cot_listener" ]]; then
    echo "Error: cot_listener executable not found in build/ directory"
    echo "Please run CMake build first:"
    echo "  mkdir build && cd build && cmake .. && make"
    exit 1
fi

# Run the CoT listener
build/cot_listener \
    --host "$HOST" \
    --port "$PORT" \
    --cert "$ADMIN_CERT" \
    --key "$ADMIN_KEY" \
    --ca "$CA_CERT" \
    --passphrase "$PASSPHRASE" \
    $COMPACT \
    $VERBOSE \
    $FILTER