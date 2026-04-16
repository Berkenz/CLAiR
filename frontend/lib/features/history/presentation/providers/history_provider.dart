import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/history/data/datasources/history_remote_datasource.dart';
import 'package:clair/features/history/data/repositories/history_repository_impl.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/domain/repositories/history_repository.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = HistoryRemoteDataSource(dio: apiClient.dio);
  return HistoryRepositoryImpl(remoteDataSource: remoteDataSource);
});

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier(this._repository) : super(const HistoryState());

  final HistoryRepository _repository;

  Future<void> loadConversations() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversations = await _repository.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> renameConversation(String id, String newTitle) async {
    try {
      final updated = await _repository.updateConversation(id, title: newTitle);
      state = state.copyWith(
        conversations: state.conversations
            .map((c) => c.id == id ? updated : c)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> togglePin(String id) async {
    final target = state.conversations.firstWhere((c) => c.id == id);
    final newPinned = !target.isPinned;
    try {
      final updated = await _repository.updateConversation(id, isPinned: newPinned);

      final preserved = target.copyWith(
        isPinned: updated.isPinned,
        title: updated.title,
      );

      final updatedList = state.conversations
          .map((c) => c.id == id ? preserved : c)
          .toList();

      state = state.copyWith(conversations: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _repository.deleteConversation(id);
      state = state.copyWith(
        conversations:
            state.conversations.where((c) => c.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class HistoryState {
  final List<ConversationEntity> conversations;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<ConversationEntity>? conversations,
    bool? isLoading,
    String? error,
  }) =>
      HistoryState(
        conversations: conversations ?? this.conversations,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryNotifier(repository);
});
