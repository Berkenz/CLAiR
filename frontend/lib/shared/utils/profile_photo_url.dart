/// Profile photos are stored at a stable path per user; append a cache-buster
/// so [Image.network] refetches after re-upload.
String? profilePhotoDisplayUrl(
  String? photoUrl, {
  DateTime? updatedAt,
  int? cacheVersion,
}) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final bust = cacheVersion ?? updatedAt?.millisecondsSinceEpoch;
  if (bust == null) return photoUrl;
  final uri = Uri.parse(photoUrl);
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'v': '$bust',
  }).toString();
}
