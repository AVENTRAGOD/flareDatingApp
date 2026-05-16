import 'dart:ui';
import 'package:flutter/material.dart';
import 'discover_screen.dart';
import 'matches_screen.dart';
import 'chats_list_screen.dart';
import 'user_profile_tab.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating bar
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
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
            ),
          ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
