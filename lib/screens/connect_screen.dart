import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/language_manager.dart';
import '../services/lg_service.dart';
import '../kmls/logo_kml.dart';
import '../utils/notifications.dart';
import '../database/db_helper.dart';

class ConnectScreen extends StatefulWidget {
  final bool isConnected;
  final VoidCallback onConnectToggle;
  final VoidCallback onMenuToggle;

  const ConnectScreen({
    super.key,
    required this.isConnected,
    required this.onConnectToggle,
    required this.onMenuToggle,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _screensController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = await DatabaseHelper.instance.getSetting('lg_user');
    final pass = await DatabaseHelper.instance.getSetting('lg_pass');
    final ip = await DatabaseHelper.instance.getSetting('lg_ip');
    final port = await DatabaseHelper.instance.getSetting('lg_port');
    final screens = await DatabaseHelper.instance.getSetting('lg_screens');

    setState(() {
      if (user != null) _userController.text = user;
      if (pass != null) _passwordController.text = pass;
      if (ip != null) _ipController.text = ip;
      if (port != null) _portController.text = port;
      if (screens != null) _screensController.text = screens;
    });
  }

  Future<void> _saveSettings() async {
    await DatabaseHelper.instance.saveSetting('lg_user', _userController.text.trim());
    await DatabaseHelper.instance.saveSetting('lg_pass', _passwordController.text.trim());
    await DatabaseHelper.instance.saveSetting('lg_ip', _ipController.text.trim());
    await DatabaseHelper.instance.saveSetting('lg_port', _portController.text.trim());
    await DatabaseHelper.instance.saveSetting('lg_screens', _screensController.text.trim());
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _screensController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (widget.isConnected) {
      await LGService.instance.clearKML();
      await LGService.instance.disconnect();
      widget.onConnectToggle();
      AppNotifications.show(context, LanguageManager.instance.translate('disconnected'), isError: true);
      return;
    }

    final user = _userController.text.trim();
    final pass = _passwordController.text.trim();
    final ip = _ipController.text.trim();
    final portStr = _portController.text.trim();
    final screensStr = _screensController.text.trim();

    if (user.isEmpty || pass.isEmpty || ip.isEmpty || portStr.isEmpty || screensStr.isEmpty) {
      AppNotifications.show(context, 'Please fill all fields', isError: true);
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      AppNotifications.show(context, 'Invalid port', isError: true);
      return;
    }

    final screens = int.tryParse(screensStr) ?? 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await LGService.instance.connect(
      host: ip,
      port: port,
      username: user,
      password: pass,
      screens: screens,
    );

    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      await _saveSettings();
      // Upload logo assets to LG
      await LGService.instance.uploadAssets();

      // Clear previous KMLs to ensure a clean slate after connection
      await LGService.instance.clearKML();
      
      // Check logo visibility setting
      final showLogos = await DatabaseHelper.instance.getSetting('showLogos');
      if (showLogos == 'true' || showLogos == null) {
        await LGService.instance.sendLogoKML(LogoKML.generate());
      } else {
        await LGService.instance.clearLogos();
      }

      widget.onConnectToggle();
      AppNotifications.show(context, LanguageManager.instance.translate('connected'));
    } else {
      AppNotifications.show(context, 'Connection failed. Check your data.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageManager.instance.languageNotifier,
      builder: (context, lang, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              GestureDetector(
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
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(_userController, LanguageManager.instance.translate('lg_user')),
                      _buildTextField(_passwordController, LanguageManager.instance.translate('lg_password'), isPassword: true),
                      _buildTextField(_ipController, LanguageManager.instance.translate('ip')),
                      _buildTextField(_portController, LanguageManager.instance.translate('lg_port')),
                      _buildTextField(_screensController, LanguageManager.instance.translate('screens')),
                      const SizedBox(height: 20),
                      _buildConnectButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return GestureDetector(
      onTap: _handleConnect,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isConnected
                ? [
                    const Color(0xFFFF8A8A).withOpacity(0.6),
                    const Color(0xFFFF8A8A).withOpacity(0.3),
                  ]
                : [
                    Colors.blue.withOpacity(0.6),
                    Colors.blue.withOpacity(0.3),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.isConnected ? const Color(0xFFFF8A8A).withOpacity(0.4) : Colors.white.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isConnected ? const Color(0xFFFF8A8A).withOpacity(0.3) : Colors.blue.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            LanguageManager.instance
                .translate(widget.isConnected ? 'disconnect_button' : 'connect_button')
                .toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
