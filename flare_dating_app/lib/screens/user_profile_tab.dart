import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database_service.dart';
import 'welcome_screen.dart';
import 'user_guide_screen.dart';
import 'achievements_screen.dart';
import 'games_screen.dart';

class UserProfileTab extends StatefulWidget {
  final String currentUserEmail;
  
  const UserProfileTab({
    super.key,
    required this.currentUserEmail,
  });

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  Map<String, dynamic>? _userProfile;
  Map<String, int> _userStats = {'likes_sent': 0, 'passes_sent': 0, 'messages_sent': 0, 'snake_score': 0, 'pong_score': 0};
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await DatabaseService.instance.getUserProfile(widget.currentUserEmail);
      final stats = await DatabaseService.instance.getUserStats(widget.currentUserEmail);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final publicUrl = await DatabaseService.instance.uploadProfilePicture(
          widget.currentUserEmail, 
          bytes: bytes,
        );
        
        if (publicUrl != null) {
          _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _editName() {
    final firstController = TextEditingController(text: _userProfile?['first_name'] ?? '');
    final lastController = TextEditingController(text: _userProfile?['last_name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Name', style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF14C86)),
            onPressed: () async {
              await DatabaseService.instance.updateUserProfile(widget.currentUserEmail, {
                'first_name': firstController.text,
                'last_name': lastController.text,
              });
              if (mounted) {
                Navigator.pop(context);
                _loadProfile();
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Account?',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF322369),
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete your account? This cannot be undone.',
            style: GoogleFonts.nunito(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF14C86),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context); 
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86))),
                );
                try {
                  await DatabaseService.instance.deleteUser(widget.currentUserEmail);
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                }
              },
              child: Text('Delete', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86))),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUserEmail');
      if (mounted) {
        Navigator.pop(context); // close dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF14C86))),
      );
    }

    final firstName = _userProfile?['first_name']?.toString() ?? 'User';
    final lastName = _userProfile?['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final avatarPath = _userProfile?['avatar_path']?.toString() ?? '';
    final avatarImage = _getAvatarImage(avatarPath);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cinematic Header
            Container(
              height: 400,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Builder(builder: (context) {
                      return avatarImage != null
                          ? Image(image: avatarImage, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1A1635), Color(0xFF0D0B1F)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Icon(Icons.person_rounded, size: 120, color: Colors.white.withOpacity(0.05)),
                            );
                    }),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: GoogleFonts.outfit(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                widget.currentUserEmail,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF14C86),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF14C86).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bento Grid Stats
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBentoStat('Likes', _userStats['likes_sent'].toString(), const Color(0xFFF14C86))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBentoStat('Passes', _userStats['passes_sent'].toString(), const Color(0xFF8B51E5))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBentoStat(
                    'Game Achievements', 
                    '${(_userStats['snake_score']! + _userStats['pong_score']!)} Points', 
                    const Color(0xFFC76CD9),
                    isWide: true,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Modern Settings List
                  _buildSectionTitle('Account Settings'),
                  const SizedBox(height: 16),
                  _buildModernSetting(Icons.person_outline_rounded, 'Edit Profile', _editName),
                  _buildModernSetting(Icons.sports_esports_outlined, 'Game Center', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GamesScreen(currentUserEmail: widget.currentUserEmail)));
                  }),
                  _buildModernSetting(Icons.help_outline_rounded, 'User Guide', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGuideScreen()));
                  }),
                  _buildModernSetting(Icons.logout_rounded, 'Log Out', _logout, isDestructive: true),
                  _buildModernSetting(Icons.delete_outline_rounded, 'Delete Account', _confirmDelete, isDestructive: true),
                  
                  const SizedBox(height: 100), // Navigation padding
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildBentoStat(String label, String value, Color color, {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildModernSetting(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.redAccent : const Color(0xFF8B51E5), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.redAccent.withOpacity(0.8) : Colors.white.withOpacity(0.9),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
