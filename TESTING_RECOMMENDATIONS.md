# Testing Personalized Movie Recommendations

## Test Scenarios

### 1. New User (No Liked Movies)
**Expected Behavior:**
- Swipe screen should show popular movies
- System should use onboarding preferences (if available) or default genres

**Steps to Test:**
1. Create a new account or log in as a new user
2. Complete onboarding (select genres)
3. Go to swipe screen
4. Verify movies are shown (popular movies or based on onboarding genres)

### 2. User with 1-2 Liked Movies
**Expected Behavior:**
- Still shows popular movies (not enough data for personalization)
- System is learning but needs 3+ likes

**Steps to Test:**
1. Like 1-2 movies by swiping right
2. Verify movies continue to load (popular movies)
3. Check that liked movies are saved in user data

### 3. User with 3+ Liked Movies (Personalized Recommendations)
**Expected Behavior:**
- System analyzes liked movies
- Shows personalized recommendations based on:
  - Top genres from liked movies
  - Similar movies to liked ones
  - Preferred years and ratings

**Steps to Test:**
1. Like at least 3 movies (swipe right on 3+ movies)
2. Wait a moment for recommendations to refresh
3. Verify new movies shown match your preferences:
   - Similar genres to liked movies
   - Similar ratings
   - Movies you haven't seen before

### 4. Progressive Learning
**Expected Behavior:**
- Recommendations improve as you like more movies
- System adapts to your taste over time

**Steps to Test:**
1. Like 5 movies in one genre (e.g., Action)
2. Verify recommendations show more Action movies
3. Like 5 movies in a different genre (e.g., Comedy)
4. Verify recommendations now include both genres

### 5. Dislike Filtering
**Expected Behavior:**
- Disliked movies should not appear in recommendations
- System learns what you don't like

**Steps to Test:**
1. Dislike a few movies (swipe left)
2. Verify those movies don't appear again
3. Check that recommendations exclude disliked movies

### 6. Dynamic Refresh
**Expected Behavior:**
- When you like a movie, recommendations refresh in background
- New recommendations appear when running low on movies

**Steps to Test:**
1. Like a movie
2. Continue swiping
3. When you get to the last few movies, verify new recommendations load automatically

## Verification Points

### Check User Preferences Analysis
- Open debug console and check logs
- Verify preference analyzer extracts:
  - Top genres from liked movies
  - Preferred years
  - Rating preferences

### Check Recommendation Sources
The system uses 3 strategies:
1. **Discover API**: Movies matching user's top genres and preferences
2. **Similar/Recommended**: Movies similar to liked movies
3. **Genre-based**: Movies from preferred genres
4. **Fallback**: Popular movies if needed

### Check Filtering
- Liked movies should not appear in recommendations
- Disliked movies should not appear
- Already seen movies should be filtered out

## Expected Results

✅ **Success Indicators:**
- Movies shown match user's taste (genres, ratings)
- Recommendations improve after 3+ likes
- System adapts to user preferences
- No duplicate movies shown
- Smooth loading without freezing

❌ **Issues to Watch For:**
- Movies don't match preferences
- Recommendations don't improve over time
- Same movies appearing repeatedly
- App freezing during recommendation loading
- Empty movie list

## Debug Information

To see what's happening:
1. Check console logs for:
   - "Error discovering movies"
   - "Error fetching similar movies"
   - Preference analysis results

2. Verify user data:
   - `user.likedMovies` should contain movie IDs
   - `user.preferences['selectedGenres']` should contain genre IDs from onboarding

3. Check API calls:
   - TMDB Discover API should be called with genre filters
   - Similar/Recommendations API should be called for liked movies

