/// Canonical storage URL without API cache-bust query params.
String? profilePhotoCanonicalUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final uri = Uri.parse(photoUrl.trim());
  final params = Map<String, String>.from(uri.queryParameters)..remove('v');
  if (params.isEmpty) {
    return uri.replace(queryParameters: <String, String>{}).toString();
  }
  return uri.replace(queryParameters: params).toString();
}

/// Profile photos are stored at a stable path per user; append a cache-buster
/// so [Image.network] refetches after re-upload.
String? profilePhotoDisplayUrl(
  String? photoUrl, {
  DateTime? updatedAt,
  int? cacheVersion,
}) {
  final canonical = profilePhotoCanonicalUrl(photoUrl);
  if (canonical == null) return null;
  final uri = Uri.parse(canonical);
  final params = Map<String, String>.from(uri.queryParameters);
  final bust = cacheVersion ?? updatedAt?.toUtc().millisecondsSinceEpoch;
  if (bust == null) return canonical;
  params['v'] = '$bust';
  return uri.replace(queryParameters: params).toString();
}