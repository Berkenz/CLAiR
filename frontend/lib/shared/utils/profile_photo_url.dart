/// Profile photos are stored at a stable path per user; append a cache-buster
/// so [Image.network] refetches after re-upload.
String? profilePhotoDisplayUrl(
  String? photoUrl, {
  DateTime? updatedAt,
  int? cacheVersion,
}) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final uri = Uri.parse(photoUrl.trim());
  final params = Map<String, String>.from(uri.queryParameters)..remove('v');
  final bust = cacheVersion ?? updatedAt?.millisecondsSinceEpoch;
  if (bust == null) {
    return params.isEmpty ? uri.replace(queryParameters: {}).toString() : uri.replace(queryParameters: params).toString();
  }
  params['v'] = '$bust';
  return uri.replace(queryParameters: params).toString();
}
