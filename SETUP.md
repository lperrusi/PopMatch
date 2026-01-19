# Quick Setup Guide for PopMatch

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK 3.2.3+
- Firebase project
- TMDB API key

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Download config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### 4. Configure TMDB API
1. Get API key from [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)
2. Replace `YOUR_TMDB_API_KEY` in `lib/services/tmdb_service.dart`

### 5. Run the App
```bash
flutter run
```

## 🔧 Configuration Files

### Firebase Configuration
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`

### API Configuration
- **TMDB API Key**: `lib/services/tmdb_service.dart` (line 6)

## 📱 Features Ready to Use

✅ **Authentication**: Email/password login & registration  
✅ **Movie Discovery**: Swipe interface with Tinder-style cards  
✅ **Watchlist**: Save and manage your movie list  
✅ **Filtering**: Filter by genre and year  
✅ **Search**: Search movies by title  
✅ **Movie Details**: Comprehensive movie information  
✅ **Sharing**: Share movie recommendations  
✅ **Dark Mode**: Automatic theme switching  
✅ **User Profile**: View statistics and liked movies  

## 🎨 Customization

### Colors
Edit `lib/utils/theme.dart` to change the app's color scheme:
- Primary Red: `AppTheme.primaryRed`
- Dark Red: `AppTheme.darkRed`
- Background colors for light/dark themes

### Features
- Add new movie sources in `lib/services/tmdb_service.dart`
- Modify UI components in `lib/widgets/`
- Update state management in `lib/providers/`

## 🐛 Common Issues

### Firebase Issues
```bash
# If you get Firebase configuration errors:
flutter clean
flutter pub get
```

### TMDB API Issues
- Verify API key is correct
- Check internet connection
- Ensure API key has proper permissions

### Build Issues
```bash
# Clean and rebuild:
flutter clean
flutter pub get
flutter run
```

## 📋 Next Steps

1. **Test the app** on both Android and iOS
2. **Customize the theme** to match your brand
3. **Add your Firebase configuration**
4. **Replace TMDB API key** with your own
5. **Deploy to app stores** when ready

## 🆘 Need Help?

- Check the main [README.md](README.md) for detailed documentation
- Review Firebase and TMDB documentation
- Create an issue in the repository

---

**Happy coding! 🎬** 