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
                    // Personal Score Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF14C86), Color(0xFFC76CD9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF14C86).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'YOUR HIGH SCORE',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_personalHighScore',
                            style: GoogleFonts.nunito(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF322369),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 8,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SnakeGameScreen(
                                currentUserEmail: widget.currentUserEmail,
                              ),
                            ),
                          );
                          _loadData();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              'PLAY CLASSIC SNAKE',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Leaderboard Section
                    Row(
                      children: [
                        const Icon(Icons.leaderboard_rounded, color: Color(0xFF322369), size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Global Rankings',
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF322369),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index];
                          final score = user['snake_high_score'] ?? 0;
                          final name = user['first_name'] ?? 'Anonymous';
                          final photo = user['avatar_path'] as String?;
                          
                          bool isTopThree = index < 3;
                          Color rankColor = isTopThree 
                            ? (index == 0 ? const Color(0xFFFFD700) : (index == 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32)))
                            : Colors.grey[400]!;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: isTopThree ? Border.all(color: rankColor.withOpacity(0.5), width: 2) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w900,
                                      color: rankColor,
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: _resolveAvatar(photo ?? ''),
                                  backgroundColor: const Color(0xFFFDE8F5),
                                  child: _resolveAvatar(photo ?? '') == null
                                    ? const Icon(Icons.person, color: Color(0xFFF14C86), size: 20) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF322369),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isTopThree ? rankColor.withOpacity(0.1) : const Color(0xFFFDE8F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$score',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w900,
                                      color: isTopThree ? rankColor : const Color(0xFFF14C86),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
