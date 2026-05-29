# Movie Suggestion Algorithm Analysis

## Overview

The PopMatch app uses a sophisticated **hybrid recommendation system** that combines multiple machine learning and recommendation techniques to provide personalized movie suggestions. The algorithm is implemented primarily in `movie_provider.dart` with supporting services.

---

## Algorithm Architecture

### Main Entry Point
**File**: `lib/providers/movie_provider.dart`
**Method**: `loadPersonalizedRecommendations()`

The algorithm follows a multi-stage process:

1. **Movie Discovery** - Gathers candidate movies from multiple sources
2. **Scoring** - Scores each movie using weighted factors
3. **Filtering** - Applies platform filters and removes duplicates
4. **Diversity** - Ensures variety in recommendations

---

## Stage 1: Movie Discovery Strategies

The algorithm uses **4 main strategies** to discover candidate movies:

### Strategy 1: Genre-Based Discovery (Primary)
- Uses user's top 3 preferred genres (or swipe filter genres)
- Combines genres from selected moods if any
- Prefers movies from last 15 years
- Respects user's rating preferences (min/max)

```dart
// Lines 671-694 in movie_provider.dart
final discoveredMovies = await _tmdbService.discoverMovies(
  genres: finalGenres,
  minYear: currentYear - 15,
  minRating: preferences.preferredMinRating,
  maxRating: preferences.preferredMaxRating,
);
```

### Strategy 2: Similar Movies from Liked Movies
- Analyzes top 8 most recent liked movies
- Gets similar movies and recommendations for each
- Combines results from both sources

```dart
// Lines 696-722 in movie_provider.dart
for (final movieIdStr in likedMoviesToAnalyze) {
  final similarMovies = await _tmdbService.getSimilarMovies(movieId);
  final recommendedMovies = await _tmdbService.getMovieRecommendations(movieId);
}
```

### Strategy 3: Actor/Director-Based Discovery
- Gets movies from top 5 preferred actors
- Gets movies from top 3 preferred directors
- Only used if recommendations < 30 movies

### Strategy 4: Genre Fallback
- If still < 20 recommendations, adds popular movies from preferred genres
- Fallback: Adds popular movies if < 10 recommendations

---

## Stage 2: Multi-Factor Scoring System

Each discovered movie is scored using a **weighted hybrid approach**:

### Base Score (50% of total weight)

The base score considers:

1. **Genre Match (40% of base)**
   - Calculates how many of the movie's genres match user's top genres
   - Formula: `(matchingGenres / totalPreferredGenres) * 40.0`

2. **Actor Match (25% of base)**
   - Verifies actors actually appear in the movie (via credits API)
   - Only counts top 10 cast members
   - Formula: `(matchingActors / totalPreferredActors) * 25.0`

3. **Director Match (20% of base)**
   - Verifies directors actually appear in credits
   - Formula: `(matchingDirectors / totalPreferredDirectors) * 20.0`

4. **Rating Match (10% of base)**
   - Checks if movie rating falls within user's preferred range
   - Gives partial credit for close ratings

5. **Recency Bonus (5% of base)**
   - Prefers recent movies:
     - ≤ 5 years: +5.0 points
     - ≤ 10 years: +3.0 points
     - ≤ 15 years: +1.0 points

**Final Base Score**: `baseScore * 0.5` (50% of total)

### Enhanced Scoring Factors (50% of total weight)

#### 1. Contextual Recommendations (15% weight)
**Service**: `ContextualRecommendationService`

Considers:
- **Time of day**:
  - Morning (6-12): Prefers comedy, animation; avoids horror
  - Afternoon (12-17): Neutral
  - Evening (17-22): Prefers action, drama, thriller
  - Night (22-6): Prefers horror, thriller; avoids animation
- **Weekend vs Weekday**:
  - Weekend: Prefers longer movies (>120 min), blockbusters
  - Weekday: Prefers shorter movies (<100 min)
- **Mood filters**: Multiplies weight if movie matches selected moods

```dart
// Lines 1024-1030 in movie_provider.dart
final contextualWeight = _contextualService.getContextualWeight(
  movie,
  currentMoods: currentMoods,
  currentTime: currentTime,
);
score += (baseScore * 0.15) * contextualWeight;
```

#### 2. Behavior Tracking (10% weight)
**Service**: `BehaviorTrackingService`

Tracks:
- Detail view counts (how many times user viewed movie details)
- Time spent viewing details
- Movie revisits (swiping back)
- Swipe speed (slow = considering = interest)
- Explicit likes/dislikes

Converts interest score to weight multiplier (0.5-1.5 range)

```dart
// Lines 1032-1034 in movie_provider.dart
final behaviorWeight = _behaviorService.getBehaviorWeight(movie.id);
score += (baseScore * 0.10) * behaviorWeight;
```

#### 3. Embedding-Based Similarity (15% weight)
**Service**: `MovieEmbeddingService`

Creates 50-dimensional embeddings based on:
- Genres (dimensions 0-19)
- Rating (dimensions 20-24)
- Year (dimensions 25-29)
- Popularity (dimensions 30-34)
- Runtime (dimensions 35-39)
- Vote count (dimensions 40-44)
- Language (dimensions 45-49)

Uses cosine similarity to find movies similar to user's liked movies.

```dart
// Lines 1036-1040 in movie_provider.dart
if (likedMovies.isNotEmpty) {
  final embeddingWeight = _embeddingService.getEmbeddingWeight(movie, likedMovies);
  score += (baseScore * 0.15) * embeddingWeight;
}
```

#### 4. Collaborative Filtering (5% weight)
**Service**: `CollaborativeFilteringService`

Tracks "users who liked X also liked Y" patterns:
- Builds co-occurrence matrix of movie pairs
- Normalizes by popularity to avoid bias
- Uses item-based collaborative filtering

```dart
// Lines 1042-1047 in movie_provider.dart
final collaborativeWeight = _collaborativeService.getCollaborativeWeight(
  movie.id,
  userLikedMovieIds,
);
score += (baseScore * 0.05) * collaborativeWeight;
```

#### 5. Deep Learning (5% weight)
**Service**: `DeepLearningService`

**Current Status**: Uses fallback scoring (model not yet implemented)

Fallback considers:
- Genre preferences
- High ratings (>7.0)
- High popularity (>50)

```dart
// Lines 1049-1056 in movie_provider.dart
try {
  final deepLearningWeight = await _deepLearningService.getDeepLearningWeight(user, movie);
  score += (baseScore * 0.05) * deepLearningWeight;
} catch (e) {
  score += baseScore * 0.05; // Neutral weight on error
}
```

---

## Stage 3: Filtering

### User History Filter
- Removes movies user has already liked
- Removes movies user has disliked
- Applied before scoring

### Platform Filter
- If user selected streaming platforms, filters to show only movies available on those platforms
- Falls back to top 10 scored movies if filtering removes too many

### Diversity Filter
**Method**: `_applyDiversityFilter()`

Prevents genre clustering:
- Tracks genres used in last 5 movies
- Skips movies with >2 overlapping genres if list has ≥5 movies
- After 20 diverse movies, adds remaining without strict filtering

---

## User Preference Analysis

**Service**: `UserPreferenceAnalyzer`

Analyzes user's liked movies to extract:
- **Top 5 genres** (by frequency)
- **Top 10 actors** (from cast of liked movies)
- **Top 5 directors** (from crew of liked movies)
- **Rating range** (25th-75th percentile)
- **Default preferences** if no liked movies (from onboarding or defaults)

---

## Performance Optimizations

1. **Parallel Credit Fetching**: Fetches movie credits in parallel (up to 50 movies) with 5-second timeout
2. **Caching**: Embeddings are cached per movie
3. **Limits**: Analyzes max 30 liked movies, top 8 for similar movies
4. **Background Loading**: Supports background loading to avoid UI disruption

---

## Weight Distribution Summary

| Factor | Weight | Description |
|--------|--------|-------------|
| **Base Score** | 50% | Genre, actor, director, rating, recency |
| Contextual | 15% | Time, mood, weekend/weekday |
| Embedding | 15% | Semantic similarity to liked movies |
| Behavior | 10% | User interaction patterns |
| Collaborative | 5% | "Users who liked X also liked Y" |
| Deep Learning | 5% | ML predictions (currently fallback) |

---

## Data Flow

```
User Action
    ↓
loadPersonalizedRecommendations()
    ↓
1. Analyze User Preferences (UserPreferenceAnalyzer)
    ↓
2. Discover Movies (4 strategies)
    ↓
3. Score Movies (_scoreMovies)
    ├─ Base Score (50%)
    ├─ Contextual Weight (15%)
    ├─ Behavior Weight (10%)
    ├─ Embedding Weight (15%)
    ├─ Collaborative Weight (5%)
    └─ Deep Learning Weight (5%)
    ↓
4. Filter (platform, history)
    ↓
5. Apply Diversity Filter
    ↓
6. Return Ranked List
```

---

## Strengths

1. **Multi-faceted approach**: Combines content-based, collaborative, and contextual filtering
2. **Real-time learning**: Behavior tracking adapts to user interactions
3. **Verification**: Checks actors/directors actually appear in movies
4. **Diversity**: Prevents genre clustering
5. **Context-aware**: Considers time, mood, and user behavior
6. **Fallback systems**: Graceful degradation if services fail

---

## Potential Improvements

1. **Deep Learning**: Currently using fallback - could implement actual ML model
2. **Collaborative Filtering**: Limited by local data - could benefit from server-side aggregation
3. **Cold Start**: New users get default preferences - could improve onboarding
4. **Performance**: Some API calls could be batched or cached better
5. **Weight Tuning**: Weights are fixed - could be A/B tested or learned

---

## Key Files

- `lib/providers/movie_provider.dart` - Main algorithm orchestration
- `lib/services/user_preference_analyzer.dart` - Preference extraction
- `lib/services/contextual_recommendation_service.dart` - Time/mood context
- `lib/services/behavior_tracking_service.dart` - User behavior tracking
- `lib/services/movie_embedding_service.dart` - Semantic similarity
- `lib/services/collaborative_filtering_service.dart` - Collaborative filtering
- `lib/services/deep_learning_service.dart` - ML predictions (fallback)

---

## Testing Recommendations

1. Test with users who have 0, 3, 10, 30+ liked movies
2. Test different times of day and moods
3. Test platform filtering
4. Verify diversity filter prevents clustering
5. Test behavior tracking with various interaction patterns
6. Measure recommendation quality (precision, recall, diversity)
