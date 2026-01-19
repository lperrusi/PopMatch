# Authentication Error Testing Plan

## Test Scenarios

### 1. Email/Password Sign-In Errors
- [ ] Non-existent email
- [ ] Wrong password
- [ ] Invalid email format
- [ ] Empty fields
- [ ] Network error (offline)
- [ ] Corrupted local storage

### 2. Email/Password Sign-Up Errors
- [ ] Email already exists
- [ ] Weak password (< 6 chars)
- [ ] Invalid email format
- [ ] Empty fields
- [ ] Network error (offline)
- [ ] Password mismatch

### 3. Google Sign-In Errors
- [ ] User cancels
- [ ] Network error
- [ ] Google service unavailable
- [ ] Account disabled

### 4. Apple Sign-In Errors
- [ ] User cancels
- [ ] Not available on device
- [ ] Network error
- [ ] Account disabled

### 5. Edge Cases
- [ ] Corrupted JSON in SharedPreferences
- [ ] Missing user data
- [ ] Storage permission denied
- [ ] Timeout errors
