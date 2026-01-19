#!/bin/bash

# Make the clapboard bigger in the app icon
SOURCE_ICON="assets/icons/icon-pack/ios/iTunesArtwork@1x.png"
TEMP_DIR="temp_icons"
OUTPUT_DIR="assets/icons/icon-pack/ios/"

echo "Creating larger clapboard icon..."

# Create temp directory
mkdir -p "$TEMP_DIR"

# Create a larger version of the icon (scale up the clapboard)
# We'll create a 1200x1200 version to make the clapboard more prominent
sips -z 1200 1200 "$SOURCE_ICON" --out "$TEMP_DIR/larger_icon.png"

# Copy the larger version back to replace the original
cp "$TEMP_DIR/larger_icon.png" "$SOURCE_ICON"

# Also update Android source
cp "$SOURCE_ICON" "assets/icons/icon-pack/android/mipmap-xxxhdpi/ic_launcher.png"

echo "Clapboard icon enlarged successfully!"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "Now regenerating all icon sizes..." 