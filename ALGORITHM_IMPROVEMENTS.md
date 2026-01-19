# Movie Suggestion Algorithm Improvements

## Problems Identified

### 1. **Flawed Base Score Calculation**
- **Issue**: Base score used absolute values (40, 25, 20 points) instead of normalized percentages
- **Impact**: Movies with partial matches got unfairly penalized
- **Fix**: Normalized all components to 0-1 range before weighting

### 2. **Multiplicative Scoring Penalty**
- **Issue**: All enhancement factors multiplied `baseScore`, so if baseScore was low, all other factors were also low
- **Impact**: Good movies with strong embeddings or behavior signals were still scored low if they didn't match genres perfectly
- **Fix**: Changed to **additive scoring** where each factor contributes independently (0-1 range)

### 3. **No Quality Filtering**
- **Issue**: Low-rated or unpopular movies could still score high if they matched genres
- **Impact**: Users saw bad movies in recommendations
- **Fix**: Added quality filter that removes movies with:
  - Rating < 5.0 (unless they have significant popularity)
  - Vote count < 10 (unless very recent)

### 4. **Broken Rating Scoring**
- **Issue**: Partial credit calculation `(10.0 - distance)` could give negative or very small values
- **Impact**: Movies close to preferred rating range didn't get proper credit
- **Fix**: Implemented smooth falloff with proper normalization

### 5. **Too Aggressive Diversity Filter**
- **Issue**: Skipped movies with 2+ genre overlaps, removing good recommendations
- **Impact**: Good movies were excluded just for genre similarity
- **Fix**: Made filter smarter - only skips if last 3 movies all had overlap AND movie is lower ranked

### 6. **Weak Enhancement Factors**
- **Issue**: Embedding and collaborative filtering weights were too low (5-15% of baseScore)
- **Impact**: These powerful signals weren't being used effectively
- **Fix**: Increased weights and made them independent (additive):
  - Embedding: 20% (was 15% of baseScore)
  - Contextual: 20% (was 15% of baseScore)
  - Behavior: 15% (was 10% of baseScore)
  - Collaborative: 5% (was 5% of baseScore)

## Key Changes

### Scoring System Overhaul

**Before (Multiplicative)**:
```dart
baseScore = genre(40) + actor(25) + director(20) + rating(10) + recency(5)
score = baseScore * 0.5 + (baseScore * 0.15 * contextualWeight) + ...
```

**After (Additive with Normalization)**:
```dart
genreScore = normalize(matchingGenres) // 0-1
actorScore = normalize(matchingActors) // 0-1
// ... all normalized to 0-1

baseScore = (genreScore * 0.30) + (actorScore * 0.20) + ... // 0-1
score = (baseScore * 0.40) + (contextualWeight * 0.20) + ... // Independent factors
```

### New Quality Score Component

Added a **quality score** (15% of base) that rewards:
- High ratings (70% weight)
- High popularity/vote count (30% weight)

This ensures good movies get boosted even if they don't match all preferences.

### Improved Weight Distribution

| Factor | Old Weight | New Weight | Change |
|--------|-----------|------------|--------|
| Base Score | 50% | 40% | Reduced (was too dominant) |
| Contextual | 15% of base | 20% independent | Increased |
| Embedding | 15% of base | 20% independent | Increased |
| Behavior | 10% of base | 15% independent | Increased |
| Collaborative | 5% of base | 5% independent | Same |
| Quality | 0% | 15% of base | NEW |
| Deep Learning | 5% of base | 0% | Disabled (was noise) |

## Expected Improvements

1. **Better Quality**: Low-rated movies filtered out before scoring
2. **More Balanced**: Enhancement factors now work independently
3. **Smarter Diversity**: Preserves quality while preventing clustering
4. **Better Matching**: Normalized scoring gives fair credit for partial matches
5. **Stronger Signals**: Embedding and behavior tracking have more impact

## Testing Recommendations

1. **Compare before/after**: Test with same user to see quality improvement
2. **Monitor metrics**:
   - Like rate (should increase)
   - Average rating of recommended movies (should increase)
   - User satisfaction (should improve)
3. **Edge cases**:
   - New users (few liked movies)
   - Users with diverse tastes
   - Users with very specific preferences

## Next Steps (Future Improvements)

1. **A/B Testing**: Test different weight combinations
2. **Machine Learning**: Train model to learn optimal weights per user
3. **Feedback Loop**: Use user likes/dislikes to adjust weights dynamically
4. **Cold Start**: Improve recommendations for new users
5. **Deep Learning**: Implement actual ML model instead of fallback
