import 'package:flutter/material.dart';
import 'dart:ui';
import 'timeline_screen.dart';
import 'connect_screen.dart';
import 'about_us_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import '../services/language_manager.dart';
import '../services/lg_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Default to Timeline
  late PageController _pageController;
  bool get _isConnected => LGService.instance.isConnected;
  bool _isMenuOpen = false;
  late AnimationController _menuAnimationController;
  late Animation<Offset> _menuOffsetAnimation;

  void _toggleConnection() {
    setState(() {
      // LGService now manages the connection state
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
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
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
    _pageController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LGService.instance,
      builder: (context, child) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageManager.instance.languageNotifier,
          builder: (context, lang, child) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
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
                      bottom: false,
                      child: Column(
                        children: [
                          // Header with Logo
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Image.asset(
                              'assets/images/Timeline/LogoApp_Menu.png',
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Body
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              children: [
                                ConnectScreen(
                                  isConnected: _isConnected,
                                  onConnectToggle: _toggleConnection,
                                  onMenuToggle: _toggleMenu,
                                ),
                                TimelineScreen(
                                  onTabChange: _onItemTapped,
                                  isConnected: _isConnected,
                                  onMenuToggle: _toggleMenu,
                                ),
                                SettingsScreen(
                                  isConnected: _isConnected,
                                  onMenuToggle: _toggleMenu,
                                ),
                              ],
                            ),
                          ),
                          // Bottom Navigation
                          _buildBottomNav(),
                        ],
                      ),
                    ),
                  ),
                  _buildSideMenu(),
                ],
              ),
            );
          },
        );
      },
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
                                _menuItem(LanguageManager.instance.translate('about_us'), () {
                                  _toggleMenu();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AboutUsScreen(isConnected: _isConnected)),
                                  );
                                }),
                                _menuItem(LanguageManager.instance.translate('help'), () {
                                  _toggleMenu();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => HelpScreen(isConnected: _isConnected)),
                                  );
                                }),
                                _menuItem(LanguageManager.instance.translate('connection'), () {
                                  _toggleMenu();
                                  _onItemTapped(0);
                                }),
                                _menuItem(LanguageManager.instance.translate('settings'), () {
                                  _toggleMenu();
                                  _onItemTapped(2);
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.wifi, LanguageManager.instance.translate('connect'), 0),
            _navItem(Icons.location_on, LanguageManager.instance.translate('timeline'), 1),
            _navItem(Icons.settings, LanguageManager.instance.translate('settings'), 2),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    Color iconColor = isSelected ? Colors.white : Colors.white.withOpacity(0.5);
    
    if (index == 0) { // Connect icon
      iconColor = _isConnected ? const Color(0xFF8AFF8A) : const Color(0xFFFF8A8A);
      if (!isSelected) {
        iconColor = iconColor.withOpacity(0.7);
      }
    }

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
