import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/auth/login_page.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> _images = [
    'assets/images/splash1.png',
    'assets/images/splash2.png',
    'assets/images/splash3.png',
  ];

  List heading = [
    "Find Your Perfect Travel Companion",
    "Receive/Send Packages Abroad",
    "Rate Travelers & Build Trust"
  ];

  List subHeading =[
    "Connect with verified travelers heading to your destination. Make your journey safer and more enjoyable.",
    "Need to send documents or items abroad? Connect with travelers willing to help carry your parcels safely.",
    "Share feedback after each trip. Build your reputation and travel with confidence."
  ];

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _nextPage() {
    if (_currentIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: Column(
          children: [
            // 🔹 SKIP TEXT
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _finishTutorial,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 10),
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🔹 CAROUSEL
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      _images[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(left: 10,right: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    heading[_currentIndex],
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsetsGeometry.only(left: 10,right: 5),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subHeading[_currentIndex],
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),

            SizedBox(height: 50,),

            // 🔹 DOT INDICATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: _currentIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color:
                    _currentIndex == index ? Colors.black : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),


            // 🔹 NAVIGATION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _currentIndex == 0 ? null : _prevPage,
                    child: const Text("Back"),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E729F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _currentIndex == _images.length - 1
                        ? _finishTutorial
                        : _nextPage,
                    child: Text(
                      _currentIndex == _images.length - 1 ? "Finish" : "Next",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
}
