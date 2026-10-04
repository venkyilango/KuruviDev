import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/validators.dart';
import 'verify_otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  String _generateOtp() {
    final r = Random();
    return (100000 + r.nextInt(900000)).toString();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _loading = true);

    try {
      final otp = _generateOtp();

      await FirebaseFirestore.instance
          .collection('password_otps')
          .doc(email)
          .set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
        Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      });

      // 👉 EMAIL WILL BE SENT VIA CLOUD FUNCTION / SENDGRID
      _show("OTP sent to your email", success: true);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpPage(email: email),
        ),
      );
    } catch (e) {
      _show("Failed to send OTP");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _show(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
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
            Image.asset("assets/images/logo1.png", height: 80),
            const SizedBox(height: 40),
            const Text(
              "Reset Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Registered Email",
                  prefixIcon: Icon(Icons.email),
                  border: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Email is required";
                  }
                  if (!Validators.isValidEmail(value.trim())) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: _loading ? null : _sendOtp,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Send OTP",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
