import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'welcome_screen.dart';
import 'main_container_screen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> _quotes = [
    {
      'title': 'Find Your Destined One',
      'subtitle': 'Find genuine relationships based on shared values and interests, not just looks.',
    },
    {
      'title': 'Sparks that Last',
      'subtitle': 'Build meaningful connections that go beyond the surface and stand the test of time.',
    },
    {
      'title': 'A Journey Together',
      'subtitle': 'Discover someone who truly understands you and shares your vision for the future.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/side_view_man_woman_being_romantic_6.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Cloudy / Rain vibe overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.65), // Light cloudy at top/middle
                    Colors.white.withOpacity(0.3),
                    Colors.black.withOpacity(0.55), // Darker at bottom for text contrast
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Stack(
              children: [
                // Bypass Login Button (Temporary)
                Positioned(
                  top: 10,
                  right: 10,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainContainerScreen(currentUserEmail: 'tester1@example.com'),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Skip Login',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        shadows: [
                          const Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                const Spacer(flex: 8),
                
                // Carousel
                CarouselSlider(
                  options: CarouselOptions(
                    height: 180.0,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  items: _quotes.map((quote) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            quote['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC556B8), // Pinkish purple
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quote['subtitle']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.blueGrey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _quotes.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == entry.key
                            ? const Color(0xFFC556B8)
                            : Colors.grey.withOpacity(0.5),
                      ),
                    );
                  }).toList(),
                ),
                
                const Spacer(flex: 9),
                
// ... previous code ...
                // Get Started Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC556B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFFC556B8),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
