import 'package:flutter_test/flutter_test.dart';
import 'package:clair/core/services/nominatim_service.dart';

void main() {
  group('formatProfileLocation', () {
    test('prefers city over county', () {
      expect(
        formatProfileLocation({
          'city': 'Cebu City',
          'state': 'Central Visayas',
          'country': 'Philippines',
        }),
        'Cebu City',
      );
    });

    test('falls back to town or municipality', () {
      expect(
        formatProfileLocation({'municipality': 'Liloan'}),
        'Liloan',
      );
    });

    test('returns null when no locality fields', () {
      expect(formatProfileLocation({'country': 'Philippines'}), isNull);
    });
  });
}