#!/bin/bash
set -e

# This script builds the APK inside the Docker container
# It mirrors the GitHub Actions workflow exactly

echo "==================================="
echo "Building Ecash App APK"
echo "==================================="

# Determine build mode (default to debug)
BUILD_MODE="${1:-debug}"

if [[ "$BUILD_MODE" != "debug" && "$BUILD_MODE" != "release" ]]; then
    echo "Error: Build mode must be 'debug' or 'release'"
    echo "Usage: $0 [debug|release]"
    exit 1
fi

echo "Build mode: $BUILD_MODE"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
rm -rf android/.gradle android/build build

# Setup gradle properties (matching GitHub Actions)
echo "Configuring Gradle..."
mkdir -p android
cat > android/gradle.properties <<EOF
org.gradle.daemon=false
org.gradle.parallel=false
org.gradle.configureondemand=true
org.gradle.workers.max=2
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
android.ndkVersion=25.2.9519653
EOF

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build Rust library for Android
echo "Building Rust library for aarch64-linux-android..."
RUST_DIR="/workspace/rust/ecashapp"
JNI_LIBS_DIR="/workspace/android/app/src/main/jniLibs/arm64-v8a"
mkdir -p "$JNI_LIBS_DIR"

# Set up environment variables for cross-compilation (matching GitHub Actions)
export CC_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
export CXX_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"
export AR_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
export CFLAGS_aarch64_linux_android="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
export CXXFLAGS_aarch64_linux_android="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_linux_android="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot -I$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include -I$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/aarch64-linux-android"

# CRITICAL: Do NOT set AWS_LC_SYS_NO_ASM=1 for release builds!
# GitHub Actions does not set this variable, and it causes build failures with aws-lc-sys

# NEW: Set Android NDK environment variables that aws-lc-sys expects
export ANDROID_NDK_HOME="$ANDROID_NDK_HOME"
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
export ANDROID_NDK="$ANDROID_NDK_HOME"

echo "Cleaning Rust build cache..."
rm -rf rust/ecashapp/target

cd "$RUST_DIR"
cargo ndk -t arm64-v8a -o "$JNI_LIBS_DIR" build --release --target aarch64-linux-android

# Move .so files to correct location
find "$JNI_LIBS_DIR" -type f -name '*.so' -exec mv {} "$JNI_LIBS_DIR" \;
find "$JNI_LIBS_DIR" -type d -empty -delete

# Copy libc++_shared.so (required for Android)
cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "$JNI_LIBS_DIR/" 2>/dev/null || true

cd /workspace

# Build Flutter APK
echo "Building Flutter APK..."
flutter build apk --$BUILD_MODE

echo ""
echo "==================================="
echo "Build complete!"
echo "==================================="
echo "APK location: build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
