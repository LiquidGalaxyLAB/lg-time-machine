import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/poi.dart';
import '../services/language_manager.dart';
import '../services/time_manager.dart';
import '../services/lg_service.dart';
import '../kmls/logo_kml.dart';
import '../kmls/look_at_kml.dart';
import '../kmls/orbit_kml.dart';

class POIDetailScreen extends StatefulWidget {
  final POI poi;
  final bool isConnected;

  const POIDetailScreen({
    super.key,
    required this.poi,
    required this.isConnected,
  });

  @override
  State<POIDetailScreen> createState() => _POIDetailScreenState();
}

class _POIDetailScreenState extends State<POIDetailScreen> {
  bool _isGeneratingFuture = false;
  bool _futureImageExists = false;

  @override
  void initState() {
    super.initState();
    _checkFutureImage();
  }

  @override
  void dispose() {
    if (LGService.instance.orbitPlaying) {
      LGService.instance.orbitStop();
    }
    super.dispose();
  }

  void _checkFutureImage() {
    // In a real app, we would check if the file exists on disk
    // For this simulation, we'll use a simple state
  }

  Future<void> _generateFutureImage() async {
    setState(() {
      _isGeneratingFuture = true;
    });

    // Simulate AI generation delay
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isGeneratingFuture = false;
        _futureImageExists = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageManager.instance.translate('future_success')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LGService.instance,
      builder: (context, _) {
        final bool isConnected = LGService.instance.isConnected;
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Timeline/GalaxyBackground.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, isConnected),
                      _buildTitle(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildPOIImage(),
                              const SizedBox(height: 20),
                              _buildToolButtons(isConnected),
                            ],
                          ),
                        ),
                      ),
                      _buildTimelineSlider(),
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

  Widget _buildHeader(BuildContext context, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/Timeline/LogoApp_Menu.png',
            width: double.infinity,
            height: 80,
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
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
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
                ),
                child: Icon(
                  Icons.wifi,
                  color: isConnected ? const Color(0xFF8AFF8A) : const Color(0xFFFF8A8A),
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'I ${widget.poi.name.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOIImage() {
    return ValueListenableBuilder<double>(
      valueListenable: TimeManager.instance.timeNotifier,
      builder: (context, timeValue, child) {
        String assetPath = '';
        bool isFuture = timeValue == 2.0;
        bool isPresent = timeValue == 1.0;
        bool isPast = timeValue == 0.0;

        if (isPast) {
          assetPath = widget.poi.pastImages.isNotEmpty ? widget.poi.pastImages.first : '';
        } else if (isPresent) {
          assetPath = widget.poi.presentImages.isNotEmpty ? widget.poi.presentImages.first : '';
        } else if (isFuture) {
          // Future image logic
          assetPath = widget.poi.presentImages.isNotEmpty ? widget.poi.presentImages.first : '';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    assetPath.isNotEmpty
                        ? Image.asset(
                            assetPath,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 220,
                              color: Colors.white10,
                              child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 220,
                            color: Colors.white10,
                            child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                          ),
                    if (isFuture && _futureImageExists)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            LanguageManager.instance.translate('ai_generated'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isFuture && _futureImageExists)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${LanguageManager.instance.translate('estimation_of')} ${widget.poi.name} in 2075',
                    style: TextStyle(
                      color: Colors.cyanAccent.withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolButtons(bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  LanguageManager.instance.translate('travel_lg').toUpperCase(),
                  icon: Icons.rocket_launch,
                  onTap: () async {
                    if (isConnected) {
                      final logosKml = LogoKML.generate();
                      await LGService.instance.sendLogoKML(logosKml);
                      final lookAt = LookAtKML.generate(widget.poi, LGService.instance.screens);
                      await LGService.instance.sendQuery('flytoview=$lookAt');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Traveling to ${widget.poi.name}...'),
                          backgroundColor: Colors.blue.withOpacity(0.8),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please connect to Liquid Galaxy first')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildButton('COMPARE WITH PRESENT')),
              const SizedBox(width: 15),
              Expanded(child: _buildButton('AI NARRATION')),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: LGService.instance,
                  builder: (context, _) {
                    final isOrbiting = LGService.instance.orbitPlaying;
                    return _buildButton(
                      isOrbiting ? 'STOP ORBIT' : 'ORBIT AROUND',
                      icon: isOrbiting ? Icons.stop_circle : Icons.public,
                      color: isOrbiting ? Colors.red : Colors.blue,
                      onTap: () async {
                        if (isConnected) {
                          if (isOrbiting) {
                            await LGService.instance.orbitStop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Orbit stopped'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          // Start the orbit using the new method
                          await LGService.instance.orbitPlay(
                            widget.poi.latitude,
                            widget.poi.longitude,
                            widget.poi.range / LGService.instance.screens,
                            45, // Tilt
                            initialBearing: widget.poi.heading,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Starting orbit around ${widget.poi.name}...'),
                              backgroundColor: Colors.blue.withOpacity(0.8),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please connect to Liquid Galaxy first')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(child: _buildButton('SHOW STATISTICS')),
            ],
          ),
          ValueListenableBuilder<double>(
            valueListenable: TimeManager.instance.timeNotifier,
            builder: (context, timeValue, child) {
              final isFuture = timeValue == 2.0;
              if (!isFuture) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          _futureImageExists
                              ? LanguageManager.instance.translate('regenerate_future')
                              : LanguageManager.instance.translate('generate_future'),
                          icon: Icons.auto_awesome,
                          onTap: _isGeneratingFuture ? null : _generateFutureImage,
                        ),
                      ),
                    ],
                  ),
                  if (_isGeneratingFuture)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, {IconData? icon, VoidCallback? onTap, Color? color}) {
    final bool isDisabled = onTap == null;
    final baseColor = color ?? Colors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor.withOpacity(0.5),
                baseColor.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: baseColor.withOpacity(0.4)),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: baseColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSlider() {
    return ValueListenableBuilder<double>(
      valueListenable: TimeManager.instance.timeNotifier,
      builder: (context, timeValue, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _timeLabel(LanguageManager.instance.translate('past').toUpperCase(), timeValue == 0, 0),
                  _timeLabel(LanguageManager.instance.translate('present').toUpperCase(), timeValue == 1, 1),
                  _timeLabel(LanguageManager.instance.translate('future').toUpperCase(), timeValue == 2, 2),
                ],
              ),
              const SizedBox(height: 2),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.cyanAccent,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  trackHeight: 4.0,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                  overlayColor: Colors.cyanAccent.withOpacity(0.3),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                  tickMarkShape: const RoundSliderTickMarkShape(),
                  activeTickMarkColor: Colors.cyanAccent,
                  inactiveTickMarkColor: Colors.white.withOpacity(0.3),
                ),
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Slider(
                    value: timeValue,
                    min: 0,
                    max: 2,
                    divisions: 2,
                    onChanged: (value) {
                      TimeManager.instance.setTime(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timeLabel(String label, bool isSelected, double value) {
    return GestureDetector(
      onTap: () => TimeManager.instance.setTime(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 9,
            letterSpacing: 1.0,
            shadows: isSelected
                ? [
                    const Shadow(
                      color: Colors.cyanAccent,
                      blurRadius: 6,
                    )
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
