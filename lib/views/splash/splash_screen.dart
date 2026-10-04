import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tutorial/tutorial_page.dart';
import '../auth/login_page.dart';
import '../dashboard/dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();

    // First time launch check
    final bool isFirstLaunch =
        prefs.getBool('is_first_launch') ?? true;

    // Logged-in check
    final bool isLoggedIn =
        prefs.getBool('is_logged_in') ?? false;


    Timer(const Duration(seconds: 5), () async {
      if (isFirstLaunch) {
        // Mark first launch as completed
        await prefs.setBool('is_first_launch', false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorialPage(),
          ),
        );
      } else if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Image.asset('assets/images/logo1.png'),
          ],
        ),
      ),
    );
  }
}
