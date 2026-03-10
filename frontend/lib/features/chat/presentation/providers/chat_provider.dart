import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:clair/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/repositories/chat_repository.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = ChatRemoteDataSource(dio: apiClient.dio);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._repository) : super(ChatState.initial());

  final ChatRepository _repository;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMessage = ChatMessageEntity(text: text.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final reply = await _repository.sendMessage(
        message: text.trim(),
        history: state.messages.where((m) => m != userMessage).toList(),
      );

      final aiMessage = ChatMessageEntity(text: reply, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = ChatState.initial();
  }
}

class ChatState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
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
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});
