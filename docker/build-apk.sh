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

# Build the Docker image if it doesn't exist or if forced
IMAGE_NAME="ecash-app-builder"

if ! docker image inspect $IMAGE_NAME &> /dev/null || [[ "${REBUILD_IMAGE}" == "1" ]]; then
    echo "Building Docker image..."
    docker build -t $IMAGE_NAME "$SCRIPT_DIR"
    echo ""
else
    echo "Using existing Docker image: $IMAGE_NAME"
    echo "(Set REBUILD_IMAGE=1 to force rebuild)"
    echo ""
fi

# Run the build
echo "Starting build in Docker container..."
docker run --rm \
    -v "$PROJECT_ROOT:/workspace" \
    -w /workspace \
    $IMAGE_NAME \
    bash /workspace/docker/build-in-container.sh "$BUILD_MODE"

echo ""
echo "==================================="
echo "All done!"
echo "==================================="
echo "Your APK is at: $PROJECT_ROOT/build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
