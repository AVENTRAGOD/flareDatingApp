import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'snake_game_screen.dart';

class GamesScreen extends StatefulWidget {
  final String currentUserEmail;

  const GamesScreen({super.key, required this.currentUserEmail});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool _isLoading = true;
  int _personalHighScore = 0;
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DatabaseService.instance.getUserStats(widget.currentUserEmail);
      final leaderboard = await DatabaseService.instance.getSnakeLeaderboard();
      
      if (mounted) {
        setState(() {
          _personalHighScore = stats['snake_score'] ?? 0;
          _leaderboard = leaderboard;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading game data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5), // Light pink bg
      appBar: AppBar(
        title: Text(
          'Snake Game',
          style: GoogleFonts.nunito(
            color: const Color(0xFF322369),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5E5088)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hero Icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1), // Green hue for snake
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gesture,
                        size: 80,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Classic Snake',
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF322369),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Personal High Score: $_personalHighScore',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF14C86),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          // Navigate to Game and wait for return
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SnakeGameScreen(
                                currentUserEmail: widget.currentUserEmail,
                              ),
                            ),
                          );
                          // Refresh data when returning (in case score changed)
                          _loadData();
                        },
                        child: Text(
                          'PLAY NOW',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Leaderboard Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Global Leaderboard',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF322369),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_leaderboard.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No scores yet. Be the first!',
                            style: GoogleFonts.nunito(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leaderboard.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
                          itemBuilder: (context, index) {
                            final user = _leaderboard[index];
                            final score = user['snake_high_score'] ?? 0;
                            final name = user['first_name'] ?? 'Anonymous';
                            final photo = user['avatar_path'] as String?;
                            
                            // Top 3 distinct styles
                            Color rankColor = Colors.grey[600]!;
                            if (index == 0) rankColor = const Color(0xFFFFD700); // Gold
                            if (index == 1) rankColor = const Color(0xFFC0C0C0); // Silver
                            if (index == 2) rankColor = const Color(0xFFCD7F32); // Bronze
                            
                            return ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${index + 1}',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.bold,
                                      color: rankColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  CircleAvatar(
                                    backgroundImage: _resolveAvatar(photo ?? ''),
                                    backgroundColor: const Color(0xFFC76CD9),
                                    child: _resolveAvatar(photo ?? '') == null
                                      ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                                  ),
                                ],
                              ),
                              title: Text(
                                name,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF322369),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE8F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$score',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFF14C86),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
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
