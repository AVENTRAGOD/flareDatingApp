import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'search_users_screen.dart';
import 'notifications_screen.dart';
import 'chat_room_screen.dart';
import 'match_screen.dart';
import '../services/database_service.dart';

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
      backgroundColor: const Color(0xFFFDE8F5), // Light pinkish background from design
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Flare',
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF322369),
                        ),
                      ),
                    ],
                  ),
                  
                  // Action Icons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Color(0xFF5E5088), size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchUsersScreen(
                                currentUserEmail: widget.currentUserEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Color(0xFF5E5088), size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(
                                currentUserEmail: widget.currentUserEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFF5E5088), size: 28),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Filter options coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Swipe Cards Area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 64, color: const Color(0xFFC76CD9).withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No more profiles around you.',
                                style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF322369),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later or expand your interests!',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  color: const Color(0xFF5E5088),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadUsers,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC76CD9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Refresh', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: CardSwiper(
                            controller: controller,
                            cardsCount: users.length,
                            onSwipe: _onSwipe,
                            onUndo: _onUndo,
                            numberOfCardsDisplayed: users.length > 2 ? 3 : users.length,
                            backCardOffset: const Offset(0, 20),
                            padding: const EdgeInsets.all(8.0),
                            cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                              final user = users[index];
                              return _buildCard(user);
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString() ?? 'Unknown';
    final lastName = user['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final location = user['location']?.toString() ?? 'Unknown Location';
    final avatarPath = user['avatar_path']?.toString() ?? '';
    
    // Calculate exact age from ISO dob
    String age = '';
    final dobString = user['dob']?.toString() ?? '';
    if (dobString.isNotEmpty) {
      try {
        DateTime dob = DateTime.parse(dobString);
        DateTime now = DateTime.now();
        int calcAge = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calcAge--;
        }
        age = ', $calcAge';
      } catch (e) {
        // ignore
      }
    }

    // Extract interests
    List<dynamic> rawInterests = user['interests'] ?? [];
    List<String> interests = rawInterests.map((e) => e.toString()).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85, // 85% of screen height
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Huge Banner Image
                  Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    color: Colors.grey[300],
                    child: Builder(builder: (context) {
                      final imgProvider = _getAvatarImage(avatarPath);
                      if (imgProvider != null) {
                        return Image(image: imgProvider, fit: BoxFit.cover);
                      }
                      return Center(child: Icon(Icons.person, size: 100, color: Colors.grey[500]));
                    }),
                  ),
                  
                  // Details Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Age
                        Text(
                          '$fullName$age',
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF322369),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFC76CD9), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // About / Interests
                        Text(
                          'Interests',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF322369),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (interests.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFC76CD9).withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFFFDE8F5),
                                ),
                                child: Text(
                                  interest,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFC76CD9),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            'No interests added yet.',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                        const SizedBox(height: 40),
                        
                        // Close Details Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC76CD9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              'Close Profile',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns the correct ImageProvider for any avatar (base64 or network URL)
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

  Widget _buildCard(Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString() ?? 'Unknown';
    final lastName = user['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final location = user['location']?.toString() ?? 'Unknown Location';
    final avatarPath = user['avatar_path']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showUserDetails(context, user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // User Image (supports base64 and network URLs)
              Builder(builder: (context) {
                final imgProvider = _getAvatarImage(avatarPath);
                if (imgProvider != null) {
                  return Image(
                    image: imgProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Center(child: Icon(Icons.person, size: 80, color: Colors.grey[600])),
                    ),
                  );
                }
                return Container(
                  color: const Color(0xFF6C3FC7),
                  child: Center(child: Icon(Icons.person, size: 80, color: Colors.white.withOpacity(0.5))),
                );
              }),
              
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              
              // User Details Overlay
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar circle (bottom-left of card)
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF8B51E5),
                          backgroundImage: _getAvatarImage(avatarPath),
                          child: _getAvatarImage(avatarPath) == null
                            ? Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            : null,
                        ),
                        const SizedBox(width: 16),
                        
                        // Name and Location
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: GoogleFonts.nunito(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Message Button
                        GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                currentUserEmail: widget.currentUserEmail,
                                targetUserEmail: user['email']?.toString() ?? '',
                                targetUserName: fullName,
                                targetUserAvatar: avatarPath,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Simple dots indicator mimic
                    Row(
                      children: List.generate(5, (index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0 ? Colors.white : Colors.white.withOpacity(0.3),
                          ),
                        );
                      }),
                    )
                  ],
                ),
              ),
              
              // Bug/Report Icon (Top right)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        
        // Asynchronously check for match and show celebration
        DatabaseService.instance.checkMutualMatch(widget.currentUserEmail, targetUserEmail).then((isMutual) {
          if (isMutual && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchScreen(
                  currentUserEmail: widget.currentUserEmail,
                  targetUserEmail: targetUserEmail,
                  targetUserName: targetUserName,
                  targetUserAvatar: targetUserAvatar,
                  currentUserAvatar: myAvatar,
                ),
              ),
            );
          } else if (mounted) {
            // Unmatched like
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liked!'),
                duration: Duration(milliseconds: 1000),
                backgroundColor: Color(0xFFC76CD9),
              ),
            );
          }
        });
        
      } else if (direction == CardSwiperDirection.left) {
        DatabaseService.instance.recordInteraction(widget.currentUserEmail, targetUserEmail, false);
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
