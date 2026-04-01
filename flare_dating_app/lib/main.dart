import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Automatically seed 10 dummy tester profiles if they don't exist
  await DatabaseService.instance.seedDummyUsers();

  runApp(const FlareDatingApp());
}

class FlareDatingApp extends StatelessWidget {
  const FlareDatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC556B8)),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
