import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import '../models/poi.dart';
import '../services/language_manager.dart';
import '../services/time_manager.dart';
import '../services/lg_service.dart';
import '../services/api_service.dart';
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
  bool _cooldownStatistics = false;
  bool _cooldownComparison = false;
  bool _cooldownOrbit = false;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  String? _cachedFutureImagePath;
  String? _cachedFutureText;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTts();
    _checkFutureAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoTravel();
    });
  }

  Future<void> _autoTravel() async {
    if (widget.isConnected) {
      final logosKml = LogoKML.generate();
      await LGService.instance.sendLogoKML(logosKml);

      // La barrera 3D usa el canal slave_X.kml que ya funciona.
      // La pantalla derecha queda reservada para el balloon.
      final boundaryResult = await LGService.instance.sendPOIBoundaryKML(
        latitude: widget.poi.latitude,
        longitude: widget.poi.longitude,
        sizeMeters: 200.0,
        heightMeters: 15.0,
      );

      if (boundaryResult != null) {
        debugPrint(
          'POIDetailScreen: error enviando barrera 3D: $boundaryResult',
        );
      }

      // Dejamos que Liquid Galaxy reciba el KML antes del FlyTo.
      await Future.delayed(const Duration(milliseconds: 250));

      final lookAt = LookAtKML.generate(
        widget.poi,
        LGService.instance.screens,
      );
      await LGService.instance.sendQuery('flytoview=$lookAt');

      // El balloon se envía después del FlyTo y directamente al slave
      // reservado para balloons.
      await Future.delayed(const Duration(milliseconds: 250));
      await _showBalloonOnly();
    }
  }

  Future<void> _showBalloonOnly() async {
    if (!widget.isConnected) return;

    final double timeValue = TimeManager.instance.timeValue;
    final bool isPast = timeValue == 0.0;
    final bool isPresent = timeValue == 1.0;
    final bool isFuture = timeValue == 2.0;

    String viewType = "";
    String statsText = "";

    if (isPast) {
      viewType = "${LanguageManager.instance.translate('past')} VIEW";
      statsText = widget.poi.statisticsTextPast;
    } else if (isPresent) {
      viewType = "${LanguageManager.instance.translate('present')} VIEW";
      statsText = widget.poi.statisticsTextPresent;
    } else if (isFuture) {
      viewType = "${LanguageManager.instance.translate('future')} VIEW";
      statsText = _cachedFutureText ?? "";
    }

    final String balloonKml = StatisticsOverlayKML.generate(
      poi: widget.poi,
      statisticsText: statsText,
      viewType: viewType,
    );

    // El balloon vive en LG3, que es el slave reservado para la
    // información HTML/KML. LGService lo compone con la barrera 3D.
    await LGService.instance.sendBalloonKML(balloonKml);
  }

  void _startStatisticsCooldown() {
    if (mounted) setState(() => _cooldownStatistics = true);
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _cooldownStatistics = false);
    });
  }

  void _startComparisonCooldown() {
    if (mounted) setState(() => _cooldownComparison = true);
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _cooldownComparison = false);
    });
  }

  Future<void> _toggleStatistics({bool forceShow = false}) async {
    if (_isLoadingStatistics || _showingComparison || _cooldownStatistics) return;
    if (!widget.isConnected) return;

    final double timeValue = TimeManager.instance.timeValue;
    final bool isPast = timeValue == 0.0;
    final bool isPresent = timeValue == 1.0;
    final bool isFuture = timeValue == 2.0;

    if (isFuture && !_futureImageExists && !forceShow) return;

    setState(() {
      _isLoadingStatistics = true;
    });

    try {
      if (_showingStatistics && !forceShow) {
        // Hide Chromium photo but KEEP balloon
        await Future.wait([
          LGService.instance.stopBrowser(1),
          LGService.instance.stopBrowser(2),
          if (LGService.instance.screens == 5) ...[
            LGService.instance.stopBrowser(4),
            LGService.instance.stopBrowser(5),
          ],
        ]);

        if (mounted) {
          setState(() {
            _showingStatistics = false;
          });
        }
      } else {
        String? assetPath;
        if (isPast) {
          assetPath =
          widget.poi.pastImages.isNotEmpty ? widget.poi.pastImages.first : null;
        } else if (isPresent) {
          assetPath =
          widget.poi.presentImages.isNotEmpty
              ? widget.poi.presentImages.first
              : null;
        } else if (isFuture) {
          assetPath = _cachedFutureImagePath;
        }

        if (assetPath != null) {
          final fileName = await LGService.instance.uploadPOIImage(
            assetPath,
            isExternal: isFuture,
          );
          if (fileName != null) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final imageUrl = 'http://lg1:81/logos/$fileName?v=$timestamp';
            final int totalScreens = LGService.instance.screens;

            await LGService.instance.createStatisticsHTML(imageUrl);

            if (totalScreens == 5) {
              await Future.wait([
                LGService.instance.openBrowser(
                  5,
                  'http://lg1:81/statistics.html?screen=left&v=$timestamp',
                ),
                LGService.instance.openBrowser(
                  1,
                  'http://lg1:81/statistics.html?screen=center&v=$timestamp',
                ),
                LGService.instance.openBrowser(
                  2,
                  'http://lg1:81/statistics.html?screen=right&v=$timestamp',
                ),
              ]);
            } else if (totalScreens == 3) {
              await Future.wait([
                LGService.instance.openBrowser(
                  1,
                  'http://lg1:81/statistics.html?screen=center&v=$timestamp',
                ),
                LGService.instance.openBrowser(
                  2,
                  'http://lg1:81/statistics.html?screen=right&v=$timestamp',
                ),
              ]);
            } else {
              await LGService.instance.openBrowser(
                1,
                'http://lg1:81/statistics.html?screen=center&v=$timestamp',
              );
            }

            if (mounted) {
              setState(() {
                _showingStatistics = true;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling statistics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatistics = false;
        });
        _startStatisticsCooldown();
      }
    }
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    String textToSpeak = "";
    final double timeValue = TimeManager.instance.timeNotifier.value;
    final String currentLang = LanguageManager.instance.currentLanguage;

    if (_showingComparison) {
      textToSpeak =
      "${widget.poi.statisticsTextPast}. ${widget.poi.statisticsTextPresent}. ${widget.poi.comparisonSummary}";
    } else if (_showingStatistics) {
      if (timeValue == 0.0) {
        textToSpeak = widget.poi.statisticsTextPast;
      } else if (timeValue == 1.0) {
        textToSpeak = widget.poi.statisticsTextPresent;
      } else if (timeValue == 2.0 && _cachedFutureText != null) {
        textToSpeak = _cachedFutureText!;
      }
    }

    if (textToSpeak.isNotEmpty) {
      String ttsLang = "en-US";
      if (currentLang == 'es') ttsLang = "es-ES";
      if (currentLang == 'ca') ttsLang = "ca-ES";

      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(textToSpeak);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LanguageManager.instance.translate('no_narration'))),
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    if (LGService.instance.orbitPlaying) {
      LGService.instance.orbitStop();
    }
    if (_showingStatistics) {
      LGService.instance.clearStatistics();
    }
    if (_showingComparison) {
      LGService.instance.clearComparison();
    }
    LGService.instance.clearKML();
    super.dispose();
  }

  void _checkFutureAssets() async {
    final lang = LanguageManager.instance.currentLanguage;
    final path = await APIService.instance.getCachedFutureImage(widget.poi.name);
    final text = await APIService.instance.getCachedFutureText(widget.poi.name, lang);
    if (path != null) {
      setState(() {
        _cachedFutureImagePath = path;
        _cachedFutureText = text;
        _futureImageExists = true;
      });
    }
  }

  Future<void> _generateFutureAssets() async {
    final additivePrompt = _promptController.text;
    final lang = LanguageManager.instance.currentLanguage;
    setState(() {
      _isGeneratingFuture = true;
      // Clear existing assets for a fresh regeneration UX
      _cachedFutureImagePath = null;
      _cachedFutureText = null;
      _futureImageExists = false;
    });

    try {
      final results = await APIService.instance.generateFutureEstimation(
        widget.poi.name,
        lang,
        additivePrompt: additivePrompt,
      );
      final path = results['imagePath'];
      final text = results['statisticsText'];

      if (mounted) {
        setState(() {
          _isGeneratingFuture = false;
          if (path != null) {
            _cachedFutureImagePath = path;
            _cachedFutureText = text;
            _futureImageExists = true;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageManager.instance.translate('future_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingFuture = false;
          // Restore if possible? No, if it failed we leave it cleared or reload from cache.
          _checkFutureAssets();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LanguageManager.instance.translate('error_prefix')}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
                      _buildHeader(context, isConnected, isTablet),
                      _buildTitle(isTablet),
                      Expanded(
                        child: SingleChildScrollView(
                          child:
                          isTablet
                              ? Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildPOIImage(isTablet),
                              ),
                              Expanded(
                                flex: 4,
                                child: _buildToolButtons(
                                  isConnected,
                                  isTablet,
                                ),
                              ),
                            ],
                          )
                              : Column(
                            children: [
                              _buildPOIImage(isTablet),
                              const SizedBox(height: 20),
                              _buildToolButtons(isConnected, isTablet),
                            ],
                          ),
                        ),
                      ),
                      _buildTimelineSlider(isTablet),
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

  Widget _buildHeader(BuildContext context, bool isConnected, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/Timeline/LogoApp_Menu.png',
            width: double.infinity,
            height: isTablet ? 120 : 80,
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
                  color:
                  isConnected
                      ? const Color(0xFF8AFF8A).withValues(alpha: 0.2)
                      : const Color(0xFFFF8A8A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                    isConnected
                        ? const Color(0xFF8AFF8A).withValues(alpha: 0.4)
                        : const Color(0xFFFF8A8A).withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.wifi,
                  color:
                  isConnected
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

  Widget _buildTitle(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40.0 : 24.0,
        vertical: 10.0,
      ),
      child: Row(
        children: [
          Container(width: 3, height: isTablet ? 32 : 24, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'I ${widget.poi.name.toUpperCase()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 32 : 22,
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

  Widget _buildPOIImage(bool isTablet) {
    return ValueListenableBuilder<double>(
      valueListenable: TimeManager.instance.timeNotifier,
      builder: (context, timeValue, child) {
        String assetPath = '';
        bool isFuture = timeValue == 2.0;
        bool isPresent = timeValue == 1.0;
        bool isPast = timeValue == 0.0;

        if (isPast) {
          assetPath =
          widget.poi.pastImages.isNotEmpty
              ? widget.poi.pastImages.first
              : '';
        } else if (isPresent) {
          assetPath =
          widget.poi.presentImages.isNotEmpty
              ? widget.poi.presentImages.first
              : '';
        } else if (isFuture) {
          assetPath =
              _cachedFutureImagePath ??
                  (widget.poi.presentImages.isNotEmpty
                      ? widget.poi.presentImages.first
                      : '');
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 40.0 : 24.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    assetPath.isNotEmpty
                        ? (assetPath.startsWith('assets/')
                        ? Image.asset(
                      assetPath,
                      width: double.infinity,
                      height: isTablet ? 400 : 220,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                          _buildImageError(isTablet),
                    )
                        : Image.file(
                      File(assetPath),
                      width: double.infinity,
                      height: isTablet ? 400 : 220,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                          _buildImageError(isTablet),
                    ))
                        : _buildImageError(isTablet),
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
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isTablet ? 14 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isFuture && _futureImageExists)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${LanguageManager.instance.translate('estimation_of')} ${widget.poi.name} ${LanguageManager.instance.translate('estimation_in_2100').toLowerCase()}',
                        style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.7),
                          fontSize: isTablet ? 16 : 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolButtons(bool isConnected, bool isTablet) {
    return ValueListenableBuilder<double>(
      valueListenable: TimeManager.instance.timeNotifier,
      builder: (context, timeValue, child) {
        final bool isPast = timeValue == 0.0;
        final bool isPresent = timeValue == 1.0;
        final bool isFuture = timeValue == 2.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 40.0 : 24.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Row(
                children: [
                  if (!isPresent) ...[
                    Expanded(
                      child: _buildButton(
                        _showingComparison
                            ? LanguageManager.instance.translate(
                          'hide_comparison',
                        )
                            : LanguageManager.instance.translate(
                          'compare_present',
                        ),
                        color: _showingComparison ? Colors.red : Colors.blue,
                        isLoading: _isLoadingComparison,
                        isTablet: isTablet,
                        onTap:
                          (!isConnected ||
                            _isLoadingComparison ||
                            _showingStatistics ||
                            _cooldownComparison ||
                            (isFuture && !_futureImageExists))
                            ? null
                            : () async {
                          setState(() {
                            _isLoadingComparison = true;
                          });

                          try {
                            if (_showingComparison) {
                              await LGService.instance.clearComparison();
                              await LGService.instance.sendLogoKML(
                                LogoKML.generate(),
                              );
                              await _showBalloonOnly();
                              if (mounted) {
                                setState(() {
                                  _showingComparison = false;
                                });
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      LanguageManager.instance.translate(
                                        'comparison_hidden',
                                      ),
                                    ),
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                );
                              }
                            } else {
                              String? pastPath;
                              if (isPast) {
                                pastPath =
                                widget.poi.pastImages.isNotEmpty
                                    ? widget.poi.pastImages.first
                                    : null;
                              } else if (isFuture) {
                                pastPath = _cachedFutureImagePath;
                              }

                              final presentPath =
                              widget.poi.presentImages.isNotEmpty
                                  ? widget.poi.presentImages.first
                                  : null;

                              if (pastPath != null &&
                                  presentPath != null) {
                                final results = await Future.wait([
                                  LGService.instance.uploadPOIImage(
                                    pastPath,
                                    customName: isFuture
                                        ? 'comparison_future'
                                        : 'comparison_past',
                                    isExternal: isFuture,
                                  ),
                                  LGService.instance.uploadPOIImage(
                                    presentPath,
                                    customName: 'comparison_present',
                                  ),
                                ]);

                                final pastName = results[0];
                                final presentName = results[1];

                                if (pastName != null &&
                                    presentName != null) {
                                  final timestamp =
                                      DateTime.now().millisecondsSinceEpoch;
                                  final pastUrl =
                                      'http://lg1:81/logos/$pastName?v=$timestamp';
                                  final presentUrl =
                                      'http://lg1:81/logos/$presentName?v=$timestamp';

                                  await LGService.instance.clearComparison();
                                  await LGService.instance.createComparisonHTML(
                                    pastUrl,
                                    presentUrl,
                                  );

                                  final balloonKml = ComparisonOverlayKML.generate(
                                    poi: widget.poi,
                                    futureStats: _cachedFutureText,
                                    isFuture: isFuture,
                                  );

                                  // Parallel browser opening
                                  final List<Future> browserFutures = [];
                                  if (LGService.instance.screens == 5) {
                                    browserFutures.add(
                                      LGService.instance.openBrowser(
                                        4,
                                        'http://lg1:81/comparison.html?mode=past&side=left&v=$timestamp',
                                      ),
                                    );
                                    browserFutures.add(
                                      LGService.instance.openBrowser(
                                        5,
                                        'http://lg1:81/comparison.html?mode=past&side=right&v=$timestamp',
                                      ),
                                    );
                                  }

                                  browserFutures.add(
                                    LGService.instance.openBrowser(
                                      1,
                                      'http://lg1:81/comparison.html?mode=present&side=left&v=$timestamp',
                                    ),
                                  );
                                  browserFutures.add(
                                    LGService.instance.openBrowser(
                                      2,
                                      'http://lg1:81/comparison.html?mode=present&side=right&v=$timestamp',
                                    ),
                                  );

                                  await Future.wait(browserFutures);

                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  await LGService.instance.sendBalloonKML(
                                    balloonKml,
                                  );

                                  if (mounted) {
                                    setState(() {
                                      _showingComparison = true;
                                    });
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          LanguageManager.instance.translate(
                                            'comparison_success',
                                          ),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            debugPrint('Error in comparison process: $e');
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoadingComparison = false;
                              });
                              _startComparisonCooldown();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                  Expanded(
                    child: _buildButton(
                      _isSpeaking
                          ? LanguageManager.instance.translate('stop_narration')
                          : LanguageManager.instance.translate('ai_narration'),
                      color: _isSpeaking ? Colors.red : Colors.blue,
                      icon: _isSpeaking ? Icons.stop : Icons.record_voice_over,
                      isTablet: isTablet,
                      onTap:
                      (_showingStatistics ||
                          _showingComparison ||
                          _isSpeaking)
                          ? () => _speak()
                          : null,
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
                          isOrbiting
                              ? LanguageManager.instance.translate('stop_orbit')
                              : LanguageManager.instance.translate(
                            'orbit_around',
                          ),
                          icon: isOrbiting ? Icons.stop_circle : Icons.public,
                          color: isOrbiting ? Colors.red : Colors.blue,
                          isTablet: isTablet,
                          onTap:
                          (_showingStatistics || _cooldownOrbit)
                              ? null
                              : () async {
                            if (isConnected) {
                              setState(() {
                                _cooldownOrbit = true;
                              });

                              Future.delayed(const Duration(milliseconds: 3500), () {
                                if (mounted) {
                                  setState(() {
                                    _cooldownOrbit = false;
                                  });
                                }
                              });

                              if (isOrbiting) {
                                await LGService.instance.orbitStop();
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      LanguageManager.instance
                                          .translate('orbit_stopped'),
                                    ),
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

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${LanguageManager.instance.translate('orbit_starting')} ${widget.poi.name}...',
                                  ),
                                  backgroundColor: Colors.blue.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    LanguageManager.instance.translate(
                                      'connect_first',
                                    ),
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
                          ? LanguageManager.instance.translate(
                        'hide_statistics',
                      )
                          : '${LanguageManager.instance.translate('show_statistics')} (${LanguageManager.instance.translate(TimeManager.instance.getTimeState())})',
                      color: _showingStatistics ? Colors.orange : Colors.blue,
                      isLoading: _isLoadingStatistics,
                      isTablet: isTablet,
                      onTap:
                      (_isLoadingStatistics ||
                          _showingComparison ||
                          _cooldownStatistics ||
                          (isFuture && !_futureImageExists))
                          ? null
                          : _toggleStatistics,
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
                        isTablet: isTablet,
                        onTap:
                        (_isGeneratingFuture || _showingStatistics)
                            ? null
                            : _generateFutureAssets,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Text(
                    LanguageManager.instance.translate('ai_disclaimer'),
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: isTablet ? 14 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _promptController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 16 : 12,
                    ),
                    decoration: InputDecoration(
                      hintText: LanguageManager.instance.translate(
                        'additive_prompt_hint',
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: isTablet ? 16 : 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
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
        bool isTablet = false,
      }) {
    final bool isDisabled = onTap == null && !isLoading;
    final baseColor = color ?? Colors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 12,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor.withValues(alpha: 0.5),
                baseColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: baseColor.withValues(alpha: 0.4)),
            boxShadow:
            isDisabled
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
                Icon(icon, color: Colors.white, size: isTablet ? 20 : 16),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  isLoading
                      ? LanguageManager.instance.translate('loading')
                      : label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 14 : 10,
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

  Widget _buildImageError(bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 400 : 220,
      color: Colors.white10,
      child: Icon(
        Icons.image_not_supported,
        color: Colors.white24,
        size: isTablet ? 80 : 50,
      ),
    );
  }

  Widget _buildTimelineSlider(bool isTablet) {
    return ValueListenableBuilder<double>(
      valueListenable: TimeManager.instance.timeNotifier,
      builder: (context, timeValue, child) {
        return AbsorbPointer(
          absorbing: _showingStatistics || _showingComparison,
          child: Opacity(
            opacity: (_showingStatistics || _showingComparison) ? 0.5 : 1.0,
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
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
                          isTablet,
                        ),
                        _timeLabel(
                          LanguageManager.instance
                              .translate('present')
                              .toUpperCase(),
                          timeValue == 1,
                          1,
                          isTablet,
                        ),
                        _timeLabel(
                          LanguageManager.instance
                              .translate('future')
                              .toUpperCase(),
                          timeValue == 2,
                          2,
                          isTablet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.cyanAccent,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.2,
                        ),
                        trackHeight: 4.0,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10.0,
                        ),
                        overlayColor: Colors.cyanAccent.withValues(
                          alpha: 0.3,
                        ),
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
                              color: Colors.cyanAccent.withValues(
                                alpha: 0.3,
                              ),
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
                            _showBalloonOnly();
                            if (_showingStatistics) {
                              _toggleStatistics(forceShow: true);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _timeLabel(
      String label,
      bool isSelected,
      double value,
      bool isTablet,
      ) {
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
            fontSize: isTablet ? 12 : 9,
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

