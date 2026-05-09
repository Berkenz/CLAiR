import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:clair/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/repositories/chat_repository.dart';
import 'package:clair/features/history/data/datasources/history_remote_datasource.dart';
import 'package:clair/features/history/data/repositories/history_repository_impl.dart';
import 'package:clair/features/history/domain/repositories/history_repository.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = ChatRemoteDataSource(dio: apiClient.dio);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

final _historyRepoProvider = Provider<HistoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = HistoryRemoteDataSource(dio: apiClient.dio);
  return HistoryRepositoryImpl(remoteDataSource: remoteDataSource);
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._repository, this._historyRepository, this._ref)
      : super(ChatState.initial());

  final ChatRepository _repository;
  final HistoryRepository _historyRepository;
  final Ref _ref;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMessage = ChatMessageEntity(text: text.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Attach location if already available (no blocking permission request here)
    final loc = _ref.read(locationProvider);

    try {
      final response = await _repository.sendMessage(
        message: text.trim(),
        history: state.messages.where((m) => m != userMessage).toList(),
        conversationId: state.conversationId,
        userLat: loc.latitude,
        userLng: loc.longitude,
      );

      final aiMessage = ChatMessageEntity(
        text: response.reply,
        isUser: false,
        suggestedLawyers: response.suggestedLawyers,
      );
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        // Preserve existing conversationId if backend returned empty.
        conversationId: response.conversationId.isNotEmpty
            ? response.conversationId
            : state.conversationId,
        conversationTitle: response.conversationTitle.isNotEmpty
            ? response.conversationTitle
            : state.conversationTitle,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadConversation(
    String conversationId, {
    String? title,
    bool isPinned = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages =
          await _historyRepository.getConversationMessages(conversationId);
      state = state.copyWith(
        messages: messages,
        conversationId: conversationId,
        conversationTitle: title,
        conversationIsPinned: isPinned,
        isLoading: false,
        isLoadedConversation: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> renameCurrentConversation(String newTitle) async {
    final id = state.conversationId;
    if (id == null) return;
    try {
      final updated =
          await _historyRepository.updateConversation(id, title: newTitle);
      state = state.copyWith(
        conversationTitle: updated.title,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleCurrentPin() async {
    final id = state.conversationId;
    if (id == null) return;
    try {
      final updated = await _historyRepository.updateConversation(
        id,
        isPinned: !state.conversationIsPinned,
      );
      state = state.copyWith(conversationIsPinned: updated.isPinned);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCurrentConversation() async {
    final id = state.conversationId;
    if (id == null) return;
    try {
      await _historyRepository.deleteConversation(id);
      state = ChatState.initial();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Uint8List?> downloadPdf() async {
    final id = state.conversationId;
    if (id == null) return null;
    try {
      return await _historyRepository.downloadPdf(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void hideDisclaimer() {
    state = state.copyWith(isLoadedConversation: false);
  }

  void updateMessages(List<ChatMessageEntity> messages) {
    state = state.copyWith(messages: messages);
  }

  void reset() {
    state = ChatState.initial();
  }
}

class ChatState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final String? error;
  final String? conversationId;
  final String? conversationTitle;
  final bool conversationIsPinned;
  final bool isLoadedConversation;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
    this.conversationId,
    this.conversationTitle,
    this.conversationIsPinned = false,
    this.isLoadedConversation = false,
  });

  factory ChatState.initial() => const ChatState(
        messages: [
          ChatMessageEntity(
            text: "Hi! I'm CLAiR, how may I assist you today?",
            isUser: false,
          ),
        ],
        isLoading: false,
      );

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    String? error,
    String? conversationId,
    String? conversationTitle,
    bool? conversationIsPinned,
    bool? isLoadedConversation,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        conversationId: conversationId ?? this.conversationId,
        conversationTitle: conversationTitle ?? this.conversationTitle,
        conversationIsPinned:
            conversationIsPinned ?? this.conversationIsPinned,
        isLoadedConversation:
            isLoadedConversation ?? this.isLoadedConversation,
      );
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final historyRepository = ref.watch(_historyRepoProvider);
  return ChatNotifier(repository, historyRepository, ref);
});
