import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

class PingPongGameScreen extends StatefulWidget {
  final String currentUserEmail;

  const PingPongGameScreen({super.key, required this.currentUserEmail});

  @override
  State<PingPongGameScreen> createState() => _PingPongGameScreenState();
}

class _PingPongGameScreenState extends State<PingPongGameScreen> {
  // Ball position
  double ballX = 0;
  double ballY = 0;
  double ballXDirection = 0.02;
  double ballYDirection = 0.02;

  // Paddle position
  double paddleX = 0;
  double paddleWidth = 0.4; // 40% of screen width

  // Game state
  bool hasStarted = false;
  bool isGameOver = false;
  int score = 0;
  Timer? timer;

  void startGame() {
    hasStarted = true;
    isGameOver = false;
    score = 0;
    ballX = 0;
    ballY = 0;
    ballXDirection = 0.015;
    ballYDirection = 0.015;
    
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateBall();
    });
  }

  void _updateBall() {
    setState(() {
      // Move ball
      ballX += ballXDirection;
      ballY += ballYDirection;

      // Check horizontal wall collisions
      if (ballX >= 0.95) {
        ballX = 0.95;
        ballXDirection = -ballXDirection.abs();
      } else if (ballX <= -0.95) {
        ballX = -0.95;
        ballXDirection = ballXDirection.abs();
      }

      // Check top wall collision
      if (ballY <= -0.95) {
        ballY = -0.95;
        ballYDirection = ballYDirection.abs();
      }

      // Check paddle collision (bottom)
      if (ballY >= 0.9 && ballY <= 0.95 && ballYDirection > 0) {
        if (ballX >= paddleX - (paddleWidth / 2) - 0.05 && ballX <= paddleX + (paddleWidth / 2) + 0.05) {
          ballY = 0.9;
          ballYDirection = -ballYDirection.abs();
          score++;
          // Slightly increase speed as score goes up
          ballXDirection *= 1.05;
          ballYDirection *= 1.05;
        }
      } else if (ballY >= 1.1) {
        _gameOver();
      }
    });
  }

  void _gameOver() {
    timer?.cancel();
    isGameOver = true;
    
    if (score > 0) {
      DatabaseService.instance.updatePongHighScore(widget.currentUserEmail, score);
    }

    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF322369),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Game Over',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Score: $score',
          style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFFF14C86)),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Back', style: GoogleFonts.nunito(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF14C86)),
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
              startGame();
            },
            child: Text('Play Again', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      ballX = 0;
      ballY = 0;
      hasStarted = false;
      isGameOver = false;
      score = 0;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep space blue
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pong Score: $score', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            paddleX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
            if (paddleX < -1 + (paddleWidth / 2)) paddleX = -1 + (paddleWidth / 2);
            if (paddleX > 1 - (paddleWidth / 2)) paddleX = 1 - (paddleWidth / 2);
          });
        },
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // Play Area Border
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFF14C86).withOpacity(0.3), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                  // Ball
                  Container(
                    alignment: Alignment(ballX, ballY),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF14C86),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0xFFF14C86), blurRadius: 10)],
                      ),
                    ),
                  ),

                  // Paddle
                  Container(
                    alignment: Alignment(paddleX, 0.95),
                    child: Container(
                      width: MediaQuery.of(context).size.width * (paddleWidth / 2),
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC76CD9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: const Color(0xFFC76CD9).withOpacity(0.5), blurRadius: 8)],
                      ),
                    ),
                  ),

                  // Start CTA
                  if (!hasStarted)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Drag to move paddle',
                            style: GoogleFonts.nunito(color: Colors.white60, fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 180,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF14C86),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              ),
                              onPressed: startGame,
                              child: Text('START GAME', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
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
}
