import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_service.dart';
import 'chat_room_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String currentUserEmail;

  const NotificationsScreen({
    super.key,
    required this.currentUserEmail,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _likedMeProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final likerEmails = await DatabaseService.instance.getUsersWhoLikedMe(widget.currentUserEmail);
      final allUsers = await DatabaseService.instance.getAllUsers();
      
      setState(() {
        _likedMeProfiles = allUsers.where((user) {
          final userEmail = user['email']?.toString() ?? '';
          return likerEmails.contains(userEmail);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5), // Light pinkish background
      appBar: AppBar(
        title: Text(
          'Notifications',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86)))
            : _likedMeProfiles.isEmpty
                ? Center(
                    child: Text(
                      'No new notifications yet.',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: const Color(0xFF5E5088),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _likedMeProfiles.length,
                    itemBuilder: (context, index) {
                      final user = _likedMeProfiles[index];
                      final first = user['first_name']?.toString() ?? 'Unknown';
                      final last = user['last_name']?.toString() ?? '';
                      final fullName = '$first $last';
                      final avatarPath = user['avatar_path']?.toString() ?? '';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF322369),
                                backgroundImage: _resolveAvatar(avatarPath),
                                child: _resolveAvatar(avatarPath) == null ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Color(0xFFF14C86),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            '$first liked you!',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF322369),
                            ),
                          ),
                          subtitle: Text(
                            'Say hi and start matching!',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomScreen(
                                  currentUserEmail: widget.currentUserEmail,
                                  targetUserEmail: user['email'] ?? '',
                                  targetUserName: fullName,
                                  targetUserAvatar: avatarPath,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
