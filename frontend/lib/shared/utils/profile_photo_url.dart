/// Canonical storage URL without cache-bust query params.
String? profilePhotoCanonicalUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final uri = Uri.parse(photoUrl.trim());
  final params = Map<String, String>.from(uri.queryParameters)..remove('v');
  if (params.isEmpty) {
    return uri.replace(queryParameters: <String, String>{}).toString();
  }
  return uri.replace(queryParameters: params).toString();
}

/// Cache-bust key aligned with backend `photo_url_with_cache_bust` (ms since epoch).
int? profilePhotoCacheBustKey(DateTime? updatedAt) {
  if (updatedAt == null) return null;
  return updatedAt.toUtc().millisecondsSinceEpoch;
}

/// Build display URL the same way appointment `client_photo_url` does on the backend:
/// strip any stored `?v=` and always derive it from [updatedAt] / [cacheVersion].
String? profilePhotoDisplayUrl(
  String? photoUrl, {
  DateTime? updatedAt,
  int? cacheVersion,
}) {
  final canonical = profilePhotoCanonicalUrl(photoUrl);
  if (canonical == null) return null;

  final bust = cacheVersion ?? profilePhotoCacheBustKey(updatedAt);
  if (bust == null) {
    // No timestamp (e.g. legacy row): use URL as returned by API.
    final trimmed = photoUrl?.trim();
    return trimmed != null && trimmed.isNotEmpty ? trimmed : canonical;
  }

  final uri = Uri.parse(canonical);
  final params = Map<String, String>.from(uri.queryParameters);
  params['v'] = '$bust';
  return uri.replace(queryParameters: params).toString();
}
