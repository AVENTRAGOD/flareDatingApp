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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
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
        backgroundColor: Color(0xFFFDE8F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF14C86))),
      );
    }

    final firstName = _userProfile?['first_name']?.toString() ?? 'User';
    final lastName = _userProfile?['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final avatarPath = _userProfile?['avatar_path']?.toString() ?? '';
    
    ImageProvider? avatarImage;
    if (avatarPath.startsWith('data:image')) {
      try {
        final base64Str = avatarPath.split(',').last;
        final bytes = base64Decode(base64Str);
        avatarImage = MemoryImage(bytes);
      } catch (_) {}
    } else if (avatarPath.isNotEmpty) {
      avatarImage = NetworkImage(avatarPath);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6EEF6),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF14C86), Color(0xFFC76CD9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black87, width: 2),
                                image: avatarImage != null
                                    ? DecorationImage(
                                        image: avatarImage,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: const Color(0xFF322369),
                              ),
                              child: avatarImage == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                            ),
                            if (_isUploading)
                              const Positioned.fill(
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF322369)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          fullName.isNotEmpty ? fullName : 'User',
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Likes', _userStats['likes_sent'].toString()),
                    _buildStatDivider(),
                    _buildStatItem('Passes', _userStats['passes_sent'].toString()),
                    _buildStatDivider(),
                    _buildStatItem('Games', (_userStats['snake_score']! + _userStats['pong_score']!).toString()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _editName,
                    child: _buildDetailedInfoRow(
                      icon: Icons.person_outline,
                      title: 'User Name',
                      value: fullName.isNotEmpty ? fullName : 'User',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailedInfoRow(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: widget.currentUserEmail,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showComingSoon('Password Reset'),
                    child: _buildDetailedInfoRow(
                      icon: Icons.lock_outline,
                      title: 'Password',
                      value: 'Reset Password',
                      valueColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF322369),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your settings for best app use',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5E5088),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSettingOption(Icons.lock_person_outlined, 'Privacy Options', onTap: () => _showComingSoon('Privacy Options')),
                  _buildSettingOption(Icons.notifications_outlined, 'Safety', onTap: () => _showComingSoon('Safety Center')),
                  _buildSettingOption(Icons.help_outline, 'Help Center', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGuideScreen()));
                  }),
                  _buildSettingOption(Icons.article_outlined, 'Terms & Conditions', onTap: () => _showComingSoon('Terms & Conditions')),
                  _buildSettingOption(Icons.workspace_premium_outlined, 'Achievements', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AchievementsScreen(currentUserEmail: widget.currentUserEmail)));
                  }),
                  _buildSettingOption(Icons.sports_esports_outlined, 'Games', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GamesScreen(currentUserEmail: widget.currentUserEmail)));
                  }),
                  _buildSettingOption(Icons.logout_outlined, 'Log Out', onTap: _logout),
                  _buildSettingOption(Icons.delete_outline, 'Delete Account', onTap: _confirmDelete),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInfoRow({required IconData icon, required String title, required String value, Color? valueColor}) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFCF65D9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.black, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[600],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSettingOption(IconData icon, String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF322369), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFC76CD9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF322369),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }
}
