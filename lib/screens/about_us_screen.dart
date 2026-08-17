import 'package:flutter/material.dart';
import '../services/language_manager.dart';

class AboutUsScreen extends StatelessWidget {
  final bool isConnected;

  const AboutUsScreen({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

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
              _buildHeader(context, isTablet),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildSectionTitle(
                                  LanguageManager.instance.translate(
                                    'app_description_title',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildSectionText(
                                  LanguageManager.instance.translate(
                                    'app_description_text',
                                  ),
                                ),
                                const SizedBox(height: 30),
                                _buildSectionTitle(
                                  LanguageManager.instance.translate(
                                    'mentions_title',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildMentionItem(
                                  LanguageManager.instance.translate(
                                    'mention_jan',
                                  ),
                                ),
                                _buildMentionItem(
                                  LanguageManager.instance.translate(
                                    'mention_alfredo',
                                  ),
                                ),
                                _buildMentionItem(
                                  LanguageManager.instance.translate(
                                    'mention_andreu',
                                  ),
                                ),
                                _buildMentionItem(
                                  LanguageManager.instance.translate(
                                    'mention_lg',
                                  ),
                                ),
                                _buildMentionItem(
                                  LanguageManager.instance.translate(
                                    'mention_parc',
                                  ),
                                ),
                                _buildMentionItem(
                                  LanguageManager.instance.translate(
                                    'mention_laboratoris',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white,
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  color: Colors.white,
                                  padding: const EdgeInsets.only(bottom: 40),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/Timeline/LogoDisplayScreen.png',
                                      width: isTablet ? 500 : 350,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/Timeline/LogoApp_Menu.png',
            width: double.infinity,
            height: isTablet ? 150 : 100,
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
