import 'package:flutter_test/flutter_test.dart';
import 'package:clair/shared/utils/profile_photo_url.dart';

void main() {
  test('profilePhotoCanonicalUrl strips v param', () {
    expect(
      profilePhotoCanonicalUrl('https://cdn.example.com/u.jpg?v=111&x=1'),
      'https://cdn.example.com/u.jpg?x=1',
    );
  });

  test('profilePhotoDisplayUrl uses UTC updatedAt for bust', () {
    final updated = DateTime.utc(2026, 5, 22, 12, 0, 0);
    final url = profilePhotoDisplayUrl(
      'https://cdn.example.com/u.jpg',
      updatedAt: updated,
    );
    expect(url, 'https://cdn.example.com/u.jpg?v=${updated.millisecondsSinceEpoch}');
  });

  test('profilePhotoDisplayUrl prefers cacheVersion', () {
    final url = profilePhotoDisplayUrl(
      'https://cdn.example.com/u.jpg',
      updatedAt: DateTime.utc(2026, 1, 1),
      cacheVersion: 42,
    );
    expect(url, 'https://cdn.example.com/u.jpg?v=42');
  });
}
