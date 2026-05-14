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
                // Premium Direct Access Button (Developer Bypass)
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainContainerScreen(currentUserEmail: 'nisalsayuranga0710@gmail.com'),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC556B8), Color(0xFF8B51E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Direct Access',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
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
        ],
      ),
    );
  }
}
