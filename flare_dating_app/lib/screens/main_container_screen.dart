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
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFC76CD9),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.style, size: 28), // Cards icon
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded, size: 28), // Grid icon
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 28), // Chat icon
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28), // Profile icon
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
