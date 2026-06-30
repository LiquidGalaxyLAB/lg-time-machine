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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionTitle('APP DESCRIPTION'),
                      const SizedBox(height: 10),
                      _buildSectionText(
                        'Liquid Galaxy Time Machine is an interactive application designed to visualize the evolution of historical landmarks over time. '
                        'Using the power of Liquid Galaxy, users can travel through past, present, and future eras, exploring how architecture and landscapes have transformed '
                        'through immersive 3D visualizations and historical data.',
                      ),
                      const SizedBox(height: 30),
                      _buildSectionTitle('MENTIONS'),
                      const SizedBox(height: 10),
                      _buildMentionItem('Jan Sánchez - App Creator'),
                      _buildMentionItem('Alfredo Bautista - Mentor'),
                      _buildMentionItem('Andreu Ibañez - Mentor'),
                      _buildMentionItem('Liquid Galaxy Project'),
                      _buildMentionItem('Parc Agrobiotech Lleida'),
                      _buildMentionItem('Laboratoris TIC'),
                      const SizedBox(height: 40),
                      Center(
                        child: Image.asset(
                          'assets/images/Timeline/LogoDisplayScreen.png',
                          width: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildMentionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.cyanAccent, size: 16),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
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
                      ? const Color(0xFF8AFF8A).withValues(alpha: 0.2)
                      : const Color(0xFFFF8A8A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF8AFF8A).withValues(alpha: 0.4)
                        : const Color(0xFFFF8A8A).withValues(alpha: 0.4),
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
