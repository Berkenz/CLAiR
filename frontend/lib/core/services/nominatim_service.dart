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
    double? nearLat,
    double? nearLng,
    int limit = 5,
  }) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final params = <String, dynamic>{
      'q': q,
      'format': 'json',
      'limit': limit,
      'countrycodes': 'ph',
      'addressdetails': 1,
    };

    if (nearLat != null && nearLng != null) {
      // Bias results toward the user's area (~0.5° box).
      const delta = 0.5;
      final left = nearLng - delta;
      final right = nearLng + delta;
      final top = nearLat + delta;
      final bottom = nearLat - delta;
      params['viewbox'] = '$left,$top,$right,$bottom';
      params['bounded'] = 0;
    }

    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/search',
      queryParameters: params,
    );

    final rows = response.data ?? [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PlaceSuggestion.fromSearchJson)
        .where((s) => s.label.isNotEmpty)
        .toList();
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
    return display?.trim().isNotEmpty == true ? display!.trim() : null;
  }
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  factory PlaceSuggestion.fromSearchJson(Map<String, dynamic> json) {
    final address = json['address'];
    final label = address is Map<String, dynamic>
        ? (formatProfileLocation(address) ??
            (json['display_name'] as String? ?? '').trim())
        : (json['display_name'] as String? ?? '').trim();

    return PlaceSuggestion(
      label: label,
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
