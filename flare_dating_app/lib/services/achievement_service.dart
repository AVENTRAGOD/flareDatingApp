import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AchievementService {
  static final AchievementService instance = AchievementService._init();
  AchievementService._init();

  final List<Map<String, dynamic>> achievementDefinitions = [
    // Likes / Swiping Right
    {'id': 'first_like', 'icon': Icons.favorite_border, 'title': 'First Blood', 'desc': 'Send your first like.', 'stat': 'likes_sent', 'target': 1},
    {'id': 'playboy', 'icon': Icons.local_fire_department, 'title': 'The Playboy', 'desc': 'Like 10 different profiles.', 'stat': 'likes_sent', 'target': 10},
    {'id': 'heartbreaker', 'icon': Icons.whatshot, 'title': 'Heartbreaker', 'desc': 'Like 50 different profiles.', 'stat': 'likes_sent', 'target': 50},
    {'id': 'cupid', 'icon': Icons.favorite, 'title': 'Cupid\'s Arrow', 'desc': 'Like 100 different profiles.', 'stat': 'likes_sent', 'target': 100},
    
    // Passes / Swiping Left
    {'id': 'first_pass', 'icon': Icons.not_interested, 'title': 'The Ghost', 'desc': 'Pass on a profile for the first time.', 'stat': 'passes_sent', 'target': 1},
    {'id': 'picky_eater', 'icon': Icons.restaurant_menu, 'title': 'Picky Eater', 'desc': 'Pass on 10 profiles.', 'stat': 'passes_sent', 'target': 10},
    {'id': 'tough_crowd', 'icon': Icons.block, 'title': 'Tough Crowd', 'desc': 'Pass on 50 profiles.', 'stat': 'passes_sent', 'target': 50},
    {'id': 'simon_cowell', 'icon': Icons.do_not_disturb_alt, 'title': 'Simon Cowell', 'desc': 'Pass on 100 profiles.', 'stat': 'passes_sent', 'target': 100},
    
    // Messaging
    {'id': 'first_msg', 'icon': Icons.chat_bubble_outline, 'title': 'Ice Breaker', 'desc': 'Send your first message.', 'stat': 'messages_sent', 'target': 1},
    {'id': 'chatterbox', 'icon': Icons.chat, 'title': 'Chatterbox', 'desc': 'Send 10 messages.', 'stat': 'messages_sent', 'target': 10},
    {'id': 'silver_tongue', 'icon': Icons.speaker_notes, 'title': 'Silver Tongue', 'desc': 'Send 50 messages.', 'stat': 'messages_sent', 'target': 50},
    {'id': 'shakespeare', 'icon': Icons.history_edu, 'title': 'Shakespeare', 'desc': 'Send 100 messages.', 'stat': 'messages_sent', 'target': 100},
    
    // Snake Minigame
    {'id': 'snake_bite', 'icon': Icons.apple, 'title': 'First Bite', 'desc': 'You swallowed the first apple!', 'stat': 'snake_score', 'target': 1},
    {'id': 'snake_growing', 'icon': Icons.trending_up, 'title': 'Growing Pains', 'desc': 'Score 10. Getting longer...', 'stat': 'snake_score', 'target': 10},
    {'id': 'anaconda', 'icon': Icons.bug_report, 'title': 'Anaconda', 'desc': 'Score 50. You are a beast!', 'stat': 'snake_score', 'target': 50},
  ];

  Future<void> checkAndNotify(String email, BuildContext context) async {
    try {
      final stats = await DatabaseService.instance.getUserStats(email);
      final prefs = await SharedPreferences.getInstance();
      
      for (var achievement in achievementDefinitions) {
        final id = achievement['id'] as String;
        final statKey = achievement['stat'] as String;
        final target = achievement['target'] as int;
        final currentVal = stats[statKey] ?? 0;

        if (currentVal >= target) {
          final prefKey = 'achievement_notified_$id';
          final alreadyNotified = prefs.getBool(prefKey) ?? false;

          if (!alreadyNotified) {
            // Unlocked for the first time!
            _showNotification(context, achievement);
            await prefs.setBool(prefKey, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  void _showNotification(BuildContext context, Map<String, dynamic> achievement) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _AchievementNotificationWidget(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _AchievementNotificationWidget extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final VoidCallback onDismiss;

  const _AchievementNotificationWidget({
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<_AchievementNotificationWidget> createState() => _AchievementNotificationWidgetState();
}

class _AchievementNotificationWidgetState extends State<_AchievementNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF14C86), Color(0xFFC76CD9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.achievement['icon'] as IconData,
                        color: const Color(0xFFF14C86),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievement Unlocked!',
                            style: GoogleFonts.nunito(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            widget.achievement['title'] as String,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () {
                        _controller.reverse().then((_) => widget.onDismiss());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
