import 'package:geolocator/geolocator.dart';

import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

/// Matches backend chat partner radius (km).
const double kLawyerNearbyRadiusKm = 50;

const double kLawyerNearbyFallbackRadiusKm = 120;

class LawyerNearbyEntry {
  const LawyerNearbyEntry({required this.lawyer, required this.distanceKm});

  final LawyerEntity lawyer;
  final double distanceKm;
}

/// Lawyers with GPS pins, sorted nearest-first within [maxRadiusKm].
List<LawyerNearbyEntry> lawyersNearPoint({
  required List<LawyerEntity> lawyers,
  required double userLat,
  required double userLng,
  int limit = 5,
  double maxRadiusKm = kLawyerNearbyRadiusKm,
}) {
  final entries = <LawyerNearbyEntry>[];
  for (final lawyer in lawyers) {
    final lat = lawyer.latitude;
    final lng = lawyer.longitude;
    if (lat == null || lng == null) continue;
    final meters = Geolocator.distanceBetween(userLat, userLng, lat, lng);
    final km = meters / 1000.0;
    if (km <= maxRadiusKm) {
      entries.add(LawyerNearbyEntry(lawyer: lawyer, distanceKm: km));
    }
  }
  entries.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  if (entries.length >= limit) {
    return entries.take(limit).toList();
  }

  if (entries.isNotEmpty || maxRadiusKm >= kLawyerNearbyFallbackRadiusKm) {
    return entries;
  }

  return lawyersNearPoint(
    lawyers: lawyers,
    userLat: userLat,
    userLng: userLng,
    limit: limit,
    maxRadiusKm: kLawyerNearbyFallbackRadiusKm,
  );
}
