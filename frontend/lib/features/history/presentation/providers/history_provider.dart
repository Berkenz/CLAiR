import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/utils/error_helpers.dart';
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
  int _searchGeneration = 0;

  Future<void> loadConversations() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      clearSearchResults: true,
      clearActiveSearchQuery: true,
      isSearchLoading: false,
    );

    try {
      final conversations = await _repository.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  /// Search titles and message bodies on the server (debounce in the UI).
  Future<void> searchConversations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    final generation = ++_searchGeneration;
    state = state.copyWith(
      activeSearchQuery: trimmed,
      isSearchLoading: true,
      clearSearchResults: true,
    );

    try {
      final results = await _repository.getConversations(query: trimmed);
      if (generation != _searchGeneration) return;
      state = state.copyWith(
        searchResults: results,
        isSearchLoading: false,
      );
    } catch (e) {
      if (generation != _searchGeneration) return;
      state = state.copyWith(
        isSearchLoading: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  void clearSearch() {
    _searchGeneration++;
    state = state.copyWith(
      activeSearchQuery: null,
      searchResults: null,
      isSearchLoading: false,
    );
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
      state = state.copyWith(error: friendlyErrorMessage(e));
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
      state = state.copyWith(error: friendlyErrorMessage(e));
    }
  }

  /// Returns `true` if the conversation was deleted on the server.
  Future<bool> deleteConversation(String id) async {
    try {
      await _repository.deleteConversation(id);
      removeConversationFromList(id);
      return true;
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
      return false;
    }
  }

  /// Updates local state after a conversation was deleted elsewhere (e.g. chat screen).
  void removeConversationFromList(String id) {
    state = state.copyWith(
      conversations: state.conversations.where((c) => c.id != id).toList(),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class HistoryState {
  final List<ConversationEntity> conversations;
  final List<ConversationEntity>? searchResults;
  final String? activeSearchQuery;
  final bool isSearchLoading;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.conversations = const [],
    this.searchResults,
    this.activeSearchQuery,
    this.isSearchLoading = false,
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<ConversationEntity>? conversations,
    List<ConversationEntity>? searchResults,
    String? activeSearchQuery,
    bool? isSearchLoading,
    bool? isLoading,
    String? error,
    bool clearSearchResults = false,
    bool clearActiveSearchQuery = false,
  }) =>
      HistoryState(
        conversations: conversations ?? this.conversations,
        searchResults:
            clearSearchResults ? null : (searchResults ?? this.searchResults),
        activeSearchQuery: clearActiveSearchQuery
            ? null
            : (activeSearchQuery ?? this.activeSearchQuery),
        isSearchLoading: isSearchLoading ?? this.isSearchLoading,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryNotifier(repository);
});
