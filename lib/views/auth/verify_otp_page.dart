import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reset_password_page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;
  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  String? _otpError;

  Future<void> _verifyOtp() async {
    setState(() => _otpError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('password_otps')
        .doc(widget.email)
        .get();

    if (!doc.exists) {
      setState(() {
        _otpError = "OTP has expired. Please request a new one.";
        _loading = false;
      });
      _formKey.currentState!.validate();
      return;
    }

    final data = doc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) {
      setState(() {
        _otpError = "OTP has expired. Please request a new one.";
        _loading = false;
      });
      _formKey.currentState!.validate();
      return;
    }

    if (_otpController.text.trim() != data['otp']) {
      setState(() {
        _otpError = "Invalid OTP. Please try again.";
        _loading = false;
      });
      _formKey.currentState!.validate();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: widget.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo1.png", height: 70),
            const SizedBox(height: 30),
            const Text(
              "Verify OTP",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: "6-digit OTP",
                  border: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (_otpError != null) return _otpError;
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter the OTP";
                  }
                  if (value.trim().length != 6) {
                    return "OTP must be 6 digits";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: _loading ? null : _verifyOtp,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Verify",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
