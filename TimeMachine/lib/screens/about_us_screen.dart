import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  final bool isConnected;

  const AboutUsScreen({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Timeline/GalaxyBackground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF8AFF8A).withOpacity(0.2) : const Color(0xFFFF8A8A).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnected ? const Color(0xFF8AFF8A).withOpacity(0.4) : const Color(0xFFFF8A8A).withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: isConnected ? const Color(0xFF8AFF8A).withOpacity(0.2) : const Color(0xFFFF8A8A).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.wifi,
              color: isConnected ? const Color(0xFF8AFF8A) : const Color(0xFFFF8A8A),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
