# Google Sign-in Testing Guide

## Manual Testing Steps

### 1. **Test App Launch**
```bash
flutter run --debug
```
- App should show the login screen with blue gradient
- Should see "Welcome Back" title
- Should see Email and Password fields
- Should see "Sign in with Google" button
- Should see "Test Google Sign-in Setup" button

### 2. **Test Google Sign-in Setup (Before configuring Google Console)**
- Tap "Test Google Sign-in Setup" button
- Expected: Will fail with configuration error
- This confirms the button works but needs proper setup

### 3. **After Google Cloud Console Configuration**
1. Replace `android/app/google-services.json` with real file from Google Cloud Console
2. Use your SHA-1: `B3:EF:F2:44:55:0F:A1:F7:05:37:FE:AC:1B:89:C8:58:4D:58:A8:B2`
3. Package name: `com.example.afochatapplication`

### 4. **Test Google Sign-in (After Configuration)**
- Tap "Test Google Sign-in Setup" button
- Should open Google sign-in flow
- After successful Google sign-in, should show user info dialog
- Should navigate to home screen

### 5. **Test Full Google Sign-in with Backend**
- Tap "Sign in with Google" button
- Will need backend server running on `http://10.0.2.2:4000/auth/oauth/google`

## Common Issues & Solutions

### Issue: "Sign-in failed: PlatformException"
**Solution**: 
- Check SHA-1 fingerprint matches Google Console
- Verify package name is correct
- Ensure `google-services.json` is from your project

### Issue: "Google authentication failed on server"
**Solution**: 
- Google sign-in is working, but backend is not configured
- Need to implement `/auth/oauth/google` endpoint

### Issue: "Sign-in was cancelled by user"
**Solution**: 
- User cancelled the Google sign-in flow
- This is normal behavior, not an error

## Testing Checklist

- [ ] App launches and shows login screen
- [ ] All UI elements are visible and styled correctly
- [ ] Form validation works (try submitting empty form)
- [ ] "Test Google Sign-in Setup" button responds
- [ ] Navigation between login and register screens works
- [ ] Google sign-in flow opens (after configuration)
- [ ] User info is displayed correctly after sign-in

## Next Steps

1. **Configure Google Cloud Console** (highest priority)
2. **Test the Google sign-in flow**
3. **Set up backend server** (if needed)
4. **Test full authentication flow**
