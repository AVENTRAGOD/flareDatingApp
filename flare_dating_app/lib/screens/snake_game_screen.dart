import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_service.dart';

class SnakeGameScreen extends StatefulWidget {
  final String currentUserEmail;

  const SnakeGameScreen({super.key, required this.currentUserEmail});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  // Grid settings
  static const int squaresPerRow = 20;
  static const int totalSquares = 400;

  // Snake and Food state
  List<int> snakePosition = [45, 65, 85, 105]; // Head is at the end of the list
  int foodPosition = 55;
  String direction = 'down';
  bool hasStarted = false;
  bool isGameOver = false;
  int score = 0;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _spawnFood();
  }

  void _spawnFood() {
    Random random = Random();
    int newFood;
    do {
      newFood = random.nextInt(totalSquares);
    } while (snakePosition.contains(newFood));
    foodPosition = newFood;
  }

  void startGame() {
    hasStarted = true;
    isGameOver = false;
    timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      _updateSnake();
    });
  }

  void _updateSnake() {
    if (!mounted) return;
    setState(() {
      int head = snakePosition.last;
      int nextSquare;

      switch (direction) {
        case 'up':
          nextSquare = head - squaresPerRow;
          break;
        case 'down':
          nextSquare = head + squaresPerRow;
          break;
        case 'left':
          nextSquare = head - 1;
          // Wrapping logic or hit wall logic
          break;
        case 'right':
          nextSquare = head + 1;
          break;
        default:
          nextSquare = head;
      }

      // Check collisions
      if (_checkCollision(head, nextSquare)) {
        _gameOver();
        return;
      }

      snakePosition.add(nextSquare);

      // Check if food eaten
      if (nextSquare == foodPosition) {
        score++;
        _spawnFood();
      } else {
        snakePosition.removeAt(0); // Remove tail
      }
    });
  }

  bool _checkCollision(int head, int nextSquare) {
    // 1. Hit itself
    if (snakePosition.contains(nextSquare)) return true;

    // 2. Hit Walls
    if (direction == 'up' && nextSquare < 0) return true;
    if (direction == 'down' && nextSquare >= totalSquares) return true;
    
    // For left/right, check if we crossed rows
    if (direction == 'left' && head % squaresPerRow == 0) return true;
    if (direction == 'right' && head % squaresPerRow == squaresPerRow - 1) return true;

    return false;
  }

  void _gameOver() {
    timer?.cancel();
    setState(() {
      isGameOver = true;
    });

    // Update database seamlessly
    if (score > 0) {
      DatabaseService.instance.updateSnakeHighScore(widget.currentUserEmail, score);
    }

    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Game Over',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF322369),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'You scored $score ${score == 1 ? "apple" : "apples"}!',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF14C86),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen, return to Games main page
            },
            child: Text(
              'Back',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              _resetGame();
            },
            child: Text(
              'Play Again',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      snakePosition = [45, 65, 85, 105];
      direction = 'down';
      score = 0;
      hasStarted = false;
      isGameOver = false;
      _spawnFood();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _handleSwipe(DragUpdateDetails details) {
    // Determine swipe direction
    double dx = details.delta.dx;
    double dy = details.delta.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > 0 && direction != 'left') {
        direction = 'right';
      } else if (dx < 0 && direction != 'right') {
        direction = 'left';
      }
    } else {
      // Vertical swipe
      if (dy > 0 && direction != 'up') {
        direction = 'down';
      } else if (dy < 0 && direction != 'down') {
        direction = 'up';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C), // Dark background for the game table
      appBar: AppBar(
        title: Text(
          'Score: $score',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onPanUpdate: _handleSwipe,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[800]!, width: 4),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black, // Grid background
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalSquares,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: squaresPerRow,
                      ),
                      itemBuilder: (context, index) {
                        if (snakePosition.contains(index)) {
                          final isHead = snakePosition.last == index;
                          return Container(
                            decoration: BoxDecoration(
                              color: isHead ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50), // Snake body
                              // Blocky style with sharp borders
                              border: Border.all(color: Colors.black.withOpacity(0.5), width: 1.5),
                            ),
                          );
                        } else if (foodPosition == index) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF14C86), // Flare pink apple
                              // Blocky apple too
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(Icons.favorite, size: 10, color: Colors.white),
                          );
                        } else {
                          // Grid background dots for a retro feel
                          return Center(
                            child: Container(
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Start CTA / Instructions
            if (!hasStarted && !isGameOver)
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  children: [
                    Text(
                      'Swipe to move',
                      style: GoogleFonts.nunito(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: startGame,
                        child: Text(
                          'START',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (hasStarted)
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Swipe anywhere to steer',
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
