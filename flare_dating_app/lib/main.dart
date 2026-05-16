import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding_screen.dart';
import 'screens/main_container_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yoleyzkonnuxllvsqohi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvbGV5emtvbm51eGxsdnNxb2hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTUwMTAsImV4cCI6MjA5MTIzMTAxMH0.U50YJdumRR2vbbHcw06SZYXtxcidq00CHhFmk-8x2qs',
  );

  // Seed dummy data
  DatabaseService.instance.seedDummyUsers();

  // Check for session
  final prefs = await SharedPreferences.getInstance();
  final cachedEmail = prefs.getString('currentUserEmail');

  runApp(
    FlareDatingApp(initialEmail: cachedEmail),
  );
}

class FlareDatingApp extends StatelessWidget {
  final String? initialEmail;
  const FlareDatingApp({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0B1F), // Deep midnight
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF14C86),
          brightness: Brightness.dark,
          surface: const Color(0xFF16122D),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: initialEmail != null && initialEmail!.isNotEmpty
          ? MainContainerScreen(currentUserEmail: initialEmail!)
          : const OnboardingScreen(),
    );
  }
}
