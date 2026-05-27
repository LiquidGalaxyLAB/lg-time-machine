import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/language_manager.dart';
import '../services/lg_service.dart';
import '../services/kml_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isConnected;
  final VoidCallback onMenuToggle;

  const SettingsScreen({
    super.key,
    required this.isConnected,
    required this.onMenuToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showLogos = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageManager.instance.languageNotifier,
      builder: (context, lang, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSideMenuButton(),
              const SizedBox(height: 20),
              _buildPreferencesSection(),
              const SizedBox(height: 20),
              _buildLGToolsSection(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideMenuButton() {
    return GestureDetector(
      onTap: widget.onMenuToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Icon(Icons.menu, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildContainer(
      title: LanguageManager.instance.translate('preferences').toUpperCase(),
      child: Column(
        children: [
          _buildLanguageRow(),
        ],
      ),
    );
  }

  Widget _buildLanguageRow() {
    String currentLang = LanguageManager.instance.currentLanguage;
    String displayLang = 'ENGLISH';
    if (currentLang == 'es') displayLang = 'ESPAÑOL';
    if (currentLang == 'ca') displayLang = 'CATALÀ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          LanguageManager.instance.translate('language').toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        GestureDetector(
          onTap: _showLanguageDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayLang,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LanguageManager.instance.translate('language').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _languageOption('ENGLISH', 'en'),
                  _languageOption('ESPAÑOL', 'es'),
                  _languageOption('CATALÀ', 'ca'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageOption(String title, String code) {
    bool isSelected = LanguageManager.instance.currentLanguage == code;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        LanguageManager.instance.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLGToolsSection() {
    return _buildContainer(
      title: LanguageManager.instance.translate('lg_tools').toUpperCase(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildToolButton(LanguageManager.instance.translate('relaunch'), () async {
                  if (widget.isConnected) {
                    await LGService.instance.relaunch();
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolButton(LanguageManager.instance.translate('shutdown'), () async {
                  if (widget.isConnected) {
                    await LGService.instance.shutdown();
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(LanguageManager.instance.translate('clean_kmls'), () async {
                  if (widget.isConnected) {
                    await LGService.instance.clearKML();
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolButton(LanguageManager.instance.translate('clean_logos'), () async {
                  if (widget.isConnected) {
                    await LGService.instance.clearLogos();
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(LanguageManager.instance.translate('reboot_lg'), () async {
                  if (widget.isConnected) {
                    await LGService.instance.reboot();
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LanguageManager.instance.translate('show_hide_logos').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              _buildCustomCheckbox(_showLogos, (val) async {
                setState(() => _showLogos = val);
                if (widget.isConnected) {
                  if (val) {
                    await LGService.instance.sendKML(KMLService.getLogosKML());
                  } else {
                    await LGService.instance.clearKML();
                  }
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.5),
              Colors.blue.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckbox(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.blue : Colors.transparent,
              boxShadow: value ? [
                const BoxShadow(color: Colors.blue, blurRadius: 8, spreadRadius: 1)
              ] : [],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContainer({required String title, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
