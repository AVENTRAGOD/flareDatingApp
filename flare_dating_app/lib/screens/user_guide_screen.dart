import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5),
      appBar: AppBar(
        title: Text(
          'User Guide',
          style: GoogleFonts.nunito(
            color: const Color(0xFF322369),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5E5088)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideSection(
                icon: Icons.swipe,
                title: 'How to Match',
                content: 'Swipe right on profiles you like, and left on profiles you want to pass. If they swipe right on you too, it\'s a match!',
              ),
              const SizedBox(height: 24),
              _buildGuideSection(
                icon: Icons.chat_bubble,
                title: 'Messaging',
                content: 'Once you match with someone, head to the Chats tab to start a conversation. You can send text and photos!',
              ),
              const SizedBox(height: 24),
              _buildGuideSection(
                icon: Icons.person_search,
                title: 'Finding People',
                content: 'We automatically match you with users who share at least 2 interests with you. Alternatively, use the Search bar to find specific people.',
              ),
              const SizedBox(height: 24),
              _buildGuideSection(
                icon: Icons.notifications_active,
                title: 'Notifications',
                content: 'Check your notifications (the bell icon) to see who has liked your profile. Mutual likes automatically turn into matches!',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection({required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFDE8F5),
                ),
                child: Icon(icon, color: const Color(0xFFC76CD9), size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF322369),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
