import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:travel/views/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Kuruvi',
      theme: ThemeData(
        primaryColor: const Color(0xFF3E729F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E729F),
        ),
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: const Color(0xFF3E729F),
          headerForegroundColor: Colors.white,
          todayForegroundColor:
          MaterialStateProperty.all(const Color(0xFF3E729F)),
          todayBorder:
          BorderSide(color: const Color(0xFF3E729F)),
          dayForegroundColor:
          MaterialStateProperty.all(Colors.black),
          yearForegroundColor:
          MaterialStateProperty.all(Colors.black),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

