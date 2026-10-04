import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Airport {
  final String iata;
  final String name;
  final String city;
  final String country;

  const Airport({
    required this.iata,
    required this.name,
    required this.city,
    required this.country,
  });

  factory Airport.fromJson(Map<String, dynamic> json) => Airport(
        iata: json['iata'] as String,
        name: json['name'] as String,
        city: json['city'] as String,
        country: json['country'] as String,
      );

  /// Display format stored in Firestore
  String get display => '$iata - $name, $city, $country';

  @override
  String toString() => display;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Lazily-loaded airport list from bundled JSON asset (~7 000 airports)
/// ─────────────────────────────────────────────────────────────────────────────
List<Airport>? _cachedAirports;

Future<List<Airport>> loadAirports() async {
  if (_cachedAirports != null) return _cachedAirports!;
  final raw = await rootBundle.loadString('assets/airports.json');
  final List<dynamic> list = json.decode(raw);
  _cachedAirports = list.map((e) => Airport.fromJson(e)).toList();
  return _cachedAirports!;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Shared airport picker — bottom sheet with search
/// ─────────────────────────────────────────────────────────────────────────────
Future<String?> showAirportPicker(
  BuildContext context,
  ValueChanged<String> onSelected, {
  String? excludeAirport,
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AirportPickerSheet(
      onSelected: onSelected,
      excludeAirport: excludeAirport,
    ),
  );
  return result;
}

class _AirportPickerSheet extends StatefulWidget {
  final ValueChanged<String> onSelected;
  final String? excludeAirport;

  const _AirportPickerSheet({required this.onSelected, this.excludeAirport});

  @override
  State<_AirportPickerSheet> createState() => _AirportPickerSheetState();
}

class _AirportPickerSheetState extends State<_AirportPickerSheet> {
  String _query = '';
  List<Airport> _allAirports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final airports = await loadAirports();
    if (!mounted) return;
    setState(() {
      _allAirports = airports;
      _loading = false;
    });
  }

  List<Airport> get _filtered {
    final exclude = widget.excludeAirport?.trim().toLowerCase() ?? '';
    var airports = _allAirports;
    if (exclude.isNotEmpty) {
      airports =
          airports.where((a) => a.display.toLowerCase() != exclude).toList();
    }
    if (_query.trim().isEmpty) return airports;
    final q = _query.toLowerCase();
    return airports.where((a) {
      return a.iata.toLowerCase().contains(q) ||
          a.name.toLowerCase().contains(q) ||
          a.city.toLowerCase().contains(q) ||
          a.country.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Select Airport',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),

          /// Search field
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by city, airport or IATA code\u2026',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          /// Airport list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('No airports found')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final airport = filtered[i];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                airport.iata,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF3E729F),
                                ),
                              ),
                            ),
                            title: Text(
                              airport.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${airport.city}, ${airport.country}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            onTap: () {
                              widget.onSelected(airport.display);
                              Navigator.pop(context, airport.display);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
