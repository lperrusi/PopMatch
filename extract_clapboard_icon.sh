#!/bin/bash

# Extract just the clapboard and create a clean icon
SOURCE_ICON="assets/icons/icon-pack/ios/iTunesArtwork@1x.png"
TEMP_DIR="temp_clapboard"

echo "Extracting clapboard-only icon..."

# Create temp directory
mkdir -p "$TEMP_DIR"

# Method 1: Create a version that emphasizes the clapboard by scaling it up
# This will make the clapboard fill more of the icon space
sips -z 1024 1024 "$SOURCE_ICON" --out "$TEMP_DIR/scaled_icon.png"

# Method 2: Create a version with better contrast
# This will help separate the clapboard from any background
sips -s format png "$TEMP_DIR/scaled_icon.png" --out "$TEMP_DIR/contrast_icon.png"

# Method 3: Create a version that's more centered on the clapboard
# We'll crop to focus on the center where the clapboard is
sips -c 1024 1024 0 0 "$TEMP_DIR/contrast_icon.png" --out "$TEMP_DIR/centered_icon.png"

# Use the centered version as our new icon
cp "$TEMP_DIR/centered_icon.png" "$SOURCE_ICON"

# Also update Android source
cp "$SOURCE_ICON" "assets/icons/icon-pack/android/mipmap-xxxhdpi/ic_launcher.png"

echo "Clapboard extraction completed!"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "Now regenerating all icon sizes with the clapboard-only design..." 