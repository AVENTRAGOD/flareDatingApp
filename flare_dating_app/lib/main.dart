import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yoleyzkonnuxllvsqohi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvbGV5emtvbm51eGxsdnNxb2hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTUwMTAsImV4cCI6MjA5MTIzMTAxMH0.U50YJdumRR2vbbHcw06SZYXtxcidq00CHhFmk-8x2qs',
  );

  // Fire and forget dummy tester profiles so it doesn't block the UI
  DatabaseService.instance.seedDummyUsers();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const FlareDatingApp(),
    ),
  );
}

class FlareDatingApp extends StatelessWidget {
  const FlareDatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
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
