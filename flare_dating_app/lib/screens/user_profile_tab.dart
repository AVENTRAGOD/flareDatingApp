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

  const UserProfileTab({super.key, required this.currentUserEmail});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  Map<String, dynamic>? _userProfile;
  Map<String, int> _userStats = {
    'likes_sent': 0,
    'passes_sent': 0,
    'messages_sent': 0,
    'snake_score': 0,
    'pong_score': 0,
  };
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
            TextField(controller: firstController, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 16),
            TextField(controller: lastController, decoration: const InputDecoration(labelText: 'Last Name')),
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
          title: Text('Delete Account?', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: const Color(0xFFF14C86))),
          content: Text('Are you sure you want to permanently delete your account?', style: GoogleFonts.nunito()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.nunito(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF14C86)),
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseService.instance.deleteUser(widget.currentUserEmail);
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text('Delete', style: GoogleFonts.nunito(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserEmail');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFF14C86))));
    }

    final firstName = _userProfile?['first_name']?.toString() ?? 'User';
    final lastName = _userProfile?['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final avatarPath = _userProfile?['avatar_path']?.toString() ?? '';
    final avatarImage = _getAvatarImage(avatarPath);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                image: avatarImage != null ? DecorationImage(image: avatarImage, fit: BoxFit.cover) : null,
                              ),
                              child: avatarImage == null ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
                            ),
                            if (_isUploading)
                              const Positioned.fill(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFFF14C86)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          fullName,
                          style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Account Details
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMinimalSection('User Details', [
                    _buildMinimalTile(Icons.person_rounded, 'User Name', fullName, onTap: _editName),
                    _buildMinimalTile(Icons.email_rounded, 'Email', widget.currentUserEmail),
                    _buildMinimalTile(Icons.lock_rounded, 'Password', 'Reset Password', onTap: () => _showComingSoon('Password Reset')),
                  ]),
                  const SizedBox(height: 32),
                  _buildMinimalSection('Settings', [
                    _buildMinimalTile(Icons.privacy_tip_rounded, 'Privacy Options', 'Manage your privacy', onTap: () => _showComingSoon('Privacy')),
                    _buildMinimalTile(Icons.security_rounded, 'Safety', 'Safety guidelines', onTap: () => _showComingSoon('Safety')),
                    _buildMinimalTile(Icons.help_rounded, 'Help Center', 'Get help and support', onTap: () => _showComingSoon('Help Center')),
                    _buildMinimalTile(Icons.sports_esports_rounded, 'Game Center', 'Play games and compete', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GamesScreen(currentUserEmail: widget.currentUserEmail)));
                    }),
                    _buildMinimalTile(Icons.military_tech_rounded, 'Achievements', 'View your progress', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AchievementsScreen(currentUserEmail: widget.currentUserEmail)));
                    }),
                    _buildMinimalTile(Icons.info_rounded, 'User Guide', 'How to use Flare', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGuideScreen()));
                    }),
                  ]),
                  const SizedBox(height: 32),
                  _buildMinimalSection('Account Actions', [
                    _buildMinimalTile(Icons.logout_rounded, 'Log Out', 'Sign out of your account', onTap: _logout, isDestructive: true),
                    _buildMinimalTile(Icons.delete_forever_rounded, 'Delete Account', 'Permanently delete account', onTap: _confirmDelete, isDestructive: true),
                  ]),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF333333))),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildMinimalTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDestructive ? Colors.red[50] : const Color(0xFFF14C86).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFFF14C86), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: isDestructive ? Colors.red : const Color(0xFF333333))),
                  Text(subtitle, style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title is coming soon!'), behavior: SnackBarBehavior.floating));
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
}
