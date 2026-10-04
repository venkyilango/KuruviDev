import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../main.dart';
import '../../utils/device_utils.dart';
import '../../utils/location_utils.dart';
import '../../utils/validators.dart';
import '../dashboard/dashboard_page.dart';
import 'google_profile_setup_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _fullPhoneNumber;
  String? _nationalNumber;
  String? _countryISO;
  String? _emailError;
  String? _usernameError;
  String? _termsError;



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

  Future<void> _googleSignup() async {
    setState(() => _isLoading = true);

    final bool isConnected = await InternetConnection().hasInternetAccess;
    if (isConnected) {
      try {
        final authController = AuthController();
        final deviceType = DeviceUtils.getDeviceType();
        final result = await authController.signInWithGoogle(deviceType: deviceType);

        if (result == GoogleAuthStatus.newUser) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoogleProfileSetupPage()),
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

          // ✅ NAVIGATE TO DASHBOARD
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      } catch (e) {
        _showError(e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
      _showError("Internet not available");
    }
  }

  Future<void> _selectDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }


  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Enable Location",style: TextStyle(color: Colors.black),),
        content: const Text(
          "Location is required to create an account. "
              "Please enable location services to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor:    WidgetStateProperty.all<Color>(Colors.black),
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await LocationUtils.openLocationSettings();
            },
            child: const Text("Turn On Location"),
          ),
        ],
      ),
    );
  }



  void _signup() async {
    setState(() {
      _emailError = null;
      _usernameError = null;
      _termsError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() => _termsError = "Please accept Terms & Conditions");
      return;
    }

    final bool isConnected = await InternetConnection().hasInternetAccess;
    if (isConnected) {

        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );


          final deviceType = DeviceUtils.getDeviceType();
          final location = await LocationUtils.getLocation();

          await AuthController().createUser(
            email: _emailController.text,
            password: _passwordController.text,
            username: _usernameController.text,
            contact: _fullPhoneNumber ?? "",
            dob: _dobController.text,
            deviceType: deviceType,
            latitude: location['lat']!,
            longitude: location['lng']!,
          );



          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context); // back to login
          });


        } catch (e) {
          Navigator.of(context).pop();
          if (e == 'LOCATION_SERVICE_DISABLED') {
            _showEnableLocationDialog();
          } else if (e == 'LOCATION_PERMISSION_DENIED') {
            _showError(
              "Location permission is required to continue",
            );
          } else {
            final msg = e.toString();
            if (e is FirebaseAuthException) {
              if (e.code == 'email-already-in-use') {
                _emailError = "This email is already registered";
              } else if (e.code == 'invalid-email') {
                _emailError = "Enter a valid email address";
              } else if (e.code == 'weak-password') {
                _showError("Password is too weak");
                return;
              }
            } else if (msg.contains('email-already-in-use') ||
                msg.contains('already in use')) {
              _emailError = "This email is already registered";
            } else if (msg.contains('username') &&
                msg.contains('already')) {
              _usernameError = "This username is already taken";
            }

            if (_emailError != null || _usernameError != null) {
              setState(() {});
              _formKey.currentState!.validate();
            } else {
              _showError(msg);
            }
          }
        }

    } else {
      setState(() => _isLoading = false);
      _showError("Internet not available");
    }
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Text(
                  "Terms & Conditions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 20),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Text('''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

1. You must be at least 18 years old to use this application.
2. You agree not to misuse the platform.
3. Your data will be stored securely and processed according to our privacy policy.
4. The application is provided "as is" without warranties.
5. We reserve the right to suspend accounts violating our terms.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                  ''', style: const TextStyle(fontSize: 14, height: 1.6)),
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E729F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 80),
                Image.asset('assets/images/logo2.png'),
                const SizedBox(height: 40),
                Text(
                  "Welcome! Create new account",
                  style: TextStyle(letterSpacing: 1, fontSize: 16),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _isLoading ? null : _googleSignup,
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
                  onTap: _isLoading ? null : _googleSignup,
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
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // USERNAME
                      TextFormField(
                        controller: _usernameController,
                        maxLength: 13,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_usernameError != null) return _usernameError;
                          if (value == null || value.isEmpty) {
                            return "Username required";
                          }
                          if (!Validators.validUsername(value)) {
                            return "Only letters & numbers (max 13)";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // EMAIL
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
                            return "Email required";
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // CONTACT
                      IntlPhoneField(
                        decoration: const InputDecoration(
                          labelText: "Contact Number",
                          prefixIcon: Icon(Icons.phone),
                          border: UnderlineInputBorder(),
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (phone) {
                          _fullPhoneNumber = phone.completeNumber; // +91xxxxxxxxxx
                          _nationalNumber = phone.number;          // xxxxxxxxxx
                          _countryISO = phone.countryISOCode;      // IN
                        },
                        validator: (phone) {
                          if (phone == null) {
                            return "Phone number required";
                          }

                          final number = phone.number;
                          final country = phone.countryISOCode;

                          // 🇮🇳 INDIA RULE (STRICT)
                          if (country == 'IN' && number.length != 10) {
                            return "Indian phone number must be 10 digits";
                          }

                          // 🌍 GENERIC RULE (other countries)
                          if (number.length < 6 || number.length > 15) {
                            return "Invalid phone number";
                          }

                          return null;
                        },
                      ),


                      const SizedBox(height: 12),

                      // DOB
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date of Birth",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: _selectDOB,
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "DOB required" : null,
                      ),

                      const SizedBox(height: 12),

                      // PASSWORD
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
                          if (value == null || value.isEmpty) {
                            return "Password required";
                          }
                          if (!Validators.validPassword(value)) {
                            return "8–12 chars, 1 caps, 1 number, 1 symbol";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // TERMS & CONDITIONS
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            checkColor: Colors.black,
                            fillColor: WidgetStateProperty.all<Color>(Colors.white),
                            onChanged: (val) {
                              setState(() {
                                _acceptTerms = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Wrap(
                              children: [
                                const Text("I agree to the ",style: TextStyle(fontSize: 12),),
                                GestureDetector(
                                  onTap: () {
                                    _showTermsAndConditions();
                                  },
                                  child: const Text(
                                    "Terms & Conditions",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(" and ",style: TextStyle(fontSize: 12)),
                                GestureDetector(
                                  onTap: () {
                                    _showTermsAndConditions();
                                  },
                                  child: const Text(
                                    "Privacy policy",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_termsError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            _termsError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // SIGNUP BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E729F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      //
                      // const Row(
                      //   children: [
                      //     Expanded(child: Divider()),
                      //     Padding(
                      //       padding: EdgeInsets.symmetric(horizontal: 10),
                      //       child: Text(
                      //         "OR",
                      //         style: TextStyle(color: Colors.black),
                      //       ),
                      //     ),
                      //     Expanded(child: Divider()),
                      //   ],
                      // ),
                      //
                      // const SizedBox(height: 20),
                      //
                      // GestureDetector(
                      //   onTap: _isLoading ? null : _googleSignup,
                      //
                      //   child: Container(
                      //     width: double.infinity,
                      //     height: 48,
                      //     decoration: BoxDecoration(
                      //       color: Colors.black,
                      //       borderRadius: BorderRadius.circular(25),
                      //     ),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Image.asset("assets/images/google.png", width: 20),
                      //         const Text(
                      //           "    Sign up with Google",
                      //           style: TextStyle(color: Colors.white),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),

                      const SizedBox(height: 20),

                      // LOGIN REDIRECT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Log In",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

              ],
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }
}
