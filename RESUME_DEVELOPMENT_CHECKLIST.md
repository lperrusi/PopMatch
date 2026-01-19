# Resume Development Checklist

Use this checklist when you're ready to resume development on PopMatch.

## 🔍 Pre-Development Verification

### Environment Setup
- [ ] Verify Flutter version is 3.2.3+
  ```bash
  flutter --version
  ```
- [ ] Run Flutter doctor to check setup
  ```bash
  flutter doctor
  ```
- [ ] Navigate to project directory
  ```bash
  cd /Users/lucasperrusi/Projects/PopMatch
  ```

### Dependencies
- [ ] Install/update dependencies
  ```bash
  flutter pub get
  ```
- [ ] Check for dependency conflicts
  ```bash
  flutter pub outdated
  ```

### Configuration Files

#### Firebase Configuration
- [ ] Check if `android/app/google-services.json` exists
- [ ] Check if `ios/Runner/GoogleService-Info.plist` exists
- [ ] If missing, create Firebase project and download config files
- [ ] Verify Firebase services are enabled:
  - [ ] Authentication (Email/Password, Google, Apple)
  - [ ] Firestore Database
  - [ ] Cloud Messaging (for notifications)

#### TMDB API Key
- [ ] Check current API key in `lib/services/tmdb_service.dart` (line 11)
- [ ] Verify API key is valid (not placeholder)
- [ ] Test API key by running app and checking movie loading
- [ ] Consider moving to environment variables for security

## 🚀 Quick Test Run

### Basic Functionality Test
- [ ] Run the app
  ```bash
  flutter run
  # or use convenience script
  ./run_app.sh
  ```
- [ ] Test splash screen appears
- [ ] Test authentication flow (login/register)
- [ ] Test movie loading on home/swipe screen
- [ ] Test swipe functionality
- [ ] Test search functionality
- [ ] Test watchlist functionality

### Error Check
- [ ] Check console for errors
- [ ] Check for runtime exceptions
- [ ] Verify API calls are working
- [ ] Check Firebase connectivity

## 🔧 Immediate Fixes (If Needed)

### If App Doesn't Run
- [ ] Clean build
  ```bash
  flutter clean
  flutter pub get
  ```
- [ ] For iOS: Update pods
  ```bash
  cd ios && pod install && cd ..
  ```
- [ ] Check for syntax errors
  ```bash
  flutter analyze
  ```

### If Firebase Issues
- [ ] Verify Firebase config files are in correct location
- [ ] Check Firebase project is active
- [ ] Verify authentication methods are enabled
- [ ] Check Firestore rules allow authenticated access

### If TMDB API Issues
- [ ] Verify API key is correct
- [ ] Check internet connection
- [ ] Verify API key hasn't expired
- [ ] Check TMDB API status

## 📋 Code Review Tasks

### Check Current State
- [ ] Review recent changes (if any)
- [ ] Check for uncommitted changes
  ```bash
  git status
  ```
- [ ] Review any TODO comments in code
- [ ] Check test status
  ```bash
  flutter test
  ```

### Identify Issues
- [ ] Run linter
  ```bash
  flutter analyze
  ```
- [ ] Note any critical errors
- [ ] List any warnings that need attention
- [ ] Check widget test failures

## 🎯 Development Priorities

### High Priority (Do First)
1. [ ] Fix any critical runtime errors
2. [ ] Ensure app runs successfully
3. [ ] Verify core features work
4. [ ] Fix widget test failures (if blocking)

### Medium Priority (Do Soon)
1. [ ] Complete TODO items in code
2. [ ] Fix linting warnings
3. [ ] Improve test coverage
4. [ ] Add missing documentation

### Low Priority (Do Later)
1. [ ] Implement future enhancements
2. [ ] Optimize performance
3. [ ] Add new features
4. [ ] Improve UI/UX

## 📝 Recommended First Steps

### Option 1: Quick Start (If Everything Works)
1. Run the app
2. Test all main features
3. Note any issues
4. Fix critical bugs
5. Continue with new features

### Option 2: Full Setup (If Starting Fresh)
1. Verify all prerequisites
2. Set up Firebase project
3. Configure TMDB API key
4. Run app and test
5. Fix any configuration issues
6. Review codebase structure
7. Plan next development phase

### Option 3: Debug Mode (If Issues Found)
1. Run `flutter analyze` to find errors
2. Check console logs when running app
3. Review error messages
4. Fix critical issues first
5. Test after each fix
6. Document fixes made

## 🔍 Key Files to Check

### Configuration Files
- [ ] `pubspec.yaml` - Dependencies
- [ ] `lib/services/tmdb_service.dart` - API key
- [ ] `lib/services/firebase_config.dart` - Firebase setup
- [ ] `lib/main.dart` - App initialization

### Critical Services
- [ ] `lib/services/auth_service.dart` - Authentication
- [ ] `lib/services/tmdb_service.dart` - Movie data
- [ ] `lib/services/recommendations_service.dart` - Recommendations

### Main Screens
- [ ] `lib/screens/splash_screen.dart` - Entry point
- [ ] `lib/screens/auth/login_screen.dart` - Authentication
- [ ] `lib/screens/home/home_screen.dart` - Main app

## 📚 Documentation Review

- [ ] Read `PROJECT_STATUS.md` for current state
- [ ] Review `README.md` for overview
- [ ] Check `SETUP.md` for setup instructions
- [ ] Review feature documentation as needed

## ✅ Ready to Develop Checklist

Before starting new development work:

- [ ] App runs without critical errors
- [ ] Core features are working
- [ ] Test suite passes (or known issues documented)
- [ ] Configuration is complete
- [ ] Development environment is set up
- [ ] Current project state is understood
- [ ] Next development goals are clear

## 🆘 If You Get Stuck

1. **Check Documentation**
   - Read relevant .md files
   - Check inline code comments
   - Review error messages carefully

2. **Common Solutions**
   - Run `flutter clean && flutter pub get`
   - Delete `ios/Podfile.lock` and reinstall pods
   - Check Firebase configuration
   - Verify API keys are correct

3. **Debug Steps**
   - Enable verbose logging
   - Check console output
   - Review error stack traces
   - Test individual components

---

**Quick Command Reference:**
```bash
# Clean and rebuild
flutter clean && flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Check devices
flutter devices

# Update iOS pods
cd ios && pod install && cd ..
```

**Next Step**: Once checklist is complete, proceed with your planned development tasks!
