import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.restaurant,
                  size: 80,
                  color: const Color(0xFF006e1c),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leresto',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF006e1c),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF006e1c),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Color(0xFF6f7a6b),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
