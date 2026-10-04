# Travel App - Build Instructions

This guide provides step-by-step instructions for building the Travel app for both Android and iOS platforms.

## Prerequisites

### Common Requirements
- Flutter SDK (latest stable version)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA)

### Android Requirements
- Android Studio or Android SDK Command-line tools
- JDK 17 or higher
- Gradle (bundled with Flutter)

### iOS Requirements (Mac only)
- macOS (required for iOS builds)
- Xcode 14 or higher
- CocoaPods
- Apple Developer Account (for distribution)

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Karthikeyan-alp/travel1.git
cd travel1
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Installation

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding.

---

## Android Build Instructions

### A. Debug Build (For Testing)

1. **Connect an Android device or start an emulator**

2. **Run the app in debug mode:**
   ```bash
   flutter run
   ```

3. **Build a debug APK:**
   ```bash
   flutter build apk --debug
   ```

### B. Release Build (For Distribution)

#### Prerequisites for Release Build:

1. **Keystore File** (Required)
   - You need the `upload-keystore.jks` file
   - Contact the repository owner to get this file
   - **IMPORTANT:** Never share this file publicly or commit it to Git

2. **Configure Key Properties:**

   Create a file `android/key.properties` with the following content:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=PATH_TO_YOUR_KEYSTORE_FILE
   ```

   Example:
   ```properties
   storePassword=123456
   keyPassword=123456
   keyAlias=upload
   storeFile=C:\\Users\\YourUsername\\upload-keystore.jks
   ```

   Or use a relative path:
   ```properties
   storePassword=123456
   keyPassword=123456
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

3. **Firebase Configuration:**
   - Ensure `android/app/google-services.json` is present
   - This file is already included in the repository

#### Build Release APK:

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### Build App Bundle (For Play Store):

```bash
flutter build appbundle --release
```

The AAB will be generated at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## iOS Build Instructions

**Note:** iOS builds require a Mac with Xcode installed.

### A. Initial iOS Setup

1. **Install CocoaPods** (if not already installed):
   ```bash
   sudo gem install cocoapods
   ```

2. **Install iOS dependencies:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Open Xcode project:**
   ```bash
   open ios/Runner.xcworkspace
   ```

### B. Configure iOS Signing

1. **In Xcode:**
   - Select the `Runner` project in the left sidebar
   - Select the `Runner` target
   - Go to **Signing & Capabilities** tab

2. **Set your Team:**
   - Enable "Automatically manage signing"
   - Select your Apple Developer Team from the dropdown
   - If you don't have a team, you'll need to:
     - Sign in with your Apple ID in Xcode Preferences
     - Join the Apple Developer Program ($99/year for distribution)

3. **Verify Bundle Identifier:**
   - Should be: `com.example.travel`
   - Change if needed for your organization

### C. Debug Build (For Testing)

1. **Connect an iOS device or start a simulator**

2. **Run the app:**
   ```bash
   flutter run
   ```

### D. Release Build (For Distribution)

#### Prerequisites for iOS Release:

1. **Apple Developer Account** (Required for App Store distribution)
   - Enroll at: https://developer.apple.com/programs/
   - Cost: $99/year

2. **Provisioning Profile and Certificates:**
   - Xcode can automatically manage these if "Automatically manage signing" is enabled
   - For manual signing, create profiles in Apple Developer portal

3. **Firebase Configuration:**
   - Ensure `ios/Runner/GoogleService-Info.plist` is present
   - Update Firebase Console with your Team ID (from Apple Developer Account)

#### Build for iOS Release:

**Option 1: Build using Flutter CLI**

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS release
flutter build ios --release
```

**Option 2: Build Archive in Xcode (Recommended for App Store)**

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Generic iOS Device:**
   - In Xcode toolbar, select "Any iOS Device (arm64)"

3. **Create Archive:**
   - Go to **Product** → **Archive**
   - Wait for the build to complete

4. **Distribute Archive:**
   - When archive completes, the Organizer window opens
   - Click **Distribute App**
   - Choose distribution method:
     - **App Store Connect:** For App Store submission
     - **Ad Hoc:** For testing on registered devices
     - **Enterprise:** For enterprise distribution
     - **Development:** For development testing

5. **Upload to App Store:**
   - Follow the prompts to upload to App Store Connect
   - Then submit for review in App Store Connect portal

---

## Firebase Setup

### For Google Sign-In to Work:

#### Android:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Project Settings** → **Your apps**
4. Under Android app, click **Add fingerprint**
5. Add the SHA-256 certificate fingerprint

**To get your SHA-256 fingerprint:**
```bash
keytool -list -v -keystore path/to/your/keystore.jks -alias upload
```

**Release SHA-256 fingerprint:**
```
C1:7F:A7:19:C1:05:2E:38:42:9B:1D:21:9E:78:A5:10:2B:00:FB:78:21:53:1B:FD:F7:6C:68:1D:FE:1E:09:F1
```

#### iOS:
1. In Firebase Console, go to **Project Settings**
2. Under iOS app settings
3. Add **Team ID** (from Apple Developer Account → Membership)
4. Add **App Store ID** (after publishing to App Store)

---

## Troubleshooting

### Android Issues

**Issue: "Missing classes" or R8 errors**
- Solution: ProGuard rules are already configured in `android/app/proguard-rules.pro`
- If issues persist, try: `flutter clean && flutter build apk --release`

**Issue: Google Sign-In not working in release**
- Solution: Add release SHA-256 fingerprint to Firebase Console

**Issue: Build fails with "Keystore not found"**
- Solution: Ensure `android/key.properties` points to the correct keystore file path

### iOS Issues

**Issue: "No profiles for 'com.example.travel' were found"**
- Solution: In Xcode, enable "Automatically manage signing" and select your team

**Issue: CocoaPods errors**
- Solution: Run:
  ```bash
  cd ios
  pod repo update
  pod install
  cd ..
  ```

**Issue: Build fails with code signing errors**
- Solution: Ensure you have a valid Apple Developer account and certificates

**Issue: Google Sign-In not working**
- Solution: Add Team ID to Firebase Console iOS app settings

---

## Version Information

- **App Name:** Travel
- **Bundle ID (iOS):** com.example.travel
- **Application ID (Android):** com.example.travel
- **Minimum Android SDK:** As configured in Flutter
- **Minimum iOS Version:** As configured in Flutter

---

## Important Security Notes

### Files to NEVER commit to Git:
- `*.jks` or `*.keystore` files
- `android/key.properties`
- Any files containing passwords or API keys

### Files already in .gitignore:
- Keystore files
- key.properties
- Build outputs
- IDE configuration

---

## Support

For issues or questions:
1. Check Flutter documentation: https://docs.flutter.dev
2. Check Firebase documentation: https://firebase.google.com/docs
3. Review this guide's troubleshooting section
4. Contact the repository maintainer

---

## Build Checklist

### Before Building for Release:

- [ ] All dependencies installed (`flutter pub get`)
- [ ] `flutter doctor` shows no critical issues
- [ ] For Android: Keystore file obtained and `key.properties` configured
- [ ] For iOS: Team ID set in Xcode
- [ ] Firebase SHA-256/Team ID added to console
- [ ] App tested in debug mode
- [ ] All features working correctly
- [ ] Version number updated in `pubspec.yaml`

### After Building:

- [ ] APK/IPA tested on physical device
- [ ] Google Sign-In tested
- [ ] Location services tested
- [ ] All core features verified
- [ ] Release notes prepared
