import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final bool isConnected;

  const HelpScreen({super.key, required this.isConnected});

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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpItem(
                        'How does the app work?',
                        'This app allows you to control a Liquid Galaxy system and explore different places through time (Past, Present, and Future).',
                      ),
                      _buildHelpItem(
                        'How to connect?',
                        'Go to the Connection tab, enter your Liquid Galaxy user, password, IP, port, and number of screens, then press CONNECT.',
                      ),
                      _buildHelpItem(
                        'What is the Timeline?',
                        'The timeline lets you select different countries and see their most famous Points of Interest across different eras.',
                      ),
                      _buildHelpItem(
                        'Languages',
                        'You can change the app language in the Settings tab. We support English, Spanish, and Catalan.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/Timeline/LogoApp_Menu.png',
            width: double.infinity,
            height: 100,
            fit: BoxFit.contain,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha:0.2)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF8AFF8A).withValues(alpha:0.2)
                      : const Color(0xFFFF8A8A).withValues(alpha:0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF8AFF8A).withValues(alpha:0.4)
                        : const Color(0xFFFF8A8A).withValues(alpha:0.4),
                  ),
                ),
                child: Icon(
                  Icons.wifi,
                  color: isConnected
                      ? const Color(0xFF8AFF8A)
                      : const Color(0xFFFF8A8A),
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
