# Manual Test Scenarios for Onboarding & Preferences

## Test Environment Setup
- Device: iPhone Simulator or Physical Device
- App: PopMatch (latest build)
- Test Account: Create new account for testing

---

## Scenario 1: First-Time User Flow ✅

### Steps:
1. **Launch App** → Should show Splash Screen
2. **Sign Up** → Create new account (email/password, Google, or Apple)
3. **Expected**: Onboarding screen appears (3 pages)
4. **Page 1**: Welcome screen → Tap "Next"
5. **Page 2**: Select genres (select at least 3) → Tap "Next"
6. **Page 3**: Select streaming platforms (select at least 2) → Tap "Get Started"
7. **Expected**: Navigate to HomeScreen
8. **Verify**: 
   - Swipe screen loads movies
   - Movies should be filtered by selected platforms (if available)
   - Profile shows user info

### Expected Results:
- ✅ Onboarding shows only once
- ✅ Preferences saved
- ✅ Streaming platforms applied
- ✅ Recommendations use selected genres

---

## Scenario 2: Returning User Flow ✅

### Steps:
1. **Sign Out** from previous session
2. **Sign In** with same account
3. **Expected**: Navigate directly to HomeScreen (NO onboarding)
4. **Verify**:
   - No onboarding screens appear
   - User data loaded correctly
   - Preferences preserved
   - Streaming platforms still applied

### Expected Results:
- ✅ Onboarding skipped
- ✅ Preferences loaded
- ✅ User data intact

---

## Scenario 3: Edit Preferences from Profile ✅

### Steps:
1. **Sign In** with existing account
2. **Navigate** to Profile tab (bottom navigation)
3. **Tap** "Edit Preferences" in Account Settings
4. **Expected**: EditPreferencesScreen appears (2 pages)
5. **Page 1**: Modify genre selections → Tap "Next"
6. **Page 2**: Modify platform selections → Tap "Save"
7. **Expected**: 
   - Success message appears
   - Navigate back to Profile
   - Changes saved

### Verify Changes Applied:
1. **Navigate** to Swipe tab
2. **Expected**: 
   - New recommendations loaded
   - Movies filtered by updated platforms
   - Genres used in recommendations

### Expected Results:
- ✅ Preferences editable
- ✅ Changes saved immediately
- ✅ Recommendations updated
- ✅ Platforms applied automatically

---

## Scenario 4: Multiple Sign-Ins ✅

### Steps:
1. **Sign In** → Complete onboarding (if first time)
2. **Sign Out**
3. **Sign In** again → Should skip onboarding
4. **Sign Out**
5. **Sign In** third time → Should skip onboarding
6. **Verify**: Preferences persist across all sign-ins

### Expected Results:
- ✅ Onboarding only shows once
- ✅ Preferences persist
- ✅ User data consistent

---

## Scenario 5: Streaming Platforms Auto-Application ✅

### Steps:
1. **Sign In** with account that has platform preferences
2. **Navigate** to Swipe tab
3. **Verify**: 
   - Movies shown are available on selected platforms
   - Platform filter indicator shows selected platforms
4. **Check** filter button → Should show selected platforms

### Expected Results:
- ✅ Platforms auto-applied on app start
- ✅ Recommendations filtered correctly
- ✅ Filter UI shows selected platforms

---

## Scenario 6: Preferences Used in Algorithm ✅

### Steps:
1. **Sign In** with new account (no liked movies yet)
2. **Complete** onboarding with specific genres (e.g., Action, Comedy, Drama)
3. **Navigate** to Swipe tab
4. **Observe** recommended movies
5. **Verify**: Movies match selected genres

### Expected Results:
- ✅ Recommendations use onboarding genres
- ✅ Movies match user preferences
- ✅ Algorithm respects genre selections

---

## Scenario 7: Edge Cases ✅

### 7a. User with No Platforms Selected
1. **Edit Preferences** → Deselect all platforms
2. **Save**
3. **Verify**: Recommendations show all movies (no platform filter)

### 7b. User with No Genres Selected
1. **Edit Preferences** → Deselect all genres
2. **Save**
3. **Verify**: App uses default genres or handles gracefully

### 7c. User Edits Preferences Multiple Times
1. **Edit Preferences** → Change genres → Save
2. **Edit Preferences** again → Change platforms → Save
3. **Verify**: All changes persist correctly

---

## Scenario 8: Data Persistence ✅

### Steps:
1. **Sign In** → Complete onboarding
2. **Edit Preferences** → Make changes
3. **Force Close** app
4. **Reopen** app
5. **Sign In** again
6. **Verify**: All preferences preserved

### Expected Results:
- ✅ Data persists after app close
- ✅ Preferences loaded correctly
- ✅ No data loss

---

## Scenario 9: Different Sign-In Methods ✅

### Test with Email/Password:
1. **Sign Up** with email → Complete onboarding
2. **Sign Out** → Sign In again
3. **Verify**: Onboarding skipped, preferences loaded

### Test with Google:
1. **Sign In** with Google → Complete onboarding (if first time)
2. **Sign Out** → Sign In with Google again
3. **Verify**: Onboarding skipped, preferences loaded

### Test with Apple:
1. **Sign In** with Apple → Complete onboarding (if first time)
2. **Sign Out** → Sign In with Apple again
3. **Verify**: Onboarding skipped, preferences loaded

---

## Scenario 10: Complete User Journey ✅

### Full Flow Test:
1. **First Launch** → Tutorial → Sign Up → Onboarding
2. **Select Preferences** → Genres & Platforms
3. **Use App** → Swipe movies, like some
4. **Edit Preferences** → Change selections
5. **Sign Out** → Sign In again
6. **Verify**: 
   - Onboarding skipped
   - Preferences updated
   - Liked movies preserved
   - Recommendations updated

### Expected Results:
- ✅ Complete flow works end-to-end
- ✅ All data persists
- ✅ All features functional

---

## Test Results Template

For each scenario, record:
- [ ] Test Date: ___________
- [ ] Device: ___________
- [ ] iOS Version: ___________
- [ ] Result: ✅ Pass / ❌ Fail
- [ ] Notes: ___________

---

## Known Issues to Watch For

1. **Onboarding shows twice**: Should only show once
2. **Preferences not saved**: Check SharedPreferences
3. **Platforms not applied**: Check SwipeScreen initialization
4. **Recommendations not updated**: Check MovieProvider
5. **Data loss on sign-out**: Check user data persistence

---

## Success Criteria

All scenarios should:
- ✅ Work without crashes
- ✅ Preserve user data
- ✅ Show correct UI states
- ✅ Apply preferences correctly
- ✅ Update recommendations appropriately
