import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'snake_game_screen.dart';
import 'ping_pong_game_screen.dart';

class GamesScreen extends StatefulWidget {
  final String currentUserEmail;

  const GamesScreen({super.key, required this.currentUserEmail});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _snakeHighScore = 0;
  int _pongHighScore = 0;
  List<Map<String, dynamic>> _snakeLeaderboard = [];
  List<Map<String, dynamic>> _pongLeaderboard = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DatabaseService.instance.getUserStats(widget.currentUserEmail);
      final sLeaderboard = await DatabaseService.instance.getSnakeLeaderboard();
      final pLeaderboard = await DatabaseService.instance.getPongLeaderboard();
      
      if (mounted) {
        setState(() {
          _snakeHighScore = stats['snake_score'] ?? 0;
          _pongHighScore = stats['pong_score'] ?? 0;
          _snakeLeaderboard = sLeaderboard;
          _pongLeaderboard = pLeaderboard;
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5),
      appBar: AppBar(
        title: Text(
          'Game Center',
          style: GoogleFonts.nunito(
            color: const Color(0xFF322369),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF322369)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86)))
          : SafeArea(
              child: Column(
                children: [
                  // Game Selection Grid
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a Game',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF322369),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildGameTile(
                              'Snake', 
                              Icons.gesture, 
                              const Color(0xFF4CAF50),
                              () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => SnakeGameScreen(currentUserEmail: widget.currentUserEmail)));
                                _loadData();
                              },
                            ),
                            const SizedBox(width: 24),
                            _buildGameTile(
                              'Ping Pong', 
                              Icons.sports_tennis, 
                              const Color(0xFFF14C86),
                              () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => PingPongGameScreen(currentUserEmail: widget.currentUserEmail)));
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Leaderboards Section
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFFF14C86),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFFF14C86),
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: 'Snake Rankings'),
                              Tab(text: 'Pong Rankings'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLeaderboardList(_snakeLeaderboard, 'snake_high_score'),
                                _buildLeaderboardList(_pongLeaderboard, 'pingpong_high_score'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGameTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF322369),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> leaderboard, String scoreKey) {
    if (leaderboard.isEmpty) {
      return Center(child: Text('No scores yet!', style: GoogleFonts.nunito(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final user = leaderboard[index];
        final score = user[scoreKey] ?? 0;
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
            color: const Color(0xFFFDE8F5).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text('#${index + 1}', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: rankColor, fontSize: 18)),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundImage: _resolveAvatar(photo ?? ''),
                child: _resolveAvatar(photo ?? '') == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(name, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: const Color(0xFF322369)))),
              Text('$score', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: const Color(0xFFF14C86), fontSize: 18)),
            ],
          ),
        );
      },
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
