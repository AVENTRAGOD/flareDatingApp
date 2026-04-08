import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BePatientScreen extends StatelessWidget {
  final String targetUserAvatar;

  const BePatientScreen({super.key, required this.targetUserAvatar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5), // Light pinkish
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Single Outline Avatar Circle
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF322369), // Dark purple border
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: Builder(builder: (context) {
                    ImageProvider? imgProvider;
                    if (targetUserAvatar.isNotEmpty) {
                      if (targetUserAvatar.startsWith('data:image')) {
                        try { imgProvider = MemoryImage(base64Decode(targetUserAvatar.split(',').last)); } catch (_) {}
                      } else {
                        imgProvider = NetworkImage(targetUserAvatar);
                      }
                    }
                    return imgProvider != null
                        ? Image(image: imgProvider, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackIcon())
                        : _fallbackIcon();
                  }),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Text Content
            Text(
              'Be Patient',
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF322369), // Dark purple
              ),
            ),
            
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Don\'t loose heart, keep browsing to\nfind your best match',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5E5088),
                  height: 1.4,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Start Swiping CTA
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Start Swiping',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC76CD9), // Pinkish hue
                  letterSpacing: 1,
                ),
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.transparent,
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.grey,
          size: 80,
        ),
      ),
    );
  }
}
