import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:travel/views/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Must be registered before runApp so messages that arrive while the app is
  // terminated are still handled.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Push setup is best-effort: a failure here must never block app start.
  unawaited(PushNotificationService.initialise());

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

