#!/bin/bash

# PopMatch App Runner Script
# This script ensures we're always running from the correct project directory

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the project directory
cd "$SCRIPT_DIR"

# Check if we're in the correct project directory
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: pubspec.yaml not found. Make sure you're in the PopMatch project directory."
    exit 1
fi

# Check if this is the main project (not a nested one)
if [ -d "popmatch" ]; then
    echo "Warning: Found nested 'popmatch' directory. This might cause confusion."
    echo "Consider removing the nested directory to avoid issues."
fi

echo "Running PopMatch app from: $(pwd)"
echo "Project structure verified ✓"

# Run the app with the specified device or default to iPhone 16 Plus
DEVICE=${1:-"iPhone 16 Plus"}
echo "Launching on device: $DEVICE"

flutter run -d "$DEVICE" 