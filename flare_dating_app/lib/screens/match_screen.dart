import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_room_screen.dart';

class MatchScreen extends StatefulWidget {
  final String currentUserEmail;
  final String targetUserEmail;
  final String targetUserName;
  final String targetUserAvatar;
  final String currentUserAvatar; 

  const MatchScreen({
    super.key,
    required this.currentUserEmail,
    required this.targetUserEmail,
    required this.targetUserName,
    required this.targetUserAvatar,
    required this.currentUserAvatar,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _slideController;
  late Animation<Offset> _leftAvatarSlide;
  late Animation<Offset> _rightAvatarSlide;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();

    // Fire pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide in animations
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _leftAvatarSlide = Tween<Offset>(begin: const Offset(-1.5, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _rightAvatarSlide = Tween<Offset>(begin: const Offset(1.5, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.2, 0.9, curve: Curves.easeOutBack)),
    );
    
    _avatarScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context), 
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // The Flare "Fire/Heart" Logo with pulsing animation
                   ScaleTransition(
                     scale: _pulseAnimation,
                     child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFF14C86), Color(0xFFF79C65), Color(0xFFC76CD9)], // Pink, Orange, Purple
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite, color: Colors.white, size: 50),
                        ),
                     ),
                   ),
                   
                   const SizedBox(height: 48),
                   
                   // The Two Profile Avatars
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       // Current User
                       SlideTransition(
                         position: _leftAvatarSlide,
                         child: ScaleTransition(
                           scale: _avatarScale,
                           child: _buildAvatarCircle(widget.currentUserAvatar),
                         ),
                       ),
                       
                       const SizedBox(width: 16),
                       
                       // Target User
                       SlideTransition(
                         position: _rightAvatarSlide,
                         child: ScaleTransition(
                           scale: _avatarScale,
                           child: _buildAvatarCircle(widget.targetUserAvatar),
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: 64),
                   
                   // Typography
                   Text(
                     'Congrats!',
                     style: GoogleFonts.nunito(
                       fontSize: 48,
                       fontWeight: FontWeight.w900,
                       color: const Color(0xFF322369), // Dark Purple
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'It\'s a Match!',
                     style: GoogleFonts.nunito(
                       fontSize: 18,
                       fontWeight: FontWeight.w800,
                       color: const Color(0xFF5E5088),
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     '${widget.targetUserName} & You both liked each other',
                     style: GoogleFonts.nunito(
                       fontSize: 16,
                       color: const Color(0xFF5E5088),
                     ),
                   ),
                   
                   const SizedBox(height: 64),
                   
                   // Start Conversation Action
                   GestureDetector(
                     onTap: () {
                       Navigator.pushReplacement(
                         context,
                         MaterialPageRoute(
                           builder: (context) => ChatRoomScreen(
                             currentUserEmail: widget.currentUserEmail,
                             targetUserEmail: widget.targetUserEmail,
                             targetUserName: widget.targetUserName,
                             targetUserAvatar: widget.targetUserAvatar,
                           ),
                         ),
                       );
                     },
                     child: Column(
                       children: [
                         const Icon(
                           Icons.chat_bubble_outline,
                           color: Color(0xFFF14C86), // Flare vibrant pink
                           size: 32,
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Start Conversation',
                           style: GoogleFonts.nunito(
                             fontSize: 18,
                             fontWeight: FontWeight.w900,
                             color: const Color(0xFFF14C86),
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(String path) {
    ImageProvider? imgProvider;
    if (path.isNotEmpty) {
      if (path.startsWith('data:image')) {
        try { imgProvider = MemoryImage(base64Decode(path.split(',').last)); } catch (_) {}
      } else {
        imgProvider = NetworkImage(path);
      }
    }
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF322369), width: 3),
      ),
      child: ClipOval(
        child: imgProvider != null
            ? Image(image: imgProvider, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon())
            : _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.person, color: Colors.grey, size: 60),
      ),
    );
  }
}
