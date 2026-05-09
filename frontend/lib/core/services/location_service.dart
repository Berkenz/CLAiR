import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final bool loading;
  final String? error;

  const LocationState({
    this.latitude,
    this.longitude,
    this.loading = false,
    this.error,
  });

  bool get hasLocation => latitude != null && longitude != null;

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? loading,
    String? error,
  }) =>
      LocationState(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        loading: loading ?? this.loading,
        error: error ?? this.error,
      );
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  /// Requests permission (if needed) then fetches the device position.
  /// Returns true if a position was obtained.
  Future<bool> fetchLocation() async {
    state = state.copyWith(loading: true, error: null);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            loading: false,
            error: 'Location permission denied.',
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          loading: false,
          error:
              'Location permission permanently denied. Enable it in your device settings.',
        );
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
        loading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Could not get location. Please try again.',
      );
      return false;
    }
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
