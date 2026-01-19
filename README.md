# 🎬 PopMatch

A Flutter-based movie and TV show discovery app with AI-powered personalized recommendations.

## ✨ Features

- **Swipe-Based Discovery**: Swipe through movies and TV shows to discover new content
- **AI-Powered Recommendations**: Advanced recommendation system with:
  - Adaptive hybrid weighting
  - Content-based filtering
  - Collaborative filtering
  - Embedding-based similarity
  - Contextual recommendations (time, mood, season)
  - Real-time learning from user behavior
- **Dual Content Support**: Browse both movies and TV shows
- **Personalized Profiles**: Track your favorites, watchlist, and preferences
- **Smart Filtering**: Filter by genre, mood, platform, and more
- **Firebase Authentication**: Secure email/password and Google Sign-In
- **Beautiful UI**: Retro cinema aesthetic with modern design

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- iOS 12.0+ / Android API 21+
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/PopMatch.git
cd PopMatch
```

2. Install dependencies:
```bash
flutter pub get
cd ios && pod install && cd ..
```

3. Configure Firebase (optional):
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Configure Firebase in `lib/services/firebase_config.dart`

4. Run the app:
```bash
flutter run
```

## 📱 Screenshots

*Add screenshots here*

## 🏗️ Architecture

### Key Components

- **Providers**: State management using Provider pattern
  - `AuthProvider`: User authentication and data
  - `MovieProvider`: Movie data and recommendations
  - `ShowProvider`: TV show data and recommendations
  - `StreamingProvider`: Streaming platform data

- **Services**:
  - `TMDBService`: The Movie Database API integration
  - `RecommendationMetricsService`: Track recommendation quality
  - `AdaptiveWeightingService`: Learn optimal algorithm weights
  - `MovieEmbeddingService`: Semantic similarity calculations
  - `BehaviorTrackingService`: User interaction tracking

- **Models**:
  - `Movie`: Movie data model
  - `TvShow`: TV show data model
  - `User`: User profile and preferences

## 🧠 Recommendation System

PopMatch uses a sophisticated hybrid recommendation system:

1. **Content-Based Filtering**: Genre, actor, director matching
2. **Collaborative Filtering**: User-item interactions
3. **Embedding Similarity**: Semantic similarity from descriptions
4. **Contextual Recommendations**: Time, mood, seasonal awareness
5. **Adaptive Learning**: Weights adjust based on user feedback

### Metrics Tracked

- Precision@K
- Recall@K
- NDCG@K
- Diversity
- Novelty
- Coverage

## 🔧 Configuration

### TMDB API Key

The app uses The Movie Database (TMDB) API. You'll need to:
1. Get an API key from [TMDB](https://www.themoviedb.org/settings/api)
2. Update `lib/services/tmdb_service.dart` with your API key

### Firebase Setup

See `FIREBASE_AUTH_SETUP_COMPLETE.md` for detailed Firebase configuration.

## 📦 Dependencies

Key dependencies:
- `provider`: State management
- `firebase_auth`: Authentication
- `google_sign_in`: Google Sign-In
- `shared_preferences`: Local storage
- `cached_network_image`: Image caching
- `flutter_card_swiper`: Swipe interface
- `cloud_functions`: Firebase Cloud Functions

See `pubspec.yaml` for complete list.

## 🧪 Testing

```bash
flutter test
```

## 📄 License

[Add your license here]

## 👤 Author

[Your Name]

## 🙏 Acknowledgments

- [The Movie Database (TMDB)](https://www.themoviedb.org/) for movie data
- Flutter team for the amazing framework
