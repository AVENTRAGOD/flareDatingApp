import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'main_container_screen.dart'; // Next page Placeholder

class LocationScreen extends StatefulWidget {
  final String email;

  const LocationScreen({super.key, required this.email});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
    'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
    'Matale', 'Matara', 'Moneragala', 'Mullaitivu', 'Nuwara Eliya',
    'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya',
  ];

  String? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredDistricts = [];

  @override
  void initState() {
    super.initState();
    _filteredDistricts = _districts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredDistricts = _districts
          .where((district) =>
              district.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    try {
      await DatabaseService.instance.updateUserProfile(widget.email, {'location': _selectedLocation}).timeout(const Duration(seconds: 5));

      if (mounted) {
        // Navigate to the next screen (e.g., Main Container)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainContainerScreen(currentUserEmail: widget.email)),
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
          MaterialPageRoute(builder: (context) => MainContainerScreen(currentUserEmail: widget.email)),
        );
      }
    }
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/side-view-couple-posing-with-sky-background.jpg'), // Defaulting to one of the available assets
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white54,
              BlendMode.lighten,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Location',
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF322369),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Let the app locate you to provide best searched results around you',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B58A1),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Placeholder for "Current Location - GPS feature"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Current Location',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF322369),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFF14C86)),
                      const SizedBox(width: 8),
                      Text(
                        '$_selectedLocation, Sri Lanka',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF322369),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // Search Location Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF8C7DA7), width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: const Color(0xFF322369),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search New Location',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 16,
                        color: const Color(0xFF8C7DA7),
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8C7DA7)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Dropdown List of Districts based on search
              if (_searchController.text.isNotEmpty || _selectedLocation == null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredDistricts.length,
                        itemBuilder: (context, index) {
                          final district = _filteredDistricts[index];
                          return ListTile(
                            title: Text(
                              district,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF322369),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedLocation = district;
                                _searchController.clear(); // Clear search on select
                                FocusScope.of(context).unfocus(); // Close keyboard
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              
              if (_searchController.text.isEmpty && _selectedLocation != null)
                const Spacer(),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 24.0),
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
