#!/bin/bash
set -e

# This script builds the Docker image and then builds the APK
# Run from the project root: ./docker/build-apk.sh [debug|release]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Determine build mode (default to debug)
BUILD_MODE="${1:-debug}"

if [[ "$BUILD_MODE" != "debug" && "$BUILD_MODE" != "release" ]]; then
    echo "Error: Build mode must be 'debug' or 'release'"
    echo "Usage: $0 [debug|release]"
    exit 1
fi

echo "==================================="
echo "Ecash App Docker Build"
echo "==================================="
echo "Project root: $PROJECT_ROOT"
echo "Build mode: $BUILD_MODE"
echo ""

# Show build configuration
echo "Build configuration:"
if [[ "${REBUILD_IMAGE}" == "1" ]]; then
    echo "  - REBUILD_IMAGE=1: Rebuilding Docker image"
else
    echo "  - Using existing Docker image (set REBUILD_IMAGE=1 to rebuild)"
fi

if [[ "${CLEAN}" == "1" ]]; then
    echo "  - CLEAN=1: Wiping all build caches (Rust, Flutter, Gradle)"
    # Remove Docker cache directory to force clean Gradle build
    if [ -d "$PROJECT_ROOT/.docker-cache" ]; then
        echo "  - Removing .docker-cache directory..."
        # Try to remove normally first
        if ! rm -rf "$PROJECT_ROOT/.docker-cache" 2>/dev/null; then
            # If permission denied (root-owned files), use Docker to remove
            echo "  - Using Docker to remove root-owned cache files..."
            docker run --rm -v "$PROJECT_ROOT:/workspace" alpine sh -c "rm -rf /workspace/.docker-cache"
        fi
    fi
else
    echo "  - Using incremental build caches (set CLEAN=1 to wipe)"
fi
echo ""

# Create cache directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/.docker-cache/gradle"

# Build the Docker image if it doesn't exist or if forced
IMAGE_NAME="ecash-app-builder"

if ! docker image inspect $IMAGE_NAME &> /dev/null || [[ "${REBUILD_IMAGE}" == "1" ]]; then
    echo "Building Docker image..."
    docker build -t $IMAGE_NAME "$SCRIPT_DIR"
    echo ""
else
    echo "Using existing Docker image: $IMAGE_NAME"
    echo ""
fi

# Run the build
echo "Starting build in Docker container..."
docker run --rm \
    -v "$PROJECT_ROOT:/workspace" \
    -v "$PROJECT_ROOT/.docker-cache/gradle:/root/.gradle" \
    -w /workspace \
    -e CLEAN="${CLEAN}" \
    $IMAGE_NAME \
    bash /workspace/docker/entrypoint.sh "$BUILD_MODE"

echo ""
echo "==================================="
echo "All done!"
echo "==================================="
echo "Your APK is in: $PROJECT_ROOT/build/app/outputs/flutter-apk/"
echo "Run 'ls -lth $PROJECT_ROOT/build/app/outputs/flutter-apk/' to see the latest build"
