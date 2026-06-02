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
    _loadPOIs();
    _searchController.addListener(_filterPOIs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              _buildSearchBar(),
              _buildCountryTitle(),
              Expanded(child: _buildPOIList()),
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
            height: 100,
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
                    color: Colors.white.withValues(alpha:0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha:0.2)),
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
                  color: widget.isConnected
                      ? const Color(0xFF8AFF8A).withValues(alpha:0.2)
                      : const Color(0xFFFF8A8A).withValues(alpha:0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isConnected
                        ? const Color(0xFF8AFF8A).withValues(alpha:0.4)
                        : const Color(0xFFFF8A8A).withValues(alpha:0.4),
                  ),
                ),
                child: Icon(
                  Icons.wifi,
                  color: widget.isConnected
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search places...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha:0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withValues(alpha:0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withValues(alpha:0.1)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCountryTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        children: [
          Container(width: 3, height: 24, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            widget.country.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOIList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_filteredPois.isEmpty) {
      return Center(
        child: Text(
          'No places found',
          style: TextStyle(color: Colors.white.withValues(alpha:0.5)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: _filteredPois.length,
      itemBuilder: (context, index) {
        final poi = _filteredPois[index];

        return ValueListenableBuilder<String>(
          valueListenable: LanguageManager.instance.languageNotifier,
          builder: (context, currentLang, child) {
            return ValueListenableBuilder<double>(
              valueListenable: TimeManager.instance.timeNotifier,
              builder: (context, timeValue, child) {
                String thumbnailPath = '';

                if (timeValue == 0) {
                  // Past
                  thumbnailPath = poi.pastImages.isNotEmpty
                      ? poi.pastImages.first
                      : (poi.presentImages.isNotEmpty
                            ? poi.presentImages.first
                            : '');
                } else {
                  // present (1.0) or future (2.0)
                  thumbnailPath = poi.presentImages.isNotEmpty
                      ? poi.presentImages.first
                      : (poi.pastImages.isNotEmpty ? poi.pastImages.first : '');
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => POIDetailScreen(
                          poi: poi,
                          isConnected: widget.isConnected,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: thumbnailPath.isNotEmpty
                              ? Image.asset(
                                  thumbnailPath,
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Error loading image asset: $thumbnailPath',
                                    );
                                    return Container(
                                      width: 100,
                                      height: 80,
                                      color: Colors.white10,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white24,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 100,
                                  height: 80,
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
                            children: [
                              Text(
                                poi.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                poi.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha:0.6),
                                  fontSize: 14,
                                ),
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
      },
    );
  }
}
