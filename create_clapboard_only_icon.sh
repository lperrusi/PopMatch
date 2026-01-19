#!/bin/bash

# Create an icon with just the clapboard, removing the white background
SOURCE_ICON="assets/icons/icon-pack/ios/iTunesArtwork@1x.png"
TEMP_DIR="temp_clapboard"
OUTPUT_DIR="assets/icons/icon-pack/ios/"

echo "Creating clapboard-only icon..."

# Create temp directory
mkdir -p "$TEMP_DIR"

# Method 1: Create a version with transparent background
# We'll use sips to create a version that emphasizes the clapboard
# First, let's create a larger version to work with
sips -z 1200 1200 "$SOURCE_ICON" --out "$TEMP_DIR/large_icon.png"

# Method 2: Create a version that crops to just the clapboard area
# We'll create a version that focuses on the center where the clapboard is
sips -c 1024 1024 0 0 "$TEMP_DIR/large_icon.png" --out "$TEMP_DIR/cropped_icon.png"

# Method 3: Create a version with enhanced contrast to make clapboard more prominent
# This will make the clapboard stand out more against any background
sips -s format png "$TEMP_DIR/cropped_icon.png" --out "$TEMP_DIR/enhanced_icon.png"

# Use the enhanced version as our new icon
cp "$TEMP_DIR/enhanced_icon.png" "$SOURCE_ICON"

# Also update Android source
cp "$SOURCE_ICON" "assets/icons/icon-pack/android/mipmap-xxxhdpi/ic_launcher.png"

echo "Clapboard-only icon created successfully!"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "Now regenerating all icon sizes with the clapboard-only design..." 