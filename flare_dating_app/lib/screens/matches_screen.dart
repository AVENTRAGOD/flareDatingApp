import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'chat_room_screen.dart';
import 'be_patient_screen.dart';

class MatchesScreen extends StatefulWidget {
  final String currentUserEmail;

  const MatchesScreen({super.key, required this.currentUserEmail});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _likedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      final likes = await DatabaseService.instance.getLikedUsers(widget.currentUserEmail);
      setState(() {
        _likedUsers = likes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching matches: $e');
      setState(() => _isLoading = false);
    }
  }

  void _removeMatch(String targetEmail) async {
    // Optimistic UI update
    setState(() {
      _likedUsers.removeWhere((user) => user['email'] == targetEmail);
    });
    await DatabaseService.instance.removeInteraction(widget.currentUserEmail, targetEmail);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match removed.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5), // Light pink background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Text(
                    'Matches',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // "Today" Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Today',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _likedUsers.isEmpty
                      ? Center(
                          child: Text(
                            'No matches yet. Go swipe right!',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65, // Taller cards
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _likedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _likedUsers[index];
                            return _buildMatchCard(user);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final avatarPath = user['avatar_path']?.toString() ?? '';
    
    // Calculate Age
    String age = '';
    final dobString = user['dob']?.toString() ?? '';
    if (dobString.isNotEmpty) {
      try {
        DateTime dob = DateTime.parse(dobString);
        int calcAge = DateTime.now().year - dob.year;
        age = ', $calcAge';
      } catch (e) {
        // ignore
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image (base64 or network)
            Builder(builder: (context) {
              final img = _resolveAvatar(avatarPath);
              if (img != null) {
                return Image(image: img, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackImage());
              }
              return _fallbackImage();
            }),
              
            // Bottom Gradient 
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name & Age
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '$firstName$age',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Action Buttons Bar (Dark Glassmorphism effect)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Row(
                    children: [
                      // Remove Match (Cross)
                      Expanded(
                        child: InkWell(
                          onTap: () => _removeMatch(email),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      // Divider
                      Container(
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      
                      // Chat / Accept (Heart)
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            // Quick loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(color: Color(0xFFF14C86)),
                              ),
                            );
                            
                            // Verify mutual interaction
                            final isMutual = await DatabaseService.instance.checkMutualMatch(
                              widget.currentUserEmail,
                              email,
                            );
                            
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading dialog
                              if (isMutual) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      currentUserEmail: widget.currentUserEmail,
                                      targetUserEmail: email,
                                      targetUserName: firstName,
                                      targetUserAvatar: avatarPath,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BePatientScreen(
                                      targetUserAvatar: avatarPath,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.grey[500],
          size: 60,
        ),
      ),
    );
  }

  ImageProvider? _resolveAvatar(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('data:image')) {
      try { return MemoryImage(base64Decode(path.split(',').last)); } catch (_) { return null; }
    }
    return NetworkImage(path);
  }
}
