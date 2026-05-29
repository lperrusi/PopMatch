---
name: flutter-commands
description: Use when the user asks how to run the app, build it, install dependencies, clean the build, or run static analysis. Trigger phrases: "run the app", "how do I build", "flutter analyze", "clean build", "pub get", "pod install".
argument-hint: "[run|build|analyze|clean|deps]"
allowed-tools: [Bash]
---

## Run the app
```bash
flutter run
flutter run -d "iPhone 16 Plus"      # specific device
./run_app.sh [optional-device-name]  # convenience script
```

## Static analysis
```bash
flutter analyze
```

## Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..       # after adding iOS-specific native deps
```

## Clean build
```bash
flutter clean && flutter pub get
```
