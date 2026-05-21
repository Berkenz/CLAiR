import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final bool loading;
  final String? error;
  /// True once a fetch has finished (success, denial, or other failure).
  final bool hasFetched;
  /// User denied location — do not auto-request again until [fetchLocation(force: true)].
  final bool permissionBlocked;

  const LocationState({
    this.latitude,
    this.longitude,
    this.loading = false,
    this.error,
    this.hasFetched = false,
    this.permissionBlocked = false,
  });

  bool get hasLocation => latitude != null && longitude != null;

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? loading,
    String? error,
    bool? hasFetched,
    bool? permissionBlocked,
    bool clearError = false,
    bool clearCoords = false,
  }) =>
      LocationState(
        latitude: clearCoords ? null : (latitude ?? this.latitude),
        longitude: clearCoords ? null : (longitude ?? this.longitude),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        hasFetched: hasFetched ?? this.hasFetched,
        permissionBlocked: permissionBlocked ?? this.permissionBlocked,
      );
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  /// One-shot background fetch for shell/chat — never re-prompts after denial.
  void prefetchIfNeeded() {
    if (state.hasLocation || state.loading || state.hasFetched) return;
    fetchLocation().ignore();
  }

  /// Requests permission (if needed) then fetches the device position.
  /// Pass [force: true] when the user taps "Enable location" to try again.
  Future<bool> fetchLocation({bool force = false}) async {
    if (!force) {
      if (state.hasLocation) return true;
      if (state.loading) return false;
      if (state.hasFetched) return false;
    }

    state = state.copyWith(loading: true, clearError: true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          loading: false,
          hasFetched: true,
          error:
              'Location services are turned off. Enable them in your device settings.',
        );
        return false;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          loading: false,
          hasFetched: true,
          permissionBlocked: true,
          error: 'Location permission denied.',
        );
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          loading: false,
          hasFetched: true,
          permissionBlocked: true,
          error:
              'Location permission permanently denied. Enable it in your device settings.',
        );
        return false;
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        state = state.copyWith(
          loading: false,
          hasFetched: true,
          permissionBlocked: true,
          error: 'Location permission denied.',
        );
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
        loading: false,
        hasFetched: true,
        permissionBlocked: false,
        clearError: true,
      );
      return true;
    } on PermissionDeniedException {
      state = state.copyWith(
        loading: false,
        hasFetched: true,
        permissionBlocked: true,
        error: 'Location permission denied.',
      );
      return false;
    } on LocationServiceDisabledException {
      state = state.copyWith(
        loading: false,
        hasFetched: true,
        error:
            'Location services are turned off. Enable them in your device settings.',
      );
      return false;
    } catch (_) {
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
