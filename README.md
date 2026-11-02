# Kuruvi — Community Travel Companion

Kuruvi is a community-driven travel companion app built with Flutter that connects
people traveling along the same routes. The platform is designed to make travel more
collaborative, affordable and socially connected, especially for users who prefer
communicating in their native language.

The app enables travelers to:

- Connect with people traveling on similar routes
- Participate in route-based group chats
- Use one-on-one messaging for direct coordination
- Share travel updates, discussions and local information
- Coordinate low-cost package carrying between cities
- Build trusted travel communities based on language and shared destinations

A key focus of Kuruvi is accessibility and ease of communication for elderly users and
regional language speakers, helping them travel with greater confidence and social
support.

## Features

- Real-time one-on-one chat
- Route-based group discussions
- Email OTP sign-up with hosted Terms & Privacy Policy
- Push notifications for direct messages, group messages and booking requests
- Community-driven travel coordination
- Language-friendly user experience

---

## Getting it running

Two files are deliberately **not** in this repository because they carry secrets. The
project will not compile until you create the first one.

### 1. `lib/config/app_config.dart`

```bash
cp lib/config/app_config.example.dart lib/config/app_config.dart
```

Then set `apiKey` to the same value as `API_KEY` in `server/config.php`. The two must
match or every OTP request comes back `401 unauthorized`.

### 2. `server/config.php`

This one never enters the repo at all — it is created directly on the server. See
[`server/README.md`](server/README.md) for the full walkthrough. It holds:

| Setting | Notes |
| ------- | ----- |
| `API_KEY` | Must match `AppConfig.apiKey` above |
| `APP_SECRET` | Server-only; hashes OTPs and signs proofs. Never ships in the app |
| `MAILER` | `mail` (Hostinger's local relay), `smtp`, `brevo` or `resend` |
| `MAIL_FROM` | Currently `no-reply@kuruviapp.com` |

Generate both secrets with `openssl rand -hex 32`, and make them different from each
other.

### 3. Firebase

`google-services.json`, `GoogleService-Info.plist` and `firebase_options.dart` are
committed, so Android builds work straight after clone. If you ever regenerate them,
use `flutterfire configure` rather than editing by hand.

### 4. Build

```bash
flutter pub get
flutter run
```

Cloud Functions deploy separately:

```bash
cd functions && npm install
firebase deploy --only functions
```

---

## How the pieces fit together

**OTP sign-up.** The app posts to `send_otp.php` on the Hostinger box, which stores
only a hash of the code and emails the plaintext. `verify_otp.php` checks the code and
returns a signed proof. Only then does the app call
`createUserWithEmailAndPassword`. The OTP store lives *outside* `public_html` so the
records are not reachable over HTTP.

**Push notifications.** Writing a message document triggers a Firestore Cloud Function
in `asia-south1`, which looks up the recipients' FCM tokens and sends through FCM.
Tokens that FCM reports as dead are pruned automatically.

| Function | Fires on |
| -------- | -------- |
| `onDirectMessage` | `chats/{chatId}/messages/{messageId}` |
| `onGroupMessage` | `travel_groups/{groupId}/messages/{messageId}` |
| `onBookingRequest` | booking request documents |

**Legal documents.** `legal/terms.html` and `legal/privacy.html` are uploaded to
`public_html/legal/` and opened inside the app from the sign-up page, so they can be
read before registering.

---

## Outstanding work

Ordered by what blocks a release.

### Blocking a Play Store submission

**Application ID is still `com.example.travel`.** Google Play rejects any package
beginning with `com.example`. Changing it means registering a new Android app in
Firebase and replacing `google-services.json`. Do this before the first upload — the
package name cannot be changed after a release is published.

**App icon is still the stock Flutter logo.** Nothing has replaced
`android/app/src/main/res/mipmap-*/ic_launcher.png`, which is also why the Android 12+
splash screen shows the Flutter mark. The existing artwork is far too small to reuse
(`logo1.png` is 120 × 167; an icon needs 1024 × 1024). `flutter_launcher_icons` is
already configured in `pubspec.yaml` — see [`assets/icon/README.md`](assets/icon/README.md)
for the three files required and why a notification icon has to be a white silhouette.

**Legal documents still contain template placeholders.** The copies in this repo have
the dates and contact addresses filled in, but the versions currently served from
`kuruviapp.com/legal/` are the originals, still carrying `____`, `[Company Address]`
and `legal@xapp.com` (a different company's address, repeated ten times). Upload the
files from `legal/`, and fill in the registered company address — three places across
the two documents. Play Store review reads the privacy policy URL.

### iOS push notifications do not work yet

The Dart side is platform-agnostic and ready. The native iOS configuration is absent:

| Requirement | Status |
| ----------- | ------ |
| `GoogleService-Info.plist` | Present |
| `Runner.entitlements` with `aps-environment` | **Missing** |
| `UIBackgroundModes` → `remote-notification` | **Not set** |
| APNs auth key uploaded to Firebase | **Unverified** |

To finish it you need a paid Apple Developer account, then in Xcode add the **Push
Notifications** and **Background Modes → Remote notifications** capabilities to the
Runner target, create an APNs auth key (`.p8`) in the Apple Developer portal, and
upload it under *Firebase Console → Project Settings → Cloud Messaging*. The `.p8` can
only be downloaded once. Remote push cannot be tested on the iOS Simulator — a
physical device is required.

### Smaller items

- **`onBookingRequest` has never executed.** `onDirectMessage` and `onGroupMessage` are
  both verified end to end on a device; the booking trigger is deployed but untested.
- **No SPF/DKIM on `kuruviapp.com`.** Mail delivers to the inbox, but Gmail shows
  "via srv….main-hosting.eu". Creating a mailbox in hPanel adds the records and removes
  it. Note that `legal@kuruviapp.com` and `privacy@kuruviapp.com` are published in the
  legal documents but no mailbox exists for them yet, so replies bounce.
- **No homepage.** `kuruviapp.com` serves Hostinger's "Coming soon" placeholder;
  `robots.txt` and `sitemap.xml` from `site/` have not been uploaded. Only the two
  legal pages are indexable.
- **FAQ content** has not been written.
- **Orphaned Firestore document** `users/dOVXgZE5D4WxixJdxmWroOzGGUp1` remains after an
  account deletion; it still holds the username `karthis`.

---

## Notes for anyone working on this

**Register the FCM token on sign-in, not only at startup.** `PushNotificationService
.initialise()` runs once from `main()`, before anyone has signed in, and saving a token
is a no-op while signed out. An `authStateChanges` listener now re-registers whenever a
user appears. Without it, a user who signs up or logs in during a session has no token
stored and receives no notifications until the next cold start — which looks exactly
like push being broken.

**Give every remote call a deadline.** Firestore retries a lost connection
indefinitely, so a failed read surfaces as a spinner that never resolves rather than an
error. The steps in `AuthController.createUser` each have their own timeout, and the
message names the step that stalled.

**Geolocator's `timeLimit` is not reliable on Android.** It does not always fire, so
`getLocation()` is wrapped in an outer timeout at the call site and treated as
optional — location is never a reason to block sign-up.

**Android notification icons are masked to a single colour.** Pointing one at a
full-colour image produces a white blob; it has to be authored as a white silhouette on
transparency.
