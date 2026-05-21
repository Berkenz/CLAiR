import 'package:dio/dio.dart';

/// OpenStreetMap Nominatim geocoding (search + reverse).
/// See https://operations.osmfoundation.org/policies/nominatim/
class NominatimService {
  NominatimService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                headers: const {
                  'Accept': 'application/json',
                  'User-Agent': 'CLAiR-mobile/1.0',
                },
              ),
            );

  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  final Dio _dio;

  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    int limit = 6,
  }) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/search',
      queryParameters: {
        'q': q,
        'format': 'json',
        'limit': limit * 2,
        'countrycodes': 'ph',
        'addressdetails': 1,
        'dedupe': 1,
      },
    );

    final rows = response.data ?? [];
    final parsed = rows
        .whereType<Map<String, dynamic>>()
        .map(PlaceSuggestion.fromSearchJson)
        .where((s) => s.displayLabel.isNotEmpty)
        .toList();

    final filtered = filterPlaceSuggestions(parsed, q);
    final results = filtered.isNotEmpty ? filtered : parsed;
    return results.take(limit).toList();
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'jsonv2',
        'addressdetails': 1,
      },
    );

    final data = response.data;
    if (data == null) return null;

    final address = data['address'];
    if (address is Map<String, dynamic>) {
      final formatted = formatProfileLocation(address);
      if (formatted != null) return formatted;
    }

    final display = data['display_name'] as String?;
    if (display == null || display.trim().isEmpty) return null;
    return profileValueFromDisplayName(display.trim());
  }
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.displayLabel,
    required this.profileValue,
    required this.lat,
    required this.lng,
  });

  /// Full place description shown in the autocomplete list.
  final String displayLabel;

  /// Shorter city/municipality value written into the profile field.
  final String profileValue;
  final double lat;
  final double lng;

  factory PlaceSuggestion.fromSearchJson(Map<String, dynamic> json) {
    final displayName = (json['display_name'] as String? ?? '').trim();
    final address = json['address'];
    final profileValue = address is Map<String, dynamic>
        ? (formatProfileLocation(address) ??
            profileValueFromDisplayName(displayName))
        : profileValueFromDisplayName(displayName);

    return PlaceSuggestion(
      displayLabel: displayName,
      profileValue: profileValue,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lon'] as String),
    );
  }
}

/// Prefer city/municipality-style labels for the profile field.
String? formatProfileLocation(Map<String, dynamic> address) {
  final locality = address['city'] ??
      address['town'] ??
      address['municipality'] ??
      address['city_district'] ??
      address['village'] ??
      address['suburb'];

  if (locality is String && locality.trim().isNotEmpty) {
    return locality.trim();
  }

  final county = address['county'];
  if (county is String && county.trim().isNotEmpty) {
    return county.trim();
  }

  return null;
}

/// Compact value when structured address fields are missing.
String profileValueFromDisplayName(String displayName) {
  final parts = displayName
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return displayName;
  if (parts.length == 1) return parts.first;
  // e.g. "Lahug, Cebu City, Central Visayas, Philippines" → "Cebu City"
  if (parts.length >= 2) return parts[1];
  return parts.first;
}

/// Keeps suggestions whose visible text actually relates to [query].
List<PlaceSuggestion> filterPlaceSuggestions(
  List<PlaceSuggestion> suggestions,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return suggestions;

  final seen = <String>{};
  final filtered = <PlaceSuggestion>[];

  for (final s in suggestions) {
    if (!placeMatchesQuery(s, q)) continue;

    final key = s.profileValue.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);

    filtered.add(s);
  }

  return filtered;
}

bool placeMatchesQuery(PlaceSuggestion suggestion, String queryLower) {
  final display = suggestion.displayLabel.toLowerCase();
  final profile = suggestion.profileValue.toLowerCase();

  if (display.contains(queryLower) || profile.contains(queryLower)) {
    return true;
  }

  final tokens =
      queryLower.split(RegExp(r'\s+')).where((t) => t.length >= 2);
  return tokens.every(
    (token) =>
        display.contains(token) ||
        profile.contains(token) ||
        display.split(',').any((part) => part.trim().startsWith(token)),
  );
}
