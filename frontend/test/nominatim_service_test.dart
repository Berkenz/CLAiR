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

  group('profileValueFromDisplayName', () {
    test('uses second segment as city when present', () {
      expect(
        profileValueFromDisplayName(
          'Lahug, Cebu City, Central Visayas, Philippines',
        ),
        'Cebu City',
      );
    });
  });

  group('filterPlaceSuggestions', () {
    final suggestions = [
      const PlaceSuggestion(
        displayLabel: 'Cebu City, Central Visayas, Philippines',
        profileValue: 'Cebu City',
        lat: 10.3,
        lng: 123.9,
      ),
      const PlaceSuggestion(
        displayLabel: 'Manila, Metro Manila, Philippines',
        profileValue: 'Manila',
        lat: 14.6,
        lng: 120.9,
      ),
    ];

    test('keeps results that match query text', () {
      final out = filterPlaceSuggestions(suggestions, 'cebu');
      expect(out, hasLength(1));
      expect(out.first.profileValue, 'Cebu City');
    });

    test('drops unrelated places', () {
      final out = filterPlaceSuggestions(suggestions, 'davao');
      expect(out, isEmpty);
    });
  });

  group('PlaceSuggestion.fromSearchJson', () {
    test('shows full display name but saves city profile value', () {
      final s = PlaceSuggestion.fromSearchJson({
        'lat': '10.31',
        'lon': '123.89',
        'display_name': 'Lahug, Cebu City, Central Visayas, Philippines',
        'address': {
          'suburb': 'Lahug',
          'city': 'Cebu City',
          'state': 'Central Visayas',
          'country': 'Philippines',
        },
      });

      expect(s.displayLabel, contains('Lahug'));
      expect(s.profileValue, 'Cebu City');
    });
  });
}
