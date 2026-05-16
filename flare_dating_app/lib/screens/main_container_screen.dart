import 'dart:ui';
import 'package:flutter/material.dart';
import 'discover_screen.dart';
import 'matches_screen.dart';
import 'chats_list_screen.dart';
import 'user_profile_tab.dart';
import '../services/database_service.dart';

class MainContainerScreen extends StatefulWidget {
  final String currentUserEmail;

  const MainContainerScreen({
    super.key,
    required this.currentUserEmail,
  });

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DiscoverScreen(currentUserEmail: widget.currentUserEmail),
      MatchesScreen(currentUserEmail: widget.currentUserEmail),
      ChatsListScreen(currentUserEmail: widget.currentUserEmail), 
      UserProfileTab(currentUserEmail: widget.currentUserEmail),
    ];
    // Clean up tester accounts and fake scores on start
    DatabaseService.instance.clearDummyUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating bar
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.style_rounded),
            _buildNavItem(1, Icons.grid_view_rounded),
            _buildNavItem(2, Icons.chat_bubble_rounded),
            _buildNavItem(3, Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFF14C86) : Colors.grey[400],
            size: 28,
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFF14C86),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
