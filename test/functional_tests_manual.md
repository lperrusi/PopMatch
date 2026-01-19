# Functional Tests - Manual Testing Guide

## How to Run Functional Tests on Your iPhone

The app is now running on your iPhone. Follow this checklist to test all functionality:

---

## ✅ Test Checklist

### 1. Tutorial Screen Tests
- [ ] **First Launch**
  - App shows tutorial screens (3 images)
  - Images fill entire screen
  - Progress bar at top shows correct progress
  - "1 of 3", "2 of 3", "3 of 3" text in vintagePaper color
  - Back button appears on pages 2 and 3 (sepiaBrown background)
  - Next button works (sepiaBrown background)
  - "Get Started" button on page 3
  - No black area at bottom
  - No gradient overlays

- [ ] **Navigation**
  - Swipe between pages works
  - Back button navigates to previous page
  - Next button navigates to next page
  - "Get Started" navigates to Login screen

### 2. Login Screen Tests
- [ ] **Login Flow**
  - Email/password fields work
  - Login button works
  - Google sign-in button works (if available)
  - Register link works
  - Error messages display correctly

### 3. Registration Tests
- [ ] **New User Registration**
  - Registration form works
  - After registration, navigates to Onboarding screen
  - Google sign-up works (if available)

### 4. Onboarding Screen Tests
- [ ] **Genre Selection**
  - All genres display in grid
  - Can select multiple genres
  - Selected genres highlight correctly
  - Next button works

- [ ] **Platform Selection**
  - All platforms display in list
  - Can select multiple platforms
  - Selected platforms show checkmark
  - "Get Started" completes onboarding

- [ ] **Navigation**
  - After onboarding, navigates to Home screen
  - Onboarding doesn't show again after completion

### 5. Swipe Screen (Discover) Tests
- [ ] **UI Elements**
  - "DISCOVER" header in Bebas Neue font
  - Header background is cinemaRed
  - Movie cards display correctly
  - Poster fills entire card
  - Movie info overlays on poster
  - Text color adapts to poster
  - Like/dislike buttons on card

- [ ] **Swipe Actions**
  - Swipe right = Like (works)
  - Swipe left = Dislike (works)
  - Swipe up = Match (shows match screen)
  - Tap on card = Shows movie details

### 6. Match Success Screen Tests
- [ ] **UI Elements**
  - Back button in top-left (vintagePaper bg, cinemaRed arrow)
  - Poster size appropriate
  - Movie name in sepiaBrown
  - Heart icon in sepiaBrown
  - "It's a" text in sepiaBrown
  - Add to Watchlist button (vintagePaper bg, cinemaRed text)

- [ ] **Functionality**
  - Back button navigates back
  - Add to Watchlist works
  - Share button works (if implemented)

### 7. Movie Detail Screen Tests
- [ ] **Navigation**
  - Bottom navigation bar visible
  - All 5 tabs visible
  - Tapping Discover navigates to SwipeScreen
  - Tapping For You navigates to RecommendationsScreen
  - Tapping Watchlist navigates to WatchlistScreen
  - Tapping Favorites navigates to FavoritesScreen
  - Tapping Profile navigates to ProfileScreen

- [ ] **UI Elements**
  - Movie poster fills top area
  - Title, year, rating overlay on poster
  - Colors adapt to poster
  - Watchlist and Share buttons positioned correctly
  - "Where to Watch" section displays inline
  - Synopsis section expandable/collapsible
  - Cast & Crew section horizontal scrollable
  - Similar movies section displays
  - No excessive spacing at bottom

- [ ] **Data Loading**
  - Movie details load
  - Cast information loads
  - Videos load
  - Similar movies load
  - Streaming availability loads

### 8. Recommendations Screen (For You) Tests
- [ ] **Filter System**
  - All 4 filters visible: For You, Trending, Mood, Similar
  - Filters arranged horizontally (navbar style)
  - Unselected: fadedCurtain background, cinemaRed text
  - Selected: vintagePaper background, cinemaRed text
  - Can select multiple filters
  - At least one filter must remain selected
  - Movie list updates when filters change

- [ ] **UI Elements**
  - Eye button removed from AppBar
  - Filter button works
  - Refresh button works
  - Movie cards display correctly

- [ ] **Functionality**
  - Combined movie list from selected filters
  - No duplicates in list
  - Tap on movie navigates to detail screen

### 9. Bottom Navigation Bar Tests
- [ ] **Visual**
  - Background is cinemaRed
  - Selected tab: warmCream text and icon
  - Buttons are larger (56x56)
  - Appropriate bottom margin
  - No yellow background on selected button

- [ ] **Icons**
  - Discover: home icon
  - For You: search_button.png
  - Watchlist: watchlist icon
  - Favorites: like_button.png
  - Profile: settings icon

- [ ] **Functionality**
  - All tabs navigate correctly
  - Selected state updates correctly
  - Works from all screens

### 10. Profile Screen Tests
- [ ] **Sign Out Buttons**
  - Main sign out button: cinemaRed background, warmCream text
  - Dialog sign out button: cinemaRed background, warmCream text
  - Sign out works correctly
  - Navigates to Login screen after sign out

- [ ] **UI Elements**
  - Background: vintagePaper
  - Header: "PROFILE" in Bebas Neue font
  - All user information displays

### 11. Watchlist Screen Tests
- [ ] **UI Elements**
  - Background: vintagePaper
  - Header: "WATCHLIST" in Bebas Neue font
  - Movies display correctly

- [ ] **Functionality**
  - Movies added to watchlist appear
  - Can remove from watchlist
  - Tap on movie shows details

### 12. Favorites Screen Tests
- [ ] **UI Elements**
  - Background: vintagePaper
  - Header: "FAVORITES" in Bebas Neue font
  - Movies display correctly

- [ ] **Functionality**
  - Liked movies appear
  - Tap on movie shows details

---

## 🐛 Issues to Report

If you find any issues, note:
1. **Screen**: Which screen the issue is on
2. **Action**: What you were trying to do
3. **Expected**: What should have happened
4. **Actual**: What actually happened
5. **Screenshot**: If possible, take a screenshot

---

## ✅ Test Completion

Once you've completed all tests, mark them in this checklist and report any issues found.

