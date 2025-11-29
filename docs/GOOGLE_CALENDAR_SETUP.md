# Google Calendar Integration Setup

This document provides instructions for setting up Google Calendar integration in the Doctor App.

## Overview

The Google Calendar integration allows doctors to:
- Connect their Google Calendar to the app
- Automatically create calendar events when appointments are scheduled
- View availability based on existing calendar events
- Sync appointment reminders to Google Calendar

## Setup Steps

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Google Calendar API**
   - **Google People API** (optional, for contact info)

### 2. Configure OAuth Consent Screen

1. In Google Cloud Console, go to **APIs & Services** > **OAuth consent screen**
2. Select **External** user type (or Internal if using Google Workspace)
3. Fill in the required fields:
   - App name: `Doctor App`
   - User support email: Your email
   - Developer contact: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/calendar.events`
   - `email`
5. Add test users (your Google account email)

### 3. Create OAuth 2.0 Credentials

#### For Android:

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **Android** as application type
4. Enter your package name: `com.example.doctor_app`
5. Get your SHA-1 fingerprint:

   ```bash
   # For debug keystore (development)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # On Windows:
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

   # For release keystore (production)
   keytool -list -v -keystore your-release-key.keystore -alias your-alias
   ```

6. Copy the SHA-1 fingerprint and paste it in the form
7. Click **Create**

#### For iOS (if applicable):

1. Create another OAuth client ID
2. Select **iOS** as application type
3. Enter your bundle ID: `com.example.doctorApp`
4. Click **Create**
5. Download the `GoogleService-Info.plist` file
6. Add it to `ios/Runner/`

#### For Web (if applicable):

1. Create another OAuth client ID
2. Select **Web application**
3. Add authorized origins:
   - `http://localhost:5000` (for development)
   - Your production URL
4. Add authorized redirect URIs as needed

### 4. Configure the App

#### Android Configuration

The `google_sign_in` package handles most configuration automatically. Ensure:

1. Your `android/app/build.gradle.kts` has the correct `applicationId`:
   ```kotlin
   android {
       namespace = "com.example.doctor_app"
       defaultConfig {
           applicationId = "com.example.doctor_app"
           // ...
       }
   }
   ```

2. The SHA-1 in Google Cloud Console matches your debug/release keystore

#### iOS Configuration (if needed)

Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your reversed client ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 5. Testing

1. Run the app in debug mode
2. Go to **Settings** > **Calendar Integration**
3. Tap **Connect Google Calendar**
4. Sign in with a test user account
5. Grant calendar permissions
6. Try creating an appointment - it should sync to your calendar

## Troubleshooting

### "Sign in failed" Error

1. Verify SHA-1 fingerprint is correct in Google Cloud Console
2. Ensure the package name matches exactly
3. Check if the user is added as a test user (for apps in testing mode)

### "Access Denied" Error

1. Verify OAuth consent screen is configured
2. Add required scopes to consent screen
3. Make sure Calendar API is enabled

### Calendar Events Not Creating

1. Check if the selected calendar allows event creation
2. Verify the app has calendar.events scope
3. Check console for any API errors

## Security Notes

- OAuth tokens are stored securely on device
- The app only requests necessary permissions
- Users can disconnect their calendar anytime from Settings
- No calendar data is stored on external servers

## API Quotas

Google Calendar API has the following quotas:
- 1,000,000 queries per day
- 100 queries per 100 seconds per user

For a typical doctor's office, these limits are more than sufficient.

## Files Modified/Created

- `lib/src/services/google_calendar_service.dart` - Main calendar service
- `lib/src/providers/google_calendar_provider.dart` - State management
- `lib/src/ui/screens/settings_screen.dart` - Calendar connection UI
- `lib/src/ui/screens/add_appointment_screen.dart` - Calendar sync on save
- `android/app/src/main/AndroidManifest.xml` - Internet permission
- `pubspec.yaml` - Google dependencies
