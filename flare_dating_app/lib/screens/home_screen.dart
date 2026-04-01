import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flare Home'),
      ),
      body: const Center(
        child: Text('Home Screen - Waiting for next design!'),
      ),
    );
  }
}
