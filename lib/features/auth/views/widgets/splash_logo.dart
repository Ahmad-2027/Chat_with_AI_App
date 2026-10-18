import 'package:flutter/material.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 74),
      SizedBox(height: 12),
      Text(
        'aura',
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}
