import 'package:flutter_test/flutter_test.dart';
import 'package:clair/core/services/location_service.dart';

void main() {
  test('LocationState hasLocation requires both coordinates', () {
    const withLatOnly = LocationState(latitude: 14.0);
    expect(withLatOnly.hasLocation, isFalse);

    const complete = LocationState(latitude: 14.0, longitude: 121.0);
    expect(complete.hasLocation, isTrue);
  });
}
