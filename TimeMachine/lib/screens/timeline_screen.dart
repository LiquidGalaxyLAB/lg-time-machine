import 'package:flutter/material.dart';
import 'dart:ui';
import '../database/db_helper.dart';
import '../models/country.dart';
import 'about_us_screen.dart';
import 'help_screen.dart';

class TimelineScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const TimelineScreen({super.key, this.onTabChange});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> with SingleTickerProviderStateMixin {
  List<Country> _countries = [];
  double _timeValue = 1.0; // 0: Past, 1: Present, 2: Future
  bool _isMenuOpen = false;
  late AnimationController _menuAnimationController;
  late Animation<Offset> _menuOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await DatabaseHelper.instance.getAllCountries();
    setState(() {
      _countries = countries;
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Search bar and menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.menu, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar países...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Country List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(country.flag, style: const TextStyle(fontSize: 16)),
                      ),
                      title: Text(
                        country.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
            // Timeline Slider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: 5.0),
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
                      _timeLabel('PASADO', _timeValue == 0),
                      _timeLabel('PRESENTE', _timeValue == 1),
                      _timeLabel('FUTURO', _timeValue == 2),
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
                        value: _timeValue,
                        min: 0,
                        max: 2,
                        divisions: 2,
                        onChanged: (value) {
                          setState(() {
                            _timeValue = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildSideMenu(),
      ],
    );
  }

  Widget _buildSideMenu() {
    return AnimatedBuilder(
      animation: _menuAnimationController,
      builder: (context, child) {
        if (_menuAnimationController.isDismissed && !_isMenuOpen) {
          return const SizedBox.shrink();
        }
        return Positioned.fill(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _menuAnimationController.value),
                ),
              ),
              SlideTransition(
                position: _menuOffsetAnimation,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping inside the menu
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            border: Border(
                              right: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                                        onPressed: _toggleMenu,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _menuItem('ABOUT US', () {
                                  _toggleMenu();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                                  );
                                }),
                                _menuItem('HELP', () {
                                  _toggleMenu();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                                  );
                                }),
                                _menuItem('CONNECTION', () {
                                  _toggleMenu();
                                  widget.onTabChange?.call(0);
                                }),
                                _menuItem('SETTINGS', () {
                                  _toggleMenu();
                                  widget.onTabChange?.call(2);
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _timeLabel(String label, bool isSelected) {
    return AnimatedContainer(
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
    );
  }
}
