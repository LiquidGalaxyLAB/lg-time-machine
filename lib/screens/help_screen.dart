import 'package:flutter/material.dart';
import '../services/language_manager.dart';

class HelpScreen extends StatelessWidget {
  final bool isConnected;

  const HelpScreen({super.key, required this.isConnected});

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
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHelpItem(
                            LanguageManager.instance.translate('help_q1'),
                            LanguageManager.instance.translate('help_a1'),
                            isTablet,
                          ),
                          _buildHelpItem(
                            LanguageManager.instance.translate('help_q2'),
                            LanguageManager.instance.translate('help_a2'),
                            isTablet,
                          ),
                          _buildHelpItem(
                            LanguageManager.instance.translate('help_q3'),
                            LanguageManager.instance.translate('help_a3'),
                            isTablet,
                          ),
                          _buildHelpItem(
                            LanguageManager.instance.translate('help_q4'),
                            LanguageManager.instance.translate('help_a4'),
                            isTablet,
                          ),
                          _buildHelpItem(
                            LanguageManager.instance.translate('help_q5'),
                            LanguageManager.instance.translate('help_a5'),
                            isTablet,
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

  Widget _buildHelpItem(String question, String answer, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: isTablet ? 18 : 16,
              height: 1.5,
            ),
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
