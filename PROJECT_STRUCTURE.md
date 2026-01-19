# PopMatch Project Structure

## Correct Project Directory

The main PopMatch project is located at:
```
/Users/lucasperrusi/Projects/PopMatch/
```

## Project Structure

```
PopMatch/
├── lib/                    # Main source code
├── assets/                 # Images, icons, etc.
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── test/                  # Test files
├── pubspec.yaml           # Dependencies and project config
├── pubspec.lock           # Locked dependency versions
├── README.md              # Project documentation
├── run_app.sh            # Convenience script to run the app
└── ... (other files)
```

## Running the App

### Option 1: Using the convenience script
```bash
./run_app.sh                    # Run on iPhone 16 Plus (default)
./run_app.sh "iPhone Lucas"     # Run on specific device
```

### Option 2: Manual commands
```bash
cd /Users/lucasperrusi/Projects/PopMatch
flutter run -d "iPhone 16 Plus"
```

## Important Notes

1. **Always run from the main project directory**: `/Users/lucasperrusi/Projects/PopMatch/`
2. **Never run from nested directories**: Avoid running from any subdirectories
3. **Check your current directory**: Use `pwd` to verify you're in the correct location
4. **Verify project structure**: Ensure `pubspec.yaml` exists in your current directory

## Common Issues

### Issue: "No application found for TargetPlatform.ios"
**Cause**: Running from wrong directory or missing iOS configuration
**Solution**: 
1. Ensure you're in `/Users/lucasperrusi/Projects/PopMatch/`
2. Run `flutter clean && flutter pub get`

### Issue: "Can't find ')' to match '('"
**Cause**: Syntax errors in code
**Solution**: 
1. Run `flutter analyze` to check for errors
2. Fix any syntax issues in the code

### Issue: CocoaPods dependency conflicts
**Cause**: iOS dependency version conflicts
**Solution**:
1. Run `flutter clean`
2. Delete `ios/Podfile.lock`
3. Run `flutter pub get`
4. Run `cd ios && pod install`

## Development Workflow

1. **Start development**:
   ```bash
   cd /Users/lucasperrusi/Projects/PopMatch
   ./run_app.sh
   ```

2. **Make changes** to files in `lib/`

3. **Hot reload** (if app is running): Press `r` in the terminal

4. **Hot restart** (if app is running): Press `R` in the terminal

5. **Stop the app**: Press `q` in the terminal

## Video/Trailer Fix

The video trailer issue has been fixed by:
- Correcting the API key check in `lib/services/tmdb_service.dart`
- Improving fallback trailer generation with more diverse trailer keys
- Adding specific trailers for popular recent movies

The app now uses real trailers from TMDB API when available and falls back to a varied selection of realistic trailers. 