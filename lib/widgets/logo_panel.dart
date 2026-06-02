import 'package:flutter/material.dart';

class LogoPanel extends StatelessWidget {
  final bool isConnected;

  const LogoPanel({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    if (!isConnected) return const SizedBox.shrink();

    return Positioned(
      left: 20,
      bottom: 120, // Adjusted to be above bottom nav or other elements
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.blue.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Logo
            Image.asset(
              'assets/logos/app_logo.png',
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.rocket_launch,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 15),
            // Bottom Row Logos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallLogo('assets/logos/lg_logo.png'),
                _buildSmallLogo('assets/logos/gsoc_logo.png'),
                _buildSmallLogo('assets/logos/tic_logo.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallLogo(String path) {
    return Image.asset(
      path,
      height: 25,
      width: 25,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const SizedBox(width: 25, height: 25),
    );
  }
}
