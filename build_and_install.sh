#!/bin/bash

# PopMatch Build and Install Script
# This script ensures proper build order and handles simulator setup

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 PopMatch Build and Install Script"
echo "===================================="

# Step 1: Clean and prepare
echo ""
echo "📦 Step 1: Cleaning and preparing..."
flutter clean
flutter pub get

# Step 2: Install CocoaPods
echo ""
echo "📦 Step 2: Installing CocoaPods dependencies..."
cd ios
pod install
cd ..

# Step 3: Boot simulator if not already booted
echo ""
echo "📱 Step 3: Checking simulator..."
SIMULATOR_NAME="iPhone 17 Pro"
SIMULATOR_ID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ Error: $SIMULATOR_NAME simulator not found"
    echo "Available simulators:"
    xcrun simctl list devices available | grep "iPhone"
    exit 1
fi

echo "Found simulator: $SIMULATOR_NAME ($SIMULATOR_ID)"

# Check if simulator is booted
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -oE '\(Booted|\(Shutdown\)')
if [[ "$SIMULATOR_STATE" == *"Shutdown"* ]]; then
    echo "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID" 2>&1 || true
    sleep 3
    open -a Simulator
    sleep 2
fi

# Step 4: Build Pods for simulator
echo ""
echo "🔨 Step 4: Building CocoaPods frameworks for simulator..."
cd ios
xcodebuild -workspace Runner.xcworkspace \
    -scheme Pods-Runner \
    -configuration Debug \
    -sdk iphonesimulator \
    -arch arm64 \
    clean build \
    CODE_SIGNING_ALLOWED=NO \
    > /tmp/pods_build.log 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Pods build failed. Check /tmp/pods_build.log"
    tail -30 /tmp/pods_build.log
    exit 1
fi
echo "✅ Pods built successfully"
cd ..

# Step 5: Build using xcodebuild directly (Flutter's build system has issues with simulator)
echo ""
echo "🚀 Step 5: Building app for simulator..."
cd ios
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    CODE_SIGNING_ALLOWED=NO \
    build \
    > /tmp/runner_build.log 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Runner build failed. Check /tmp/runner_build.log"
    tail -30 /tmp/runner_build.log
    exit 1
fi
echo "✅ App built successfully"
cd ..

# Step 6: Install on simulator
echo ""
echo "📱 Step 6: Installing app on simulator..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Runner.app" -path "*/iphonesimulator/*" -type d 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find build/ios -name "Runner.app" -path "*/iphonesimulator/*" -type d 2>/dev/null | head -1)
fi

if [ -n "$APP_PATH" ]; then
    echo "Found app at: $APP_PATH"
    xcrun simctl install "$SIMULATOR_ID" "$APP_PATH" 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ App installed successfully!"
        echo "Launching app..."
        xcrun simctl launch "$SIMULATOR_ID" com.example.popmatch 2>&1 || echo "Note: App may need Flutter tooling to run in debug mode"
    else
        echo "❌ Installation failed"
        exit 1
    fi
else
    echo "❌ Could not find built app"
    exit 1
fi

echo ""
echo "✅ Build and install complete!"
echo "The app should now be running on $SIMULATOR_NAME"
