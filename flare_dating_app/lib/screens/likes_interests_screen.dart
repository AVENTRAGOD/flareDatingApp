import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'location_screen.dart'; // Next page

class LikesInterestsScreen extends StatefulWidget {
  final String email; // Captured from Profile Details Screen
  
  const LikesInterestsScreen({super.key, required this.email});

  @override
  State<LikesInterestsScreen> createState() => _LikesInterestsScreenState();
}

class _LikesInterestsScreenState extends State<LikesInterestsScreen> {
  // Predefined list from the design
  final List<Map<String, dynamic>> _interestsList = [
    {'name': 'Photography', 'icon': Icons.camera_alt_outlined},
    {'name': 'Cooking', 'icon': Icons.soup_kitchen_outlined},
    {'name': 'Video Games', 'icon': Icons.sports_esports_outlined},
    {'name': 'Music', 'icon': Icons.music_note_outlined},
    {'name': 'Travelling', 'icon': Icons.landscape_outlined},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Speeches', 'icon': Icons.mic_none},
    {'name': 'Art & Crafts', 'icon': Icons.palette_outlined},
    {'name': 'Swimming', 'icon': Icons.waves},
    {'name': 'Drinking', 'icon': Icons.local_drink_outlined},
    {'name': 'Extreme Sports', 'icon': Icons.sports_kabaddi},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
  ];

  final List<String> _selectedInterests = [];
  final int _maxSelection = 5;

  void _toggleInterest(String interestName) {
    setState(() {
      if (_selectedInterests.contains(interestName)) {
        _selectedInterests.remove(interestName);
      } else {
        if (_selectedInterests.length < _maxSelection) {
          _selectedInterests.add(interestName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can select a maximum of $_maxSelection interests.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    try {
      await DatabaseService.instance.updateUserProfile(widget.email, {'interests': _selectedInterests}).timeout(const Duration(seconds: 5));

      if (mounted) {
        // Navigate to the Location Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen(email: widget.email)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase error (dummy keys). Bypassing for preview...'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen(email: widget.email)),
        );
      }
    }
  }

  void _skip() {
    // Navigate without saving
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LocationScreen(email: widget.email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4C3090)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF14C86),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/side-view-couple-posing-with-sky-background.jpg'), // Placeholder background
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white60,
              BlendMode.lighten,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Likes, Interests',
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF322369),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your likes & passion with others',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B58A1),
                ),
              ),
              const SizedBox(height: 32),
              
              // Interests Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _interestsList.length,
                    itemBuilder: (context, index) {
                      final interest = _interestsList[index];
                      final isSelected = _selectedInterests.contains(interest['name']);
                      
                      return GestureDetector(
                        onTap: () => _toggleInterest(interest['name']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: isSelected 
                              ? null 
                              : Border.all(color: Colors.transparent),
                            gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          ),
                          padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  interest['icon'],
                                  size: 18,
                                  color: isSelected ? const Color(0xFFF14C86) : const Color(0xFF8C7DA7),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    interest['name'],
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: const Color(0xFF322369),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Load More Button
              TextButton(
                onPressed: () {
                  // TODO: Implement loading more interests if needed
                },
                child: Text(
                  'Load More',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB451CD), // Purple-pinkish color
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
