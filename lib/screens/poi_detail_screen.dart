import 'package:flutter/material.dart';
import '../models/poi.dart';
import '../services/language_manager.dart';
import '../services/time_manager.dart';
import '../services/lg_service.dart';
import '../kmls/logo_kml.dart';
import '../kmls/look_at_kml.dart';
import '../kmls/statistics_overlay_kml.dart';
import '../kmls/comparison_overlay_kml.dart';

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
  bool _showingStatistics = false;
  bool _isLoadingStatistics = false;
  bool _showingComparison = false;
  bool _isLoadingComparison = false;

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
    if (_showingStatistics) {
      LGService.instance.clearStatistics();
    }
    if (_showingComparison) {
      LGService.instance.clearComparison();
    }
    super.dispose();
  }

  void _checkFutureImage() {
    // In a real app, we would check if the file exists on disk
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
                    image: AssetImage(
                      'assets/images/Timeline/GalaxyBackground.png',
                    ),
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

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        children: [
          Container(width: 3, height: 24, color: Colors.white),
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
          assetPath = widget.poi.pastImages.isNotEmpty
              ? widget.poi.pastImages.first
              : '';
        } else if (isPresent) {
          assetPath = widget.poi.presentImages.isNotEmpty
              ? widget.poi.presentImages.first
              : '';
        } else if (isFuture) {
          assetPath = widget.poi.presentImages.isNotEmpty
              ? widget.poi.presentImages.first
              : '';
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: double.infinity,
                                  height: 220,
                                  color: Colors.white10,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white24,
                                    size: 50,
                                  ),
                                ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 220,
                            color: Colors.white10,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white24,
                              size: 50,
                            ),
                          ),
                    if (isFuture && _futureImageExists)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.8),
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
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
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
    return ValueListenableBuilder<double>(
      valueListenable: TimeManager.instance.timeNotifier,
      builder: (context, timeValue, child) {
        final bool isPast = timeValue == 0.0;
        final bool isPresent = timeValue == 1.0;
        final bool isFuture = timeValue == 2.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      LanguageManager.instance
                          .translate('travel_lg')
                          .toUpperCase(),
                      icon: Icons.rocket_launch,
                      onTap: _showingStatistics
                          ? null
                          : () async {
                              if (isConnected) {
                                final logosKml = LogoKML.generate();
                                await LGService.instance.sendLogoKML(logosKml);
                                final lookAt = LookAtKML.generate(
                                  widget.poi,
                                  LGService.instance.screens,
                                );
                                await LGService.instance.sendQuery(
                                  'flytoview=$lookAt',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Traveling to ${widget.poi.name}...',
                                    ),
                                    backgroundColor: Colors.blue.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please connect to Liquid Galaxy first',
                                    ),
                                  ),
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
                  if (!isPresent) ...[
                    Expanded(
                      child: _buildButton(
                        _showingComparison
                            ? 'HIDE COMPARISON'
                            : 'COMPARE WITH PRESENT',
                        color: _showingComparison ? Colors.red : Colors.blue,
                        isLoading: _isLoadingComparison,
                        onTap:
                            (!isConnected ||
                                _isLoadingComparison ||
                                _showingStatistics)
                            ? null
                            : () async {
                                setState(() {
                                  _isLoadingComparison = true;
                                });

                                if (_showingComparison) {
                                  await LGService.instance.clearComparison();
                                  await LGService.instance.sendLogoKML(
                                    LogoKML.generate(),
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _showingComparison = false;
                                      _isLoadingComparison = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Comparison hidden'),
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                    );
                                  }
                                } else {
                                  final pastPath =
                                      widget.poi.pastImages.isNotEmpty
                                      ? widget.poi.pastImages.first
                                      : null;
                                  final presentPath =
                                      widget.poi.presentImages.isNotEmpty
                                      ? widget.poi.presentImages.first
                                      : null;

                                  if (pastPath != null && presentPath != null) {
                                    final pastName = await LGService.instance
                                        .uploadPOIImage(
                                          pastPath,
                                          customName: 'comparison_past',
                                        );
                                    final presentName = await LGService.instance
                                        .uploadPOIImage(
                                          presentPath,
                                          customName: 'comparison_present',
                                        );

                                    if (pastName != null &&
                                        presentName != null) {
                                      final pastUrl =
                                          'http://lg1:81/logos/$pastName';
                                      final presentUrl =
                                          'http://lg1:81/logos/$presentName';

                                      await LGService.instance
                                          .clearComparison();
                                      await LGService.instance
                                          .createComparisonHTML(
                                            pastUrl,
                                            presentUrl,
                                          );

                                      final balloonKml =
                                          ComparisonOverlayKML.generate(
                                            poi: widget.poi,
                                          );
                                      await LGService.instance.sendSlaveKML(
                                        3,
                                        balloonKml,
                                      );

                                      // Orden: lg4, lg5 (PAST) | lg1, lg2 (PRESENT)
                                      // lg4: Left half of Past
                                      await LGService.instance.openBrowser(
                                        4,
                                        'http://lg1:81/comparison.html?mode=past&side=left',
                                      );
                                      // lg5: Right half of Past
                                      await LGService.instance.openBrowser(
                                        5,
                                        'http://lg1:81/comparison.html?mode=past&side=right',
                                      );
                                      // lg1: Left half of Present
                                      await LGService.instance.openBrowser(
                                        1,
                                        'http://lg1:81/comparison.html?mode=present&side=left',
                                      );
                                      // lg2: Right half of Present
                                      await LGService.instance.openBrowser(
                                        2,
                                        'http://lg1:81/comparison.html?mode=present&side=right',
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _showingComparison = true;
                                          _isLoadingComparison = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Comparison loaded successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted)
                                        setState(
                                          () => _isLoadingComparison = false,
                                        );
                                    }
                                  } else {
                                    if (mounted)
                                      setState(
                                        () => _isLoadingComparison = false,
                                      );
                                  }
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                  Expanded(
                    child: _buildButton(
                      'AI NARRATION',
                      onTap: _showingStatistics
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Starting AI Narration...'),
                                  backgroundColor: Colors.blueAccent,
                                ),
                              );
                            },
                    ),
                  ),
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
                          onTap: _showingStatistics
                              ? null
                              : () async {
                                  if (isConnected) {
                                    if (isOrbiting) {
                                      await LGService.instance.orbitStop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Orbit stopped'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    await LGService.instance.orbitPlay(
                                      widget.poi.latitude,
                                      widget.poi.longitude,
                                      widget.poi.range /
                                          LGService.instance.screens,
                                      45,
                                      initialBearing: widget.poi.heading,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Starting orbit around ${widget.poi.name}...',
                                        ),
                                        backgroundColor: Colors.blue.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please connect to Liquid Galaxy first',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildButton(
                      _showingStatistics
                          ? 'HIDE STATISTICS'
                          : 'SHOW STATISTICS',
                      color: _showingStatistics ? Colors.orange : Colors.blue,
                      isLoading: _isLoadingStatistics,
                      onTap:
                          (!isConnected ||
                              isFuture ||
                              _isLoadingStatistics ||
                              _showingComparison)
                          ? null
                          : () async {
                              setState(() {
                                _isLoadingStatistics = true;
                              });

                              if (_showingStatistics) {
                                await LGService.instance.clearStatistics();
                                await LGService.instance.sendLogoKML(
                                  LogoKML.generate(),
                                );
                                if (mounted) {
                                  setState(() {
                                    _showingStatistics = false;
                                    _isLoadingStatistics = false;
                                  });
                                }
                              } else {
                                String? assetPath;
                                if (isPast) {
                                  assetPath = widget.poi.pastImages.isNotEmpty
                                      ? widget.poi.pastImages.first
                                      : null;
                                } else if (isPresent) {
                                  assetPath =
                                      widget.poi.presentImages.isNotEmpty
                                      ? widget.poi.presentImages.first
                                      : null;
                                }

                                if (assetPath != null) {
                                  final fileName = await LGService.instance
                                      .uploadPOIImage(assetPath);
                                  if (fileName != null) {
                                    final imageUrl =
                                        'http://lg1:81/logos/$fileName';
                                    final int totalScreens =
                                        LGService.instance.screens;

                                    // 1. Limpiamos KMLs y navegadores previos
                                    await LGService.instance.clearStatistics();

                                    // 2. Creamos los HTMLs para el fondo (LG4, LG1, LG2)
                                    await LGService.instance
                                        .createStatisticsHTML(imageUrl);

                                    final String statsText = isPast
                                        ? widget.poi.statisticsTextPast
                                        : widget.poi.statisticsTextPresent;

                                    // 3. Generamos y enviamos el KML de la burbuja nativa a LG3 (Slave 3)
                                    final String balloonKml =
                                        StatisticsOverlayKML.generate(
                                          poi: widget.poi,
                                          imageUrl: imageUrl,
                                          statisticsText: statsText,
                                        );
                                    await LGService.instance.sendSlaveKML(
                                      3,
                                      balloonKml,
                                    );

                                    // 4. Abrimos los navegadores para los fondos panorámicos
                                    if (totalScreens == 5) {
                                      // LG5 (Izquierda)
                                      await LGService.instance.openBrowser(
                                        5,
                                        'http://lg1:81/statistics.html?screen=left',
                                      );

                                      // LG1 (Centro)
                                      await LGService.instance.openBrowser(
                                        1,
                                        'http://lg1:81/statistics.html?screen=center',
                                      );

                                      // LG2 (Derecha)
                                      await LGService.instance.openBrowser(
                                        2,
                                        'http://lg1:81/statistics.html?screen=right',
                                      );
                                    } else if (totalScreens == 3) {
                                      // LG1 (Centro)
                                      await LGService.instance.openBrowser(
                                        1,
                                        'http://lg1:81/statistics.html?screen=center',
                                      );

                                      // LG2 (Derecha - con logo)
                                      await LGService.instance.openBrowser(
                                        2,
                                        'http://lg1:81/statistics.html?screen=right',
                                      );
                                      // LG3 tiene el globo de estadísticas (KML)
                                    } else {
                                      // Solo una pantalla
                                      await LGService.instance.openBrowser(
                                        1,
                                        'http://lg1:81/statistics.html?screen=center',
                                      );
                                    }

                                    if (mounted) {
                                      setState(() {
                                        _showingStatistics = true;
                                        _isLoadingStatistics = false;
                                      });
                                    }
                                  } else {
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingStatistics = false;
                                      });
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    setState(() {
                                      _isLoadingStatistics = false;
                                    });
                                  }
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
              if (isFuture) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        _futureImageExists
                            ? LanguageManager.instance.translate(
                                'regenerate_future',
                              )
                            : LanguageManager.instance.translate(
                                'generate_future',
                              ),
                        icon: Icons.auto_awesome,
                        onTap: (_isGeneratingFuture || _showingStatistics)
                            ? null
                            : _generateFutureImage,
                      ),
                    ),
                  ],
                ),
                if (_isGeneratingFuture)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.cyanAccent,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(
    String label, {
    IconData? icon,
    VoidCallback? onTap,
    Color? color,
    bool isLoading = false,
  }) {
    final bool isDisabled = onTap == null && !isLoading;
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
                baseColor.withValues(alpha: 0.5),
                baseColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: baseColor.withValues(alpha: 0.4)),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  isLoading ? 'LOADING...' : label,
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
        return AbsorbPointer(
          absorbing: _showingStatistics || _showingComparison,
          child: Opacity(
            opacity: (_showingStatistics || _showingComparison) ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _timeLabel(
                        LanguageManager.instance
                            .translate('past')
                            .toUpperCase(),
                        timeValue == 0,
                        0,
                      ),
                      _timeLabel(
                        LanguageManager.instance
                            .translate('present')
                            .toUpperCase(),
                        timeValue == 1,
                        1,
                      ),
                      _timeLabel(
                        LanguageManager.instance
                            .translate('future')
                            .toUpperCase(),
                        timeValue == 2,
                        2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.cyanAccent,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                      trackHeight: 4.0,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10.0,
                      ),
                      overlayColor: Colors.cyanAccent.withValues(alpha: 0.3),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20.0,
                      ),
                      tickMarkShape: const RoundSliderTickMarkShape(),
                      activeTickMarkColor: Colors.cyanAccent,
                      inactiveTickMarkColor: Colors.white.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.3),
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
            ),
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
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 9,
            letterSpacing: 1.0,
            shadows: isSelected
                ? [const Shadow(color: Colors.cyanAccent, blurRadius: 6)]
                : [],
          ),
        ),
      ),
    );
  }
}
