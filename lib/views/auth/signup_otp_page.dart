import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';
import '../../services/otp_service.dart';

/// Email verification step shown between filling in the sign-up form and
/// actually creating the account.
///
/// Pops with the signed proof string on success, or `null` if the user backs
/// out — the caller only creates the Firebase account once it has a proof.
class SignupOtpPage extends StatefulWidget {
  final String email;

  const SignupOtpPage({super.key, required this.email});

  @override
  State<SignupOtpPage> createState() => _SignupOtpPageState();
}

class _SignupOtpPageState extends State<SignupOtpPage> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  bool _verifying = false;
  bool _resending = false;
  String? _error;

  Timer? _ticker;
  int _resendIn = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    // The code was already sent by the sign-up page before pushing this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _resendIn = 60);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    final result = await OtpService.verifyOtp(widget.email, code);
    if (!mounted) return;

    if (result.ok) {
      Navigator.pop(context, result.proof ?? '');
      return;
    }

    setState(() {
      _verifying = false;
      _error = result.message;
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });

    final result = await OtpService.sendOtp(widget.email);
    if (!mounted) return;

    setState(() {
      _resending = false;
      _error = result.ok ? null : result.message;
    });

    if (result.ok) {
      _codeController.clear();
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new code is on its way'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mins = AppConfig.otpValidity.inMinutes;
    final canResend = _resendIn <= 0 && !_resending && !_verifying;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/images/logo1.png', height: 64)),
              const SizedBox(height: 28),

              const Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Text.rich(
                TextSpan(
                  text: 'We sent a 6-digit code to\n',
                  style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _codeController,
                focusNode: _focusNode,
                autofocus: true,
                enabled: !_verifying,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 14,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '······',
                  hintStyle: TextStyle(
                    fontSize: 30,
                    letterSpacing: 14,
                    color: Colors.grey.shade300,
                  ),
                  errorText: _error,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3E729F), width: 2),
                  ),
                ),
                onChanged: (v) {
                  if (_error != null) setState(() => _error = null);
                  if (v.length == 6) _verify(); // auto-submit on the 6th digit
                },
              ),
              const SizedBox(height: 8),

              Text(
                'The code expires in $mins minutes.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E729F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify & Create Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              Center(
                child: _resending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: canResend ? _resend : null,
                        child: Text(
                          canResend
                              ? 'Resend code'
                              : 'Resend code in ${_resendIn}s',
                          style: TextStyle(
                            color: canResend
                                ? const Color(0xFF3E729F)
                                : Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Wrong address? Go back and edit it.',
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
