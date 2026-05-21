import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final bool loading;
  final String? error;
  /// True once a fetch has completed (successfully or not). Prevents
  /// automatic re-fetches from hammering the permission dialog repeatedly.
  final bool hasFetched;

  const LocationState({
    this.latitude,
    this.longitude,
    this.loading = false,
    this.error,
    this.hasFetched = false,
  });

  bool get hasLocation => latitude != null && longitude != null;

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? loading,
    String? error,
    bool? hasFetched,
  }) =>
      LocationState(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        loading: loading ?? this.loading,
        error: error ?? this.error,
        hasFetched: hasFetched ?? this.hasFetched,
      );
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  /// Starts a one-shot background fetch. Skips when a position is known, a
  /// fetch is in flight, or a previous attempt succeeded. Retries after a failed
  /// attempt so a later grant of location permission can still resolve coords.
  void prefetchIfNeeded() {
    if (state.hasLocation || state.loading) return;
    if (state.hasFetched && state.error == null) return;
    fetchLocation().ignore();
  }

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
            hasFetched: true,
            error: 'Location permission denied.',
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          loading: false,
          hasFetched: true,
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
        hasFetched: true,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        hasFetched: true,
        error: 'Could not get location. Please try again.',
      );
      return false;
    }
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
