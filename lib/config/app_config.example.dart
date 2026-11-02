/// Central place for the externally-hosted endpoints the app depends on.
///
/// ⚠️ Set these once the files in `legal/` and `server/` have been uploaded
/// to Hostinger. Everything else in the app reads from here, so this is the
/// only file that needs editing when the domain changes.
class AppConfig {
  AppConfig._();

  /// Root of your Hostinger site, no trailing slash.
  /// Example: 'https://kuruvi.example.com'
  static const String siteBaseUrl = 'https://kuruviapp.com';

  /// Published legal documents (uploaded from the `legal/` folder).
  static const String termsUrl = '$siteBaseUrl/legal/terms.html';
  static const String privacyUrl = '$siteBaseUrl/legal/privacy.html';

  /// OTP endpoints. The PHP files live in `public_html/server/` on Hostinger,
  /// so this path must stay in step with wherever they are uploaded.
  static const String sendOtpUrl = '$siteBaseUrl/server/send_otp.php';
  static const String verifyOtpUrl = '$siteBaseUrl/server/verify_otp.php';

  /// Shared secret sent as `X-Api-Key`. Must match `$API_KEY` in
  /// `server/config.php`. This only raises the bar for casual abuse — a
  /// determined attacker can extract it from the APK, so the server also
  /// rate-limits by email and IP.
  static const String apiKey = 'REPLACE-WITH-THE-API_KEY-FROM-server/config.php';

  /// How long a code stays valid. Must match `OTP_TTL_MINUTES` on the server.
  static const Duration otpValidity = Duration(minutes: 10);

  /// Sign in with Apple is not implemented yet — there is no `sign_in_with_apple`
  /// dependency and no Apple Developer Service ID configured. The buttons were
  /// previously wired to the *Google* handler, which silently ran the wrong
  /// flow, so they stay hidden until the real thing is built.
  ///
  /// Note: Apple requires Sign in with Apple on iOS apps that offer any other
  /// third-party login, so this must be implemented before an App Store release.
  static const bool appleSignInEnabled = false;

  /// True once [siteBaseUrl] has actually been pointed at a real domain.
  /// Used to show a clear setup message instead of a confusing network error.
  static bool get isConfigured => !siteBaseUrl.contains('REPLACE-ME');
}
