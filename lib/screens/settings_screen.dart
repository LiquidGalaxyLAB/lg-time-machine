import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/language_manager.dart';
import '../services/lg_service.dart';
import '../services/font_manager.dart';
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
  bool _isRelaunching = false;
  bool _isRebooting = false;
  bool _isClearingKml = false;
  bool _isClearingLogos = false;
  bool _isShuttingDown = false;

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final showLogos = await DatabaseHelper.instance.getSetting('showLogos');
    final apiKey = await DatabaseHelper.instance.getSetting('imageGenerationApiKey');
    final model = await DatabaseHelper.instance.getSetting('imageGenerationModel');
    
    setState(() {
      if (showLogos != null) {
        _showLogos = showLogos == 'true';
      }
      _apiKeyController.text = apiKey ?? '';
      _modelController.text = model ?? 'sana';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return ValueListenableBuilder<String>(
      valueListenable: LanguageManager.instance.languageNotifier,
      builder: (context, lang, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 800 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSideMenuButton(),
                  const SizedBox(height: 20),
                  _buildPreferencesSection(),
                  const SizedBox(height: 20),
                  _buildLGToolsSection(isTablet),
                  const SizedBox(height: 20),
                  _buildAPIManagementSection(isTablet),
                  const SizedBox(height: 20),
                  _buildAPIObtainmentSection(isTablet),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
      child: Column(
        children: [
          _buildLanguageRow(),
          const SizedBox(height: 15),
          _buildFontSizeRow(),
        ],
      ),
    );
  }

  Widget _buildFontSizeRow() {
    return ValueListenableBuilder<double>(
      valueListenable: FontManager.instance.fontScaleNotifier,
      builder: (context, currentScale, child) {
        String displaySize = LanguageManager.instance.translate(
          currentScale < 1.0
              ? 'small'
              : currentScale > 1.0
                  ? 'large'
                  : 'medium',
        ).toUpperCase();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LanguageManager.instance.translate('font_size').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: _showFontSizeDialog,
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
                      displaySize,
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
      },
    );
  }

  void _showFontSizeDialog() {
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
                        .translate('font_size')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fontSizeOption(LanguageManager.instance.translate('small').toUpperCase(), 0.8),
                  _fontSizeOption(LanguageManager.instance.translate('medium').toUpperCase(), 1.0),
                  _fontSizeOption(LanguageManager.instance.translate('large').toUpperCase(), 1.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fontSizeOption(String title, double scale) {
    bool isSelected = FontManager.instance.fontScaleNotifier.value == scale;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        FontManager.instance.setFontScale(scale);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLanguageRow() {
    String currentLang = LanguageManager.instance.currentLanguage;
    String displayLang = LanguageManager.instance.translate(
      currentLang == 'en'
          ? 'english'
          : currentLang == 'es'
              ? 'spanish'
              : 'catalan',
    ).toUpperCase();

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
                  _languageOption(LanguageManager.instance.translate('english').toUpperCase(), 'en'),
                  _languageOption(LanguageManager.instance.translate('spanish').toUpperCase(), 'es'),
                  _languageOption(LanguageManager.instance.translate('catalan').toUpperCase(), 'ca'),
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

  Widget _buildLGToolsSection(bool isTablet) {
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

  Widget _buildAPIManagementSection(bool isTablet) {
    return _buildContainer(
      title: LanguageManager.instance.translate('api_management').toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LanguageManager.instance
                .translate('image_generation_api')
                .toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(_apiKeyController, LanguageManager.instance.translate('api_key')),
          const SizedBox(height: 20),
          Text(
            LanguageManager.instance.translate('model').toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(_modelController, LanguageManager.instance.translate('model')),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: isTablet ? 300 : double.infinity,
              child: _buildToolButton(
                LanguageManager.instance.translate('save'),
                () async {
                  if (_apiKeyController.text.isNotEmpty) {
                    await DatabaseHelper.instance.saveSetting(
                      'imageGenerationApiKey',
                      _apiKeyController.text,
                    );
                    await DatabaseHelper.instance.saveSetting(
                      'imageGenerationModel',
                      _modelController.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LanguageManager.instance
                              .translate('api_saved_success')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LanguageManager.instance
                              .translate('api_saved_error')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIObtainmentSection(bool isTablet) {
    return _buildContainer(
      title: "API OBTAINMENT",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepText("1. Enter https://pollinations.ai/"),
          _buildStepText("2. Click Register and enter with your account."),
          _buildStepText("3. On Pollinations side menu, on section Docs, click API."),
          _buildStepText("4. Inside API click \"Get your API Key\" and when created copy it."),
          _buildStepText("5. Introduce this Api key in the text input above \"IMAGE GENERATION API\"."),
          _buildStepText("6. Go to Pollination.ai and click on section \"Models\"."),
          _buildStepText("7. Use any of the models that are free to use, but have limited image generation."),
          _buildStepText("8. Click on the model title and the model code will be pasted, introduce it on your model input."),
        ],
      ),
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blue),
        ),
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
