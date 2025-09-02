#!/bin/bash

set -e

echo "TAK Server Docker Build Script"
echo "=============================="

# Configuration
IMAGE_NAME="tak-server"
TAG="latest"
CONTAINER_NAME="tak-server"

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        echo "Docker is not running or not accessible."
        echo "Please make sure Docker is installed and running."
        exit 1
    fi
}

# Function to build the Docker image
build_image() {
    echo ""
    echo "Building TAK Server Docker image..."
    echo "This may take 15-30 minutes depending on your system..."
    
    docker build -t ${IMAGE_NAME}:${TAG} .
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo "Docker image built successfully!"
        echo "Image: ${IMAGE_NAME}:${TAG}"
    else
        echo ""
        echo "Docker image build failed!"
        exit 1
    fi
}

# Function to show image info
show_image_info() {
    echo ""
    echo "Docker image information:"
    echo "========================="
    docker images ${IMAGE_NAME}:${TAG}
    
    echo ""
    echo "Image size details:"
    docker image inspect ${IMAGE_NAME}:${TAG} --format='{{.Size}}' | numfmt --to=iec
}

# Parse command line arguments
case "${1:-build}" in
    build)
        echo "Checking Docker status..."
        check_docker
        
        # Stop and remove existing container if running
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "Stopping and removing existing container..."
            docker stop ${CONTAINER_NAME} 2>/dev/null || true
            docker rm ${CONTAINER_NAME} 2>/dev/null || true
        fi
        
        # Remove existing image if requested
        if [[ "$2" == "--clean" ]]; then
            echo "Removing existing image..."
            docker rmi ${IMAGE_NAME}:${TAG} 2>/dev/null || true
        fi
        
        build_image
        show_image_info
        
        echo ""
        echo "Next steps:"
        echo "  Start container: ./docker-run.sh start"
        echo "  Or use docker-compose: docker-compose up -d"
        ;;
        
    clean)
        echo "Cleaning up TAK Server Docker resources..."
        
        # Stop and remove container
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "Stopping and removing container..."
            docker stop ${CONTAINER_NAME} 2>/dev/null || true
            docker rm ${CONTAINER_NAME} 2>/dev/null || true
        fi
        
        # Remove image
        if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}:${TAG}$"; then
            echo "Removing image..."
            docker rmi ${IMAGE_NAME}:${TAG} 2>/dev/null || true
        fi
        
        # Clean up volumes (optional)
        if [[ "$2" == "--volumes" ]]; then
            echo "Removing Docker volumes..."
            docker volume rm tak_data tak_logs postgres_data 2>/dev/null || true
        fi
        
        echo "Cleanup complete."
        ;;
        
    info)
        check_docker
        show_image_info
        ;;
        
    *)
        echo "Usage: $0 {build|clean|info}"
        echo ""
        echo "Commands:"
        echo "  build       - Build the TAK Server Docker image"
        echo "  build --clean - Build after removing existing image"
        echo "  clean       - Remove container and image"
        echo "  clean --volumes - Remove container, image, and volumes"
        echo "  info        - Show image information"
        exit 1
        ;;
esac