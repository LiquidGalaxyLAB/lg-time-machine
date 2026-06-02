import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/country.dart';
import '../services/language_manager.dart';
import '../services/time_manager.dart';
import 'poi_screen.dart';

class TimelineScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  final bool isConnected;
  final VoidCallback onMenuToggle;

  const TimelineScreen({
    super.key,
    this.onTabChange,
    required this.isConnected,
    required this.onMenuToggle,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await DatabaseHelper.instance.getAllCountries();
    setState(() {
      _countries = countries;
      _filteredCountries = countries;
    });
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = _countries.where((country) {
        return country.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageManager.instance.languageNotifier,
      builder: (context, lang, child) {
        return Column(
          children: [
            // Search bar and Menu button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onMenuToggle,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha:0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: LanguageManager.instance.translate(
                          'search_countries',
                        ),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha:0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha:0.6),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha:0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha:0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha:0.2),
                          ),
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
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                    ),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withValues(alpha:0.2),
                        child: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      title: Text(
                        country.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => POIScreen(
                              country: country,
                              isConnected: widget.isConnected,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            // Timeline Slider
            ValueListenableBuilder<double>(
              valueListenable: TimeManager.instance.timeNotifier,
              builder: (context, timeValue, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  margin: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 5.0,
                    top: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withValues(alpha:0.1)),
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
                          inactiveTrackColor: Colors.white.withValues(alpha:0.2),
                          trackHeight: 4.0,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10.0,
                          ),
                          overlayColor: Colors.cyanAccent.withValues(alpha:0.3),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 20.0,
                          ),
                          tickMarkShape: const RoundSliderTickMarkShape(),
                          activeTickMarkColor: Colors.cyanAccent,
                          inactiveTickMarkColor: Colors.white.withValues(alpha:0.3),
                        ),
                        child: Container(
                          height: 35,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha:0.3),
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
            ),
          ],
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
              ? Colors.cyanAccent.withValues(alpha:0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent.withValues(alpha:0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha:0.5),
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
