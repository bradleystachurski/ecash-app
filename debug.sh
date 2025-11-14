#!/bin/bash

echo "==================================="
echo "Flutter Docker Build Debug Info"
echo "==================================="
echo ""

# Find project root (assuming we're running from it or a subdirectory)
if [ -f "pubspec.yaml" ]; then
    PROJECT_ROOT="."
else
    echo "ERROR: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

echo "Project Root: $(pwd)"
echo ""

echo "==================================="
echo "1. DOCKERFILE(S)"
echo "==================================="
find . -name "Dockerfile*" -o -name "*.dockerfile" 2>/dev/null | while read -r file; do
    echo ""
    echo "--- File: $file ---"
    cat "$file"
    echo ""
done

echo "==================================="
echo "2. DOCKER COMPOSE FILES"
echo "==================================="
find . -name "docker-compose*.yml" -o -name "docker-compose*.yaml" 2>/dev/null | while read -r file; do
    echo ""
    echo "--- File: $file ---"
    cat "$file"
    echo ""
done

echo "==================================="
echo "3. GITHUB WORKFLOWS"
echo "==================================="
if [ -d ".github/workflows" ]; then
    for file in .github/workflows/*.yml .github/workflows/*.yaml; do
        if [ -f "$file" ]; then
            echo ""
            echo "--- File: $file ---"
            cat "$file"
            echo ""
        fi
    done
else
    echo "No .github/workflows directory found"
fi

echo "==================================="
echo "4. GITHUB ACTIONS (CUSTOM)"
echo "==================================="
if [ -d ".github/actions" ]; then
    find .github/actions -type f \( -name "action.yml" -o -name "action.yaml" \) | while read -r file; do
        echo ""
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done

    # Also find any shell scripts in actions
    find .github/actions -type f -name "*.sh" | while read -r file; do
        echo ""
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
else
    echo "No .github/actions directory found"
fi

echo "==================================="
echo "5. BUILD SCRIPTS"
echo "==================================="
if [ -d "scripts" ]; then
    for file in scripts/*.sh; do
        if [ -f "$file" ]; then
            echo ""
            echo "--- File: $file ---"
            cat "$file"
            echo ""
        fi
    done
else
    echo "No scripts directory found"
fi

# Also check for other shell scripts
find . -type f \( -name "build*.sh" -o -name "*build*.sh" \) ! -path "./.*" ! -path "*/node_modules/*" ! -path "*/build/*" ! -path "*/scripts/*" ! -path "*/.github/*" 2>/dev/null | while read -r file; do
    echo ""
    echo "--- File: $file ---"
    cat "$file"
    echo ""
done

echo "==================================="
echo "6. PUBSPEC.YAML"
echo "==================================="
if [ -f "pubspec.yaml" ]; then
    cat pubspec.yaml
else
    echo "pubspec.yaml not found!"
fi
echo ""

echo "==================================="
echo "7. ANDROID GRADLE FILES"
echo "==================================="
# Check for both .gradle and .gradle.kts files
if [ -f "android/build.gradle" ]; then
    echo "--- android/build.gradle ---"
    cat android/build.gradle
    echo ""
elif [ -f "android/build.gradle.kts" ]; then
    echo "--- android/build.gradle.kts ---"
    cat android/build.gradle.kts
    echo ""
else
    echo "android/build.gradle(.kts) not found"
fi

if [ -f "android/app/build.gradle" ]; then
    echo "--- android/app/build.gradle ---"
    cat android/app/build.gradle
    echo ""
elif [ -f "android/app/build.gradle.kts" ]; then
    echo "--- android/app/build.gradle.kts ---"
    cat android/app/build.gradle.kts
    echo ""
else
    echo "android/app/build.gradle(.kts) not found"
fi

if [ -f "android/gradle.properties" ]; then
    echo "--- android/gradle.properties ---"
    cat android/gradle.properties
    echo ""
fi

if [ -f "android/settings.gradle" ]; then
    echo "--- android/settings.gradle ---"
    cat android/settings.gradle
    echo ""
elif [ -f "android/settings.gradle.kts" ]; then
    echo "--- android/settings.gradle.kts ---"
    cat android/settings.gradle.kts
    echo ""
fi

if [ -f "android/gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "--- android/gradle/wrapper/gradle-wrapper.properties ---"
    cat android/gradle/wrapper/gradle-wrapper.properties
    echo ""
fi

echo "==================================="
echo "8. NIX FLAKE FILES"
echo "==================================="
if [ -f "flake.nix" ]; then
    echo "--- flake.nix ---"
    cat flake.nix
    echo ""
else
    echo "flake.nix not found"
fi

if [ -f "flake.lock" ]; then
    echo "--- flake.lock (first 100 lines) ---"
    head -100 flake.lock
    echo ""
    echo "(truncated - full file has $(wc -l < flake.lock) lines)"
    echo ""
fi

echo "==================================="
echo "9. PROJECT STRUCTURE"
echo "==================================="
echo "Directory tree (max depth 3, excluding common ignore dirs):"
tree -L 3 -I 'node_modules|.git|build|.dart_tool|.idea|*.iml|.gradle' 2>/dev/null || find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/.dart_tool/*' -not -path '*/.gradle/*' | head -100

echo ""
echo "==================================="
echo "10. FLUTTER/RUST BRIDGE FILES"
echo "==================================="
find . -name "flutter_rust_bridge*.yaml" -o -name "frb.yaml" 2>/dev/null | while read -r file; do
    echo ""
    echo "--- File: $file ---"
    cat "$file"
    echo ""
done

echo "==================================="
echo "11. MAKEFILE / JUSTFILE"
echo "==================================="
if [ -f "Makefile" ]; then
    echo "--- Makefile ---"
    cat Makefile
    echo ""
fi

if [ -f "justfile" ]; then
    echo "--- justfile ---"
    cat justfile
    echo ""
fi

echo "==================================="
echo "12. ENVIRONMENT CONFIGS"
echo "==================================="
if [ -f ".env.example" ]; then
    echo "--- .env.example ---"
    cat .env.example
    echo ""
fi

if [ -f ".tool-versions" ]; then
    echo "--- .tool-versions ---"
    cat .tool-versions
    echo ""
fi

echo "==================================="
echo "13. README / DOCS"
echo "==================================="
if [ -f "README.md" ]; then
    echo "--- README.md (first 200 lines) ---"
    head -200 README.md
    echo ""
fi

if [ -f "BUILDING.md" ] || [ -f "BUILD.md" ]; then
    for file in BUILDING.md BUILD.md; do
        if [ -f "$file" ]; then
            echo "--- $file ---"
            cat "$file"
            echo ""
        fi
    done
fi

echo "==================================="
echo "14. CURRENT DOCKER BUILD ERROR"
echo "==================================="
echo "If you've tried building with Docker and got an error, please run:"
echo "  cd docker && bash build-apk.sh 2>&1 | tail -100"
echo "Or paste the last 100 lines of your error here."
echo ""

echo ""
echo "==================================="
echo "SCRIPT COMPLETE"
echo "==================================="
echo "Please run: bash debug.sh |& tee results.txt"
echo "Then upload results.txt"
