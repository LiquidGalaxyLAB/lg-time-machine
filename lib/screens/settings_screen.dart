import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/language_manager.dart';
import '../services/lg_service.dart';
import '../kmls/logo_kml.dart';
import '../database/db_helper.dart';

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
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final showLogos = await DatabaseHelper.instance.getSetting('showLogos');
    setState(() {
      if (showLogos != null) {
        _showLogos = showLogos == 'true';
      }
    });
  }

  bool _isRelaunching = false;
  bool _isRebooting = false;
  bool _isClearingKml = false;
  bool _isClearingLogos = false;
  bool _isShuttingDown = false;

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
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.menu, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildContainer(
      title: LanguageManager.instance.translate('preferences').toUpperCase(),
      child: Column(children: [_buildLanguageRow()]),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: _showLanguageDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayLang,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 16,
                ),
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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LanguageManager.instance
                        .translate('language')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

  void _showConfirmationDialog(String action, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LanguageManager.instance
                        .translate('confirm_title')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${LanguageManager.instance.translate('confirm_message')} ${action.toLowerCase()}?",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _buildToolButton(
                          LanguageManager.instance.translate('no'),
                          () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildToolButton(
                          LanguageManager.instance.translate('yes'),
                          () {
                            onConfirm();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
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
                child: _buildToolButton(
                  LanguageManager.instance.translate('relaunch'),
                  () => _handleToolAction(
                    'relaunch',
                    () async => await LGService.instance.relaunch(),
                    (val) => setState(() => _isRelaunching = val),
                    confirm: true,
                  ),
                  loading: _isRelaunching,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolButton(
                  LanguageManager.instance.translate('shutdown'),
                  () => _handleToolAction(
                    'shutdown',
                    () async => await LGService.instance.shutdown(),
                    (val) => setState(() => _isShuttingDown = val),
                    confirm: true,
                  ),
                  loading: _isShuttingDown,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolButton(
                  LanguageManager.instance.translate('reboot_lg'),
                  () => _handleToolAction(
                    'reboot_lg',
                    () async => await LGService.instance.reboot(),
                    (val) => setState(() => _isRebooting = val),
                    confirm: true,
                  ),
                  loading: _isRebooting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(
                  LanguageManager.instance.translate('clean_kmls'),
                  () => _handleToolAction(
                    'clean_kmls',
                    () async => await LGService.instance.clearKML(),
                    (val) => setState(() => _isClearingKml = val),
                    confirm: false,
                  ),
                  loading: _isClearingKml,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolButton(
                  LanguageManager.instance.translate('clean_logos'),
                  () => _handleToolAction(
                    'clean_logos',
                    () async {
                      await LGService.instance.clearLogos();
                    },
                    (val) => setState(() => _isClearingLogos = val),
                    confirm: false,
                  ),
                  loading: _isClearingLogos,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LanguageManager.instance
                    .translate('show_hide_logos')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildCustomCheckbox(_showLogos, (val) async {
                setState(() => _showLogos = val);
                await DatabaseHelper.instance.saveSetting(
                  'showLogos',
                  val.toString(),
                );
                if (widget.isConnected) {
                  if (val) {
                    await LGService.instance.sendLogoKML(LogoKML.generate());
                  } else {
                    await LGService.instance.clearLogos();
                  }
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleToolAction(
    String labelKey,
    Future<void> Function() action,
    Function(bool) setLoading, {
    bool confirm = true,
  }) async {
    if (!widget.isConnected) return;

    if (confirm) {
      _showConfirmationDialog(
        LanguageManager.instance.translate(labelKey),
        () async {
          setLoading(true);
          try {
            await action();
          } catch (e) {
            debugPrint('Error executing tool action: $e');
          } finally {
            if (mounted) {
              setLoading(false);
            }
          }
        },
      );
    } else {
      setLoading(true);
      try {
        await action();
      } catch (e) {
        debugPrint('Error executing tool action: $e');
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    }
  }

  Widget _buildToolButton(
    String label,
    VoidCallback? onTap, {
    bool loading = false,
  }) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.5),
              Colors.blue.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
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
              boxShadow: value
                  ? [
                      const BoxShadow(
                        color: Colors.blue,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
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
