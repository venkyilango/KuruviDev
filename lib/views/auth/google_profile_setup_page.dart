import 'package:flutter/material.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/validators.dart';
import '../../utils/device_utils.dart';
import '../../utils/location_utils.dart';
import '../auth/login_page.dart';
import '../../main.dart';

class GoogleProfileSetupPage extends StatefulWidget {
  const GoogleProfileSetupPage({super.key});

  @override
  State<GoogleProfileSetupPage> createState() =>
      _GoogleProfileSetupPageState();
}

class _GoogleProfileSetupPageState extends State<GoogleProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
  TextEditingController();
  final TextEditingController _dobController =
  TextEditingController();
  final TextEditingController _phoneController =
  TextEditingController();
  String? _fullPhoneNumber;
  String? _nationalNumber;
  String? _countryISO;

  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _usernameError;

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


  /* -------------------------------------------------------------------------- */
  /*                                   DOB PICKER                                */
  /* -------------------------------------------------------------------------- */

  Future<void> _selectDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _dobController.text =
      "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                          ENABLE LOCATION POPUP                              */
  /* -------------------------------------------------------------------------- */

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Enable Location"),
        content: const Text(
          "Location is required to create an account. "
              "Please enable location services to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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

  void _showError(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              COMPLETE SIGNUP                                */
  /* -------------------------------------------------------------------------- */

  Future<void> _completeSignup() async {
    setState(() => _usernameError = null);
    if (!_formKey.currentState!.validate()) return;

    // if (!_acceptTerms) {
    //   _showError("Please accept Terms & Conditions");
    //   return;
    // }

    setState(() => _isLoading = true);

    try {
      final deviceType = DeviceUtils.getDeviceType();
      final location = await LocationUtils.getLocation();



      await AuthController().completeGoogleSignup(
        username: _usernameController.text,
        dob: _dobController.text,
        phone: _fullPhoneNumber ?? "",
        deviceType: deviceType,
        latitude: location['lat'],
        longitude: location['lng'],
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      if (e == 'LOCATION_SERVICE_DISABLED') {
        _showEnableLocationDialog();
      } else if (e == 'LOCATION_PERMISSION_DENIED') {
        _showError("Location permission is required to continue");
      } else {
        final msg = e.toString();
        if (msg.contains('username') && msg.contains('already')) {
          _usernameError = "This username is already taken";
          setState(() {});
          _formKey.currentState!.validate();
        } else {
          _showError(msg);
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                    UI                                      */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo2.png'),
                  const SizedBox(height: 30),
                  const Text(
                    "Complete your Signup Process",
                    style: TextStyle(
                      letterSpacing: 1,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // USERNAME
                          TextFormField(
                            controller: _usernameController,
                            maxLength: 13,
                            decoration: const InputDecoration(
                              labelText: "Username",
                            ),
                            validator: (v) {
                              if (_usernameError != null) return _usernameError;
                              if (v == null || v.isEmpty) return "Username required";
                              if (!Validators.validUsername(v)) {
                                return "Only letters & numbers (max 13)";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // DOB
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "Date of Birth",
                              suffixIcon:
                              Icon(Icons.calendar_today),
                            ),
                            onTap: _selectDOB,
                            validator: (v) =>
                            v!.isEmpty ? "DOB required" : null,
                          ),

                          const SizedBox(height: 20),

                          // PHONE
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

                          const SizedBox(height: 20),

                          // TERMS
                          // TERMS
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text(
                                "I agree to the ",
                                style: TextStyle(fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: _showTermsAndConditions,
                                child: const Text(
                                  "Terms & Conditions",
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Text(
                                " and ",
                                style: TextStyle(fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: _showTermsAndConditions,
                                child: const Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),


                          const SizedBox(height: 40),

                          // SUBMIT BUTTON
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
                              onPressed:
                              _isLoading ? null : _completeSignup,
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔄 LOADING OVERLAY
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
