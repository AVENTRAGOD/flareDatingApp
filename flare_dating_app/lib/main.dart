import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fire and forget dummy tester profiles so it doesn't block the UI
  DatabaseService.instance.seedDummyUsers();

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
