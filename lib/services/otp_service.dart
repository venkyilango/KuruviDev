import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Outcome of an OTP call, with a message already fit to show the user.
class OtpResult {
  final bool ok;
  final String? message;

  /// Signed proof returned on successful verification.
  final String? proof;

  /// Seconds to wait, when the server asked us to back off.
  final int? retryAfter;

  const OtpResult.success({this.proof})
      : ok = true,
        message = null,
        retryAfter = null;

  const OtpResult.failure(String this.message, {this.retryAfter})
      : ok = false,
        proof = null;
}

/// Talks to the OTP endpoints hosted on Hostinger.
///
/// The server stores only a hash of each code, enforces expiry, caps wrong
/// guesses, and rate-limits by address and IP — see `server/`.
class OtpService {
  static const Duration _timeout = Duration(seconds: 20);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Api-Key': AppConfig.apiKey,
      };

  /// Sends a fresh code to [email].
  static Future<OtpResult> sendOtp(String email) async {
    if (!AppConfig.isConfigured) {
      return const OtpResult.failure(
        'Email verification is not set up yet. '
        'Set AppConfig.siteBaseUrl to your domain.',
      );
    }

    try {
      final res = await http
          .post(
            Uri.parse(AppConfig.sendOtpUrl),
            headers: _headers,
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(_timeout);

      final body = _decode(res.body);

      if (res.statusCode == 200 && body['ok'] == true) {
        return const OtpResult.success();
      }
      return OtpResult.failure(
        _messageFor(body['error'], res.statusCode),
        retryAfter: body['retry_after'] is int ? body['retry_after'] : null,
      );
    } catch (_) {
      return const OtpResult.failure(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// Checks [code] for [email]. On success the result carries a proof token.
  static Future<OtpResult> verifyOtp(String email, String code) async {
    if (!AppConfig.isConfigured) {
      return const OtpResult.failure('Email verification is not set up yet.');
    }

    try {
      final res = await http
          .post(
            Uri.parse(AppConfig.verifyOtpUrl),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'code': code.trim(),
            }),
          )
          .timeout(_timeout);

      final body = _decode(res.body);

      if (res.statusCode == 200 && body['ok'] == true) {
        return OtpResult.success(proof: body['proof'] as String?);
      }

      // Surface how many tries are left, when the server tells us.
      final remaining = body['remaining'];
      if (body['error'] == 'incorrect' && remaining is int && remaining > 0) {
        return OtpResult.failure(
          'Incorrect code. $remaining ${remaining == 1 ? 'try' : 'tries'} left.',
        );
      }
      return OtpResult.failure(_messageFor(body['error'], res.statusCode));
    } catch (_) {
      return const OtpResult.failure(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  static Map<String, dynamic> _decode(String raw) {
    try {
      final d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Maps a server error code to something worth showing a user.
  static String _messageFor(Object? code, int status) {
    switch (code) {
      case 'invalid_email':
        return 'Please enter a valid email address.';
      case 'cooldown':
        return 'Please wait a moment before requesting another code.';
      case 'too_many_requests':
        return 'Too many requests. Please try again later.';
      case 'too_many_attempts':
        return 'Too many incorrect attempts. Please request a new code.';
      case 'expired':
        return 'That code has expired. Please request a new one.';
      case 'incorrect':
        return 'Incorrect code. Please check and try again.';
      case 'invalid_code_format':
        return 'Please enter the 6-digit code.';
      case 'send_failed':
        return 'We could not send the email. Please try again shortly.';
      case 'unauthorized':
        return 'Verification is misconfigured. Please contact support.';
      default:
        return 'Something went wrong (error $status). Please try again.';
    }
  }
}
