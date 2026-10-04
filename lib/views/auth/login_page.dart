import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/device_utils.dart';
import '../dashboard/dashboard_page.dart';
import 'google_profile_setup_page.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /* -------------------------------------------------------------------------- */
  /*                             REMEMBER ME LOGIC                              */
  /* -------------------------------------------------------------------------- */

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                          🔐 LOGIN SECURITY LOGIC                           */
  /* -------------------------------------------------------------------------- */

  Future<bool> _isAccountLocked(String email) async {
    final doc =
    await _firestore.collection('login_security').doc(email).get();

    if (!doc.exists) return false;

    final lockUntil = doc.data()?['lockUntil'];
    if (lockUntil == null) return false;

    final lockedUntil = (lockUntil as Timestamp).toDate();
    return DateTime.now().isBefore(lockedUntil);
  }

  Future<void> _handleFailedAttempt(String email) async {
    final ref = _firestore.collection('login_security').doc(email);
    final doc = await ref.get();

    int failedAttempts = 0;
    int lockLevel = 0;

    if (doc.exists) {
      failedAttempts = doc['failedAttempts'] ?? 0;
      lockLevel = doc['lockLevel'] ?? 0;
    }

    failedAttempts++;

    if (failedAttempts >= 3) {
      lockLevel++;
      failedAttempts = 0;

      final int lockMinutes =
      lockLevel == 1 ? 15 : lockLevel == 2 ? 30 : 60;

      await ref.set({
        'failedAttempts': failedAttempts,
        'lockLevel': lockLevel,
        'lockUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: lockMinutes)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'failedAttempts': failedAttempts,
        'lockLevel': lockLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _resetLoginSecurity(String email) async {
    await _firestore.collection('login_security').doc(email).delete();
  }

  /* -------------------------------------------------------------------------- */
  /*                               🔐 EMAIL LOGIN                               */
  /* -------------------------------------------------------------------------- */

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final bool isConnected =
    await InternetConnection().hasInternetAccess;

    if (!isConnected) {
      setState(() => _isLoading = false);
      _showError("Internet not available");
      return;
    }

    final email = _emailController.text.trim().toLowerCase();

    try {
      // 🔒 CHECK LOCK STATUS
      if (await _isAccountLocked(email)) {
        setState(() {
          _emailError = "Account temporarily locked. Please try again later.";
        });
        _formKey.currentState!.validate();
        return;
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      // ✅ SUCCESS → RESET LOCK
      await _resetLoginSecurity(email);

      await _handleRememberMe();

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('is_logged_in', true);
      } else {
        await prefs.remove('is_logged_in');
      }

      _showSuccess("Login successful");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      await _handleFailedAttempt(email);
      final code = e.code;
      if (code == 'user-not-found' || code == 'invalid-email') {
        _emailError = "No account found with this email";
      } else if (code == 'wrong-password' || code == 'invalid-credential') {
        _passwordError = "Incorrect password";
      } else {
        _emailError = "Invalid email or password";
      }
      setState(() {});
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               🔵 GOOGLE LOGIN                              */
  /* -------------------------------------------------------------------------- */


  Future<void> _saveUserSession({
    required String uid,
    required String email,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('auth_provider', 'google');
    await prefs.setString('user_uid', uid);
    await prefs.setString('user_email', email);
    await prefs.setString('username', username);
  }


  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    final bool isConnected =
    await InternetConnection().hasInternetAccess;

    if (!isConnected) {
      setState(() => _isLoading = false);
      _showError("Internet not available");
      return;
    }

    try {
      final authController = AuthController();
      final deviceType = DeviceUtils.getDeviceType();
      final result = await authController.signInWithGoogle(deviceType: deviceType);

      if (result == GoogleAuthStatus.newUser) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GoogleProfileSetupPage(),
          ),
        );
      } else {

        final user = FirebaseAuth.instance.currentUser!;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final username = doc['username'];

        // ✅ SAVE SESSION
        await _saveUserSession(
          uid: user.uid,
          email: user.email ?? '',
          username: username,
        );



        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                  UI HELPERS                                */
  /* -------------------------------------------------------------------------- */

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                     UI                                     */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              Image.asset('assets/images/logo2.png'),
              const SizedBox(height: 30),
              const Text(
                "Welcome! Sign in to proceed",
                style: TextStyle(letterSpacing: 1, fontSize: 16),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isLoading ? null : _loginWithGoogle,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    // color: Colors.black,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.black, // 👈 change this to any color
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/google.png",
                        width: 20,
                      ),
                      const Text(
                        "    Continue with Google",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _isLoading ? null : _loginWithGoogle,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    // color: Colors.black,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.black, // 👈 change this to any color
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/apple.png",
                        width: 20,
                      ),
                      const Text(
                        "    Continue with Apple",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_emailError != null) return _emailError;
                        if (value == null || value.trim().isEmpty) {
                          return "Email is required";
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (_passwordError != null) return _passwordError;
                        if (value == null || value.isEmpty) {
                          return "Password is required";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        checkColor: Colors.black,
                        fillColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text("Remember me"),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E729F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              // const SizedBox(height: 30),
              //
              // const Row(
              //   children: [
              //     Expanded(child: Divider()),
              //     Padding(
              //       padding: EdgeInsets.symmetric(horizontal: 10),
              //       child: Text("OR"),
              //     ),
              //     Expanded(child: Divider()),
              //   ],
              // ),

              const SizedBox(height: 30),



              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
