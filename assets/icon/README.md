# App icons

Drop three files here, then run `dart run flutter_launcher_icons`.

| File | Size | Content |
| ---- | ---- | ------- |
| `kuruvi_icon.png` | 1024 × 1024 | The bird on a solid background. No transparency — iOS rejects alpha. |
| `kuruvi_icon_foreground.png` | 1024 × 1024 | The bird alone on a transparent canvas, with ~25% padding on every side. |
| `ic_notification.png` | 96 × 96 | The bird as a **solid white silhouette** on transparent. |

## Why three, and not one

**The launcher icon** is the square you tap. iOS forbids an alpha channel, so
`kuruvi_icon.png` needs a filled background.

**The adaptive foreground** is for Android 8+, which crops every icon to the
shape the launcher prefers — circle, squircle, rounded square. Only the middle
~66% is guaranteed visible, so the bird needs generous padding or its wings get
clipped. The background comes from `adaptive_icon_background` in `pubspec.yaml`.

**The notification icon** is not a small version of the launcher icon. Android
discards all colour and draws the shape in a single tint, using the alpha
channel as the mask. A full-colour image therefore arrives as a solid white
blob. It has to be authored as a white silhouette on transparency.

Once `ic_notification.png` exists, copy it into the drawable buckets and point
the service at it:

```
android/app/src/main/res/drawable-mdpi/ic_notification.png     24 x 24
android/app/src/main/res/drawable-hdpi/ic_notification.png     36 x 36
android/app/src/main/res/drawable-xhdpi/ic_notification.png    48 x 48
android/app/src/main/res/drawable-xxhdpi/ic_notification.png   72 x 72
android/app/src/main/res/drawable-xxxhdpi/ic_notification.png  96 x 96
```

Then in `lib/services/push_notification_service.dart`, replace both
`icon: '@mipmap/ic_launcher'` occurrences with `'@drawable/ic_notification'`,
and add to `AndroidManifest.xml` inside `<application>` so pushes that arrive
while the app is terminated use it too:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/kuruvi_blue" />
```

## Source images already in the repo are too small

`assets/images/logo1.png` is 120 × 167 and `logo2.png` is 120 × 48 — both are
runtime UI assets, not icon sources. Upscaling either to 1024 px gives a blurry
icon, and the Play Store separately requires a sharp 512 × 512. Export fresh
from the original vector artwork.

## Splash screen

`android/app/src/main/res/drawable/launch_background.xml` is still the default
white template. On Android 12+ the system splash falls back to the launcher
icon, so fixing the icon fixes the splash as well. For a custom splash, add
`flutter_native_splash` rather than hand-editing the drawable.
