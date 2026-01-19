# Onboarding and Preferences Issues - Analysis

## Issues Found

### 1. ❌ Onboarding Shows Every Login
**Problem**: When user signs in, if existing user data isn't found or fails to parse, a new User is created with empty preferences, causing `onboardingCompleted` to be false.

**Location**: `lib/services/auth_service.dart` lines 365-377, 205-216

**Fix Needed**: 
- Ensure existing user data is always loaded if available
- Don't create new User with empty preferences if user already exists
- Preserve preferences when loading user data

### 2. ❌ Preferences Not Editable in Profile
**Problem**: Profile screen has "Edit Profile" button but it's just a TODO placeholder.

**Location**: `lib/screens/home/profile_screen.dart` line 172-177

**Fix Needed**: 
- Create preferences editing screen
- Allow editing genres, streaming platforms, and other preferences
- Save changes back to user preferences

### 3. ❌ Streaming Platforms from Onboarding Not Used
**Problem**: `selectedPlatforms` from onboarding are saved but not automatically applied to recommendations. They're only used if user manually sets filters.

**Location**: `lib/providers/movie_provider.dart` - platform filtering only uses `_swipeSelectedPlatforms`, not user preferences

**Fix Needed**:
- Load `selectedPlatforms` from user preferences on app start
- Apply them to recommendations automatically
- Use them as default for swipe screen filters

### 4. ⚠️ Preferences May Not Be Loaded Properly
**Problem**: When loading user data, preferences might not be preserved if JSON parsing fails or user data structure changes.

**Fix Needed**:
- Ensure preferences are always preserved when loading user data
- Add fallback handling for missing preferences

## Solution Plan

1. Fix user data loading to preserve preferences
2. Create preferences editing screen
3. Auto-apply streaming platforms from preferences
4. Ensure onboarding only shows once
5. Test complete flow
