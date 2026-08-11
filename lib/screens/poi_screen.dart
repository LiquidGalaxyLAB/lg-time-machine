import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/poi.dart';
import '../services/poi_service.dart';
import '../services/language_manager.dart';
import '../services/time_manager.dart';
import 'poi_detail_screen.dart';

class POIScreen extends StatefulWidget {
  final Country country;
  final bool isConnected;

  const POIScreen({
    super.key,
    required this.country,
    required this.isConnected,
  });

  @override
  State<POIScreen> createState() => _POIScreenState();
}

class _POIScreenState extends State<POIScreen> {
  List<POI> _allPois = [];
  List<POI> _filteredPois = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    POIService.clearCache();
    _loadPOIs();
    _searchController.addListener(_filterPOIs);
    LanguageManager.instance.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    LanguageManager.instance.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    POIService.clearCache();
    _loadPOIs();
  }

  Future<void> _loadPOIs() async {
    setState(() => _isLoading = true);
    try {
      final pois = await POIService().loadPOIs();
      // Use case-insensitive comparison for country matching
      final countryPois = pois
          .where(
            (poi) =>
                poi.country.toLowerCase().trim() ==
                widget.country.name.toLowerCase().trim(),
          )
          .toList();
      setState(() {
        _allPois = countryPois;
        _filteredPois = countryPois;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading POIs in screen: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterPOIs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPois = _allPois.where((poi) {
        return poi.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
              _buildHeader(context, isTablet),
              _buildSearchBar(isTablet),
              _buildCountryTitle(isTablet),
              Expanded(child: _buildPOIList(isTablet)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/Timeline/LogoApp_Menu.png',
            width: double.infinity,
            height: isTablet ? 120 : 100,
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
                      widget.isConnected
                          ? const Color(0xFF8AFF8A).withValues(alpha: 0.2)
                          : const Color(0xFFFF8A8A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        widget.isConnected
                            ? const Color(0xFF8AFF8A).withValues(alpha: 0.4)
                            : const Color(0xFFFF8A8A).withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.wifi,
                  color:
                      widget.isConnected
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

  Widget _buildSearchBar(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60.0 : 24.0,
        vertical: 10.0,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: LanguageManager.instance.translate('search_places'),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryTitle(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60.0 : 24.0,
        vertical: 10.0,
      ),
      child: Row(
        children: [
          Container(width: 3, height: isTablet ? 32 : 24, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            LanguageManager.instance.translate(widget.country.name.toLowerCase().replaceAll(' ', '_')).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOIList(bool isTablet) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_filteredPois.isEmpty) {
      return Center(
        child: Text(
          LanguageManager.instance.translate('no_places_found'),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.5,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _filteredPois.length,
        itemBuilder: (context, index) {
          return _buildPOIItem(_filteredPois[index], isTablet);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: _filteredPois.length,
      itemBuilder: (context, index) {
        return _buildPOIItem(_filteredPois[index], isTablet);
      },
    );
  }

  Widget _buildPOIItem(POI poi, bool isTablet) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageManager.instance.languageNotifier,
      builder: (context, currentLang, child) {
        return ValueListenableBuilder<double>(
          valueListenable: TimeManager.instance.timeNotifier,
          builder: (context, timeValue, child) {
            final String thumbnailPath = poi.getCurrentImage(timeValue);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => POIDetailScreen(
                          poi: poi,
                          isConnected: widget.isConnected,
                        ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: isTablet ? 0 : 20),
                decoration:
                    isTablet
                        ? BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        )
                        : null,
                padding: isTablet ? const EdgeInsets.all(10) : null,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child:
                          thumbnailPath.isNotEmpty
                              ? Image.asset(
                                thumbnailPath,
                                width: isTablet ? 120 : 100,
                                height: isTablet ? 90 : 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: isTablet ? 120 : 100,
                                    height: isTablet ? 90 : 80,
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white24,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                width: isTablet ? 120 : 100,
                                height: isTablet ? 90 : 80,
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white24,
                                ),
                              ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            poi.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            poi.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: isTablet ? 16 : 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
