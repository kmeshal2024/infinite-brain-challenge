#!/bin/bash
set -e

echo "=== Infinite Brain Challenge Setup ==="

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found. Install from https://flutter.dev"
    exit 1
fi

echo "Flutter:"
flutter --version | head -1

# Generate platform dirs if missing
if [ ! -d "android" ]; then
    echo ""
    echo "Generating platform scaffolding..."
    flutter create --org com.infinitebrain --project-name infinite_brain_challenge .
fi

# Get deps
echo ""
echo "Getting dependencies..."
flutter pub get

# Analyze
echo ""
echo "Running analysis..."
flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 || true

echo ""
echo "=== Setup complete ==="
echo "Run: flutter run"
