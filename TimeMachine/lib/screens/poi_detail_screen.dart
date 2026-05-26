import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/poi.dart';
import '../services/language_manager.dart';
import '../services/time_manager.dart';

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
              _buildTitle(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPOIImage(),
                      const SizedBox(height: 20),
                      _buildToolButtons(),
                    ],
                  ),
                ),
              ),
              _buildTimelineSlider(),
            ],
          ),
        ),
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
                  color: widget.isConnected ? const Color(0xFF8AFF8A).withOpacity(0.2) : const Color(0xFFFF8A8A).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isConnected ? const Color(0xFF8AFF8A).withOpacity(0.4) : const Color(0xFFFF8A8A).withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  Icons.wifi,
                  color: widget.isConnected ? const Color(0xFF8AFF8A) : const Color(0xFFFF8A8A),
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
    final assetPathJpg = 'assets/images/PointsOfInterest/Default/${widget.poi.name}.jpg';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          assetPathJpg,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            final assetPathPng = 'assets/images/PointsOfInterest/Default/${widget.poi.name}.png';
            return Image.asset(
              assetPathPng,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 220,
                color: Colors.white10,
                child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
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
                child: _buildButton(
                  'ORBIT AROUND',
                  icon: Icons.public,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(child: _buildButton('SHOW STATISTICS')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.5),
            Colors.blue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
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
