import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/appointments/data/datasources/appointment_remote_datasource.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final appointmentDataSourceProvider =
    Provider<AppointmentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentRemoteDataSource(dio: apiClient.dio);
});

const _errorUnset = Object();

class AppointmentState {
  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AppointmentEntity> appointments;
  final bool isLoading;
  final String? error;

  AppointmentState copyWith({
    List<AppointmentEntity>? appointments,
    bool? isLoading,
    Object? error = _errorUnset,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _errorUnset) ? this.error : error as String?,
    );
  }
}

class AppointmentNotifier extends StateNotifier<AppointmentState> {
  AppointmentNotifier(this._dataSource) : super(const AppointmentState());

  final AppointmentRemoteDataSource _dataSource;

  Future<void> loadAppointments({String? date, bool force = false}) async {
    if (state.isLoading && !force) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final appointments = await _dataSource.getMyAppointments(date: date);
      state = state.copyWith(
        appointments: appointments,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Future<void> cancelAppointment(
    String appointmentId, {
    required String reason,
    String? otherDetails,
  }) async {
    await _dataSource.cancelAppointment(
      appointmentId,
      reason: reason,
      otherDetails: otherDetails,
    );
  }
}

final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  final dataSource = ref.watch(appointmentDataSourceProvider);
  return AppointmentNotifier(dataSource);
});

/// Set when user opens an appointment from a notification; [AppointmentTabScreen] opens detail then clears.
final pendingAppointmentDetailIdProvider = StateProvider<String?>((ref) => null);
