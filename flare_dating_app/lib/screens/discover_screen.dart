import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'search_users_screen.dart';
import 'notifications_screen.dart';
import 'chat_room_screen.dart';
import 'match_screen.dart';
import '../services/database_service.dart';
import '../services/achievement_service.dart';

class DiscoverScreen extends StatefulWidget {
  final String currentUserEmail;

  const DiscoverScreen({super.key, required this.currentUserEmail});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CardSwiperController controller = CardSwiperController();

  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  List<Map<String, dynamic>> allValidUsers = []; // Cache of users before search filtering
  List<String> myInterests = [];
  String myAvatar = '';
  String _myPreferredGender = 'Everyone';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final myProfile = await DatabaseService.instance.getUserProfile(widget.currentUserEmail)
          .timeout(const Duration(seconds: 5));
      if (myProfile != null) {
        if (myProfile['interests'] != null) {
          myInterests = List<String>.from(myProfile['interests']);
        }
        myAvatar = myProfile['avatar_path']?.toString() ?? '';
        _myPreferredGender = myProfile['preferred_gender']?.toString() ?? 'Everyone';
      }

      final fetchedUsers = await DatabaseService.instance.getAllUsers()
          .timeout(const Duration(seconds: 5));
      final swipedUsers = await DatabaseService.instance.getSwipedUsers(widget.currentUserEmail)
          .timeout(const Duration(seconds: 5));
      
      setState(() {
        allValidUsers = fetchedUsers.where((user) {
          final email = user['email']?.toString() ?? '';
          if (email == widget.currentUserEmail || swipedUsers.contains(email)) return false;
          
          final first = user['first_name']?.toString() ?? '';
          final date = user['dob']?.toString() ?? '';
          final gender = user['gender']?.toString() ?? 'Unknown';

          // Preference filter
          if (_myPreferredGender == 'Men' && gender != 'Male') return false;
          if (_myPreferredGender == 'Women' && gender != 'Female') return false;

          return first.isNotEmpty && date.isNotEmpty;
        }).toList();

        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      // Professional Matchmaking Algorithm:
      // 1. Calculate scores for all users based on interest overlap
      // 2. Sort by score descending
      // 3. Keep users with at least 1 match if pool is large, otherwise show all
      
      final scoredUsers = allValidUsers.map((user) {
        final targetInterests = List<String>.from(user['interests'] ?? []);
        final overlap = myInterests.where((i) => targetInterests.contains(i)).length;
        return {'user': user, 'score': overlap};
      }).toList();

      // Sort by best matches first
      scoredUsers.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      if (myInterests.isNotEmpty) {
        // If we have interests, prioritize those with at least 1 match
        final matches = scoredUsers.where((u) => (u['score'] as int) >= 1).map((u) => u['user'] as Map<String, dynamic>).toList();
        
        if (matches.isNotEmpty) {
          users = matches;
        } else {
          // Fallback: Show everyone if no strict matches found
          users = allValidUsers;
          // Shuffle fallback to keep it fresh
          users.shuffle();
        }
      } else {
        // No interests? Show everyone
        users = allValidUsers;
        users.shuffle();
      }
      
      isLoading = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore',
                        style: GoogleFonts.nunito(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      Text(
                        'Find your perfect match',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderIcon(Icons.search_rounded, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchUsersScreen(
                              currentUserEmail: widget.currentUserEmail,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      _buildHeaderIcon(Icons.notifications_none_rounded, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(
                              currentUserEmail: widget.currentUserEmail,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Swipe Cards Area
            Expanded(
              child: isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF14C86)),
                  )
                  : users.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: CardSwiper(
                          controller: controller,
                          cardsCount: users.length,
                          onSwipe: _onSwipe,
                          onUndo: _onUndo,
                          numberOfCardsDisplayed: users.length > 2 ? 3 : users.length,
                          backCardOffset: const Offset(0, 30),
                          padding: const EdgeInsets.all(0),
                          cardBuilder: (
                            context,
                            index,
                            horizontalThresholdPercentage,
                            verticalThresholdPercentage,
                          ) {
                            return _buildCard(users[index]);
                          },
                        ),
                      ),
            ),
            const SizedBox(height: 80), // Space for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Icon(icon, color: const Color(0xFFF14C86), size: 22),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 64,
              color: const Color(0xFFF14C86).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for more profiles',
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF14C86),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Refresh Feed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> user) {
    final fullName =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final location = user['location']?.toString() ?? 'Nearby';
    final avatarPath = user['avatar_path']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showUserDetails(context, user),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // User Image
              Builder(
                builder: (context) {
                  final imgProvider = _getAvatarImage(avatarPath);
                  return imgProvider != null
                      ? Image(image: imgProvider, fit: BoxFit.cover)
                      : Container(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        child: Icon(
                          Icons.person_rounded,
                          size: 100,
                          color: Colors.grey[300],
                        ),
                      );
                },
              ),

              // Light gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Info Overlay
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    location,
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            _buildCardAction(
                              Icons.chat_bubble_rounded,
                              Colors.white.withOpacity(0.2),
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      currentUserEmail: widget.currentUserEmail,
                                      targetUserEmail:
                                          user['email']?.toString() ?? '',
                                      targetUserName: fullName,
                                      targetUserAvatar: avatarPath,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildCardAction(
                              Icons.favorite_rounded,
                              const Color(0xFFF14C86),
                              () async {
                                final targetEmail =
                                    user['email']?.toString() ?? '';
                                await DatabaseService.instance
                                    .forceMutualMatch(
                                      widget.currentUserEmail,
                                      targetEmail,
                                    );
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MatchScreen(
                                        currentUserEmail: widget.currentUserEmail,
                                        targetUserEmail: targetEmail,
                                        targetUserName: fullName,
                                        targetUserAvatar: avatarPath,
                                        currentUserAvatar: myAvatar,
                                      ),
                                    ),
                                  );
                                  controller.swipe(CardSwiperDirection.right);
                                }
                              },
                              isPrimary: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPrimary ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString() ?? 'Unknown';
    final lastName = user['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final location = user['location']?.toString() ?? 'Nearby';
    final avatarPath = user['avatar_path']?.toString() ?? '';
    final interests = List<String>.from(user['interests'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image
                      Container(
                        height: 400,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Builder(
                                builder: (context) {
                                  final imgProvider =
                                      _getAvatarImage(avatarPath);
                                  return imgProvider != null
                                      ? Image(
                                        image: imgProvider,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        color: Colors.grey[100],
                                        child: Icon(
                                          Icons.person,
                                          size: 100,
                                          color: Colors.grey[200],
                                        ),
                                      );
                                },
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: _buildHeaderIcon(
                                Icons.close_rounded,
                                () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.nunito(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFF14C86),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Interests',
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  interests
                                      .map(
                                        (i) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFF14C86,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFF14C86,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            i,
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFFF14C86),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider? _getAvatarImage(String avatarPath) {
    if (avatarPath.isEmpty) return null;
    if (avatarPath.startsWith('data:image')) {
      try {
        final base64Str = avatarPath.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(avatarPath);
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex < 0 || previousIndex >= users.length) return true;
    final targetUserEmail = users[previousIndex]['email']?.toString() ?? '';
    final targetUserName = users[previousIndex]['first_name']?.toString() ?? 'User';
    final targetUserAvatar = users[previousIndex]['avatar_path']?.toString() ?? '';
    
    if (targetUserEmail.isNotEmpty) {
      if (direction == CardSwiperDirection.right) {
        DatabaseService.instance.recordInteraction(widget.currentUserEmail, targetUserEmail, true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liked!'),
              duration: Duration(milliseconds: 1000),
              backgroundColor: Color(0xFFC76CD9),
            ),
          );
          // Check for achievements
          AchievementService.instance.checkAndNotify(widget.currentUserEmail, context);
        }
      } else if (direction == CardSwiperDirection.left) {
        DatabaseService.instance.recordInteraction(widget.currentUserEmail, targetUserEmail, false);
        // Check for achievements (passes also count)
        AchievementService.instance.checkAndNotify(widget.currentUserEmail, context);
      }
    }
    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    return true;
  }
}
