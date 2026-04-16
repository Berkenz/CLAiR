import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/lawyer/data/datasources/lawyer_remote_datasource.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final lawyerDataSourceProvider = Provider<LawyerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LawyerRemoteDataSource(dio: apiClient.dio);
});

class LawyerState {
  final List<LawyerEntity> lawyers;
  final bool isLoading;
  final String? error;

  const LawyerState({
    this.lawyers = const [],
    this.isLoading = false,
    this.error,
  });

  LawyerState copyWith({
    List<LawyerEntity>? lawyers,
    bool? isLoading,
    String? error,
  }) =>
      LawyerState(
        lawyers: lawyers ?? this.lawyers,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class LawyerNotifier extends StateNotifier<LawyerState> {
  LawyerNotifier(this._dataSource) : super(const LawyerState());

  final LawyerRemoteDataSource _dataSource;

  Future<void> loadLawyers() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final lawyers = await _dataSource.getLawyers();
      state = state.copyWith(lawyers: lawyers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final lawyerProvider = StateNotifierProvider<LawyerNotifier, LawyerState>((ref) {
  final dataSource = ref.watch(lawyerDataSourceProvider);
  return LawyerNotifier(dataSource);
});
