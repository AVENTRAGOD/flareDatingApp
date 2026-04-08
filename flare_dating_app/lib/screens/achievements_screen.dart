import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

class AchievementsScreen extends StatefulWidget {
  final String currentUserEmail;
  
  const AchievementsScreen({
    super.key,
    required this.currentUserEmail,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isLoading = true;
  int _likesSent = 0;
  int _passesSent = 0;
  int _messagesSent = 0;
  int _snakeScore = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService.instance.getUserStats(widget.currentUserEmail);
      if (mounted) {
        setState(() {
          _likesSent = stats['likes_sent'] ?? 0;
          _passesSent = stats['passes_sent'] ?? 0;
          _messagesSent = stats['messages_sent'] ?? 0;
          _snakeScore = stats['snake_score'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDE8F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF14C86))),
      );
    }

    final totalSwipes = _likesSent + _passesSent;
    final totalInteractions = totalSwipes + _messagesSent;

    // Define the 20 Achievements!
    final List<Map<String, dynamic>> achievements = [
      // Likes / Swiping Right
      {'icon': Icons.favorite_border, 'title': 'First Blood', 'desc': 'Send your first like.', 'current': _likesSent, 'target': 1, 'isHidden': false},
      {'icon': Icons.local_fire_department, 'title': 'The Playboy', 'desc': 'Like 10 different profiles.', 'current': _likesSent, 'target': 10, 'isHidden': true},
      {'icon': Icons.whatshot, 'title': 'Heartbreaker', 'desc': 'Like 50 different profiles.', 'current': _likesSent, 'target': 50, 'isHidden': true},
      {'icon': Icons.favorite, 'title': 'Cupid\'s Arrow', 'desc': 'Like 100 different profiles.', 'current': _likesSent, 'target': 100, 'isHidden': true},
      
      // Passes / Swiping Left
      {'icon': Icons.not_interested, 'title': 'The Ghost', 'desc': 'Pass on a profile for the first time.', 'current': _passesSent, 'target': 1, 'isHidden': false},
      {'icon': Icons.restaurant_menu, 'title': 'Picky Eater', 'desc': 'Pass on 10 profiles.', 'current': _passesSent, 'target': 10, 'isHidden': true},
      {'icon': Icons.block, 'title': 'Tough Crowd', 'desc': 'Pass on 50 profiles.', 'current': _passesSent, 'target': 50, 'isHidden': false},
      {'icon': Icons.do_not_disturb_alt, 'title': 'Simon Cowell', 'desc': 'Pass on 100 profiles.', 'current': _passesSent, 'target': 100, 'isHidden': true},
      
      // Messaging
      {'icon': Icons.chat_bubble_outline, 'title': 'Ice Breaker', 'desc': 'Send your first message.', 'current': _messagesSent, 'target': 1, 'isHidden': false},
      {'icon': Icons.chat, 'title': 'Chatterbox', 'desc': 'Send 10 messages.', 'current': _messagesSent, 'target': 10, 'isHidden': false},
      {'icon': Icons.speaker_notes, 'title': 'Silver Tongue', 'desc': 'Send 50 messages.', 'current': _messagesSent, 'target': 50, 'isHidden': true},
      {'icon': Icons.history_edu, 'title': 'Shakespeare', 'desc': 'Send 100 messages.', 'current': _messagesSent, 'target': 100, 'isHidden': true},
      
      // Total Swipes
      {'icon': Icons.explore, 'title': 'Explorer', 'desc': 'Swipe a total of 10 times.', 'current': totalSwipes, 'target': 10, 'isHidden': false},
      {'icon': Icons.storefront, 'title': 'Window Shopper', 'desc': 'Swipe a total of 100 times.', 'current': totalSwipes, 'target': 100, 'isHidden': false},
      {'icon': Icons.smartphone, 'title': 'Addicted', 'desc': 'Swipe a total of 500 times.', 'current': totalSwipes, 'target': 500, 'isHidden': true},
      
      // Total Overall Interactions
      {'icon': Icons.verified_user, 'title': 'Verified Human', 'desc': 'Complete your first interaction on the app.', 'current': totalInteractions, 'target': 1, 'isHidden': false},
      {'icon': Icons.stars, 'title': 'Beginner\'s Luck', 'desc': 'Reach 5 total app interactions.', 'current': totalInteractions, 'target': 5, 'isHidden': false},
      {'icon': Icons.emoji_people, 'title': 'Social Butterfly', 'desc': 'Reach 20 total app interactions.', 'current': totalInteractions, 'target': 20, 'isHidden': false},
      {'icon': Icons.location_city, 'title': 'Mayor of Flare', 'desc': 'Reach 50 total app interactions.', 'current': totalInteractions, 'target': 50, 'isHidden': true},
      {'icon': Icons.military_tech, 'title': 'Flare Legend', 'desc': 'Reach 100 total app interactions.', 'current': totalInteractions, 'target': 100, 'isHidden': true},
      
      // Snake Minigame
      {'icon': Icons.apple, 'title': 'First Bite', 'desc': 'You swallowed the first apple. Don\'t choke now!', 'current': _snakeScore, 'target': 1, 'isHidden': false},
      {'icon': Icons.trending_up, 'title': 'Growing Pains', 'desc': 'Score 10. Getting longer... watch your tail!', 'current': _snakeScore, 'target': 10, 'isHidden': false},
      {'icon': Icons.bug_report, 'title': 'Anaconda', 'desc': 'Score 50. You are a terrifying beast of the grid.', 'current': _snakeScore, 'target': 50, 'isHidden': true},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5),
      appBar: AppBar(
        title: Text(
          'Achievements',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock custom achievements by sweeping, swiping, and socializing! Progress bars update automatically.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF5E5088),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Map over the massive 20 achievement list
              ...achievements.map((item) {
                final int current = item['current'] as int;
                final int target = item['target'] as int;
                final double rawProgress = current / target;
                final double progress = rawProgress > 1.0 ? 1.0 : rawProgress;
                final bool isUnlocked = current >= target;
                final bool isHidden = item['isHidden'] == true && !isUnlocked;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildAchievementCard(
                    icon: isHidden ? Icons.lock : item['icon'] as IconData,
                    title: isHidden ? 'Secret Achievement' : item['title'] as String,
                    description: isHidden ? 'Keep using Flare to discover what this is!' : item['desc'] as String,
                    progress: progress,
                    isUnlocked: isUnlocked,
                    currentVal: current,
                    targetVal: target,
                    isHidden: isHidden,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required String title,
    required String description,
    required double progress,
    required bool isUnlocked,
    required int currentVal,
    required int targetVal,
    required bool isHidden,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked ? Border.all(color: const Color(0xFFC76CD9), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? const Color(0xFFFDE8F5) : Colors.grey[200],
            ),
            child: Icon(
              icon,
              color: isUnlocked ? const Color(0xFFF14C86) : Colors.grey[500],
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? const Color(0xFF322369) : Colors.grey[600],
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(Icons.check_circle, color: Color(0xFFC76CD9), size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                if (!isUnlocked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC76CD9)),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentVal / $targetVal',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Unlocked!',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF14C86),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
