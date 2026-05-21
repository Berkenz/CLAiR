import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/locale/app_locale_provider.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/core/services/location_service.dart';
import 'package:clair/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:clair/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/repositories/chat_repository.dart';
import 'package:clair/features/history/data/datasources/history_remote_datasource.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/history/data/repositories/history_repository_impl.dart';
import 'package:clair/features/history/domain/repositories/history_repository.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/l10n/app_localizations.dart';
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
      : super(_freshChatForRef(_ref));

  final ChatRepository _repository;
  final HistoryRepository _historyRepository;
  final Ref _ref;
  int _loadGeneration = 0;

  static ChatState _freshChatForRef(Ref ref) {
    final locale = ref.read(appLocaleProvider);
    final greeting =
        lookupAppLocalizations(locale).chatAssistantGreeting;
    return ChatState.freshChat(greeting);
  }

  static String _chatApiLocale(String languageCode) {
    switch (languageCode) {
      case 'fil':
      case 'ceb':
        return languageCode;
      default:
        return 'en';
    }
  }

  /// Syncs the placeholder greeting when the user changes app language (new chat only).
  void refreshStarterGreetingIfApplicable() {
    if (state.conversationId != null || state.isLoadedConversation) return;
    if (state.messages.any((m) => m.isUser)) return;

    final aiMessages =
        state.messages.where((m) => !m.isUser).toList(growable: false);
    if (aiMessages.length != 1) return;

    final locale = _ref.read(appLocaleProvider);
    final greeting =
        lookupAppLocalizations(locale).chatAssistantGreeting;
    if (aiMessages.first.text == greeting) return;

    final userMessages = state.messages.where((m) => m.isUser);
    state = state.copyWith(
      messages: [
        ChatMessageEntity(text: greeting, isUser: false),
        ...userMessages,
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final activeConversationId = state.conversationId;
    final userMessage = ChatMessageEntity(text: text.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Best-effort GPS — cap wait so chat send is not blocked on a slow fix.
    // Location is entirely optional; skip silently if a fetch is already in
    // flight, one has already completed (success or denial), or any error
    // occurs. This prevents repeated permission dialogs or error flickers.
    var loc = _ref.read(locationProvider);
    if (!loc.hasLocation && !loc.loading && !loc.hasFetched) {
      try {
        await _ref
            .read(locationProvider.notifier)
            .fetchLocation()
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // Intentionally swallowed — location is optional.
      }
      loc = _ref.read(locationProvider);
    }

    final localeCode =
        _chatApiLocale(_ref.read(appLocaleProvider).languageCode);

    try {
      final response = await _repository.sendMessage(
        message: text.trim(),
        history: state.messages.where((m) => m != userMessage).toList(),
        conversationId: activeConversationId,
        userLat: loc.latitude,
        userLng: loc.longitude,
        locale: localeCode,
      );

      var suggestedLawyers = response.suggestedLawyers;
      if (suggestedLawyers.isNotEmpty) {
        var directory = _ref.read(lawyerProvider).lawyers;
        if (directory.isEmpty) {
          try {
            await _ref.read(lawyerProvider.notifier).loadLawyers();
          } catch (_) {}
          directory = _ref.read(lawyerProvider).lawyers;
        }
        if (directory.isNotEmpty) {
          final byId = {for (final d in directory) d.id: d};
          suggestedLawyers = suggestedLawyers
              .map((l) => l.mergePhotoFrom(byId[l.id]))
              .toList();
        }
      }

      if (state.conversationId != activeConversationId) return;

      final updatedMessages = [...state.messages];
      if (updatedMessages.isNotEmpty && updatedMessages.last.isUser) {
        final last = updatedMessages.removeLast();
        updatedMessages.add(
          last.copyWith(
            id: response.userMessageId ?? last.id,
          ),
        );
      }
      updatedMessages.add(
        ChatMessageEntity(
          id: response.assistantMessageId,
          text: response.reply,
          isUser: false,
          suggestedLawyers: suggestedLawyers,
          ragSources: response.ragSources,
          ragEnabled: response.ragEnabled,
        ),
      );
      state = state.copyWith(
        messages: updatedMessages,
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
        error: friendlyErrorMessage(e),
      );
    }
  }

  /// Sync lawyer-report flags from the server into the current in-memory thread.
  Future<void> refreshLawyerReportFlags() async {
    final id = state.conversationId;
    if (id == null || state.messages.isEmpty || state.isLoading) return;

    try {
      final serverMsgs =
          await _historyRepository.getConversationMessages(id);
      if (id != state.conversationId) return;
      final reportedIds = <String>{};
      final reportedTexts = <String>{};
      for (final s in serverMsgs) {
        if (s.isUser || !s.lawyerReported) continue;
        if (s.id != null && s.id!.isNotEmpty) reportedIds.add(s.id!);
        reportedTexts.add(s.text.trim());
      }

      var changed = false;
      final merged = state.messages.map((m) {
        if (m.isUser) return m;
        final byId = m.id != null && reportedIds.contains(m.id);
        final byText = reportedTexts.contains(m.text.trim());
        if ((byId || byText) && !m.lawyerReported) {
          changed = true;
          return m.copyWith(lawyerReported: true);
        }
        return m;
      }).toList();

      if (changed) {
        state = state.copyWith(messages: merged);
      }
    } catch (_) {
      // Non-fatal — chat still works without flags.
    }
  }

  Future<void> loadConversation(
    String conversationId, {
    String? title,
    bool isPinned = false,
  }) async {
    if (_ref.read(currentUserProvider)?.isAnonymous == true) return;
    final generation = ++_loadGeneration;
    state = state.copyWith(
      isLoading: true,
      error: null,
      messages: const [],
      conversationId: conversationId,
      conversationTitle: title,
      conversationIsPinned: isPinned,
      isLoadedConversation: true,
      showTermsDisclaimer: false,
    );
    try {
      final messages =
          await _historyRepository.getConversationMessages(conversationId);
      if (generation != _loadGeneration ||
          state.conversationId != conversationId) {
        return;
      }
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        isLoading: false,
        error: friendlyErrorMessage(e),
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
      state = state.copyWith(error: friendlyErrorMessage(e));
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
      state = state.copyWith(error: friendlyErrorMessage(e));
    }
  }

  Future<void> deleteCurrentConversation() async {
    final id = state.conversationId;
    if (id == null) return;
    try {
      await _historyRepository.deleteConversation(id);
      _ref.read(historyProvider.notifier).removeConversationFromList(id);
      state = _freshChatForRef(_ref);
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
    }
  }

  Future<Uint8List?> downloadPdf() async {
    final id = state.conversationId;
    if (id == null) return null;
    try {
      return await _historyRepository.downloadPdf(id);
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void hideDisclaimer() {
    state = state.copyWith(
      isLoadedConversation: false,
      showTermsDisclaimer: false,
    );
  }

  void updateMessages(List<ChatMessageEntity> messages) {
    state = state.copyWith(messages: messages);
  }

  void reset() {
    _loadGeneration++;
    state = _freshChatForRef(_ref);
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
  /// True on every fresh/new chat session — hidden when the user sends their
  /// first message or loads a saved conversation.
  final bool showTermsDisclaimer;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
    this.conversationId,
    this.conversationTitle,
    this.conversationIsPinned = false,
    this.isLoadedConversation = false,
    this.showTermsDisclaimer = false,
  });

  factory ChatState.freshChat(String assistantGreeting) => ChatState(
        messages: [
          ChatMessageEntity(
            text: assistantGreeting,
            isUser: false,
          ),
        ],
        isLoading: false,
        showTermsDisclaimer: true,
      );

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    String? error,
    String? conversationId,
    String? conversationTitle,
    bool? conversationIsPinned,
    bool? isLoadedConversation,
    bool? showTermsDisclaimer,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        conversationId: conversationId ?? this.conversationId,
        conversationTitle: conversationTitle ?? this.conversationTitle,
        conversationIsPinned:
            conversationIsPinned ?? this.conversationIsPinned,
        showTermsDisclaimer:
            showTermsDisclaimer ?? this.showTermsDisclaimer,
        isLoadedConversation:
            isLoadedConversation ?? this.isLoadedConversation,
      );
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final historyRepository = ref.watch(_historyRepoProvider);
  final notifier = ChatNotifier(repository, historyRepository, ref);

  // ChatScreen is not always mounted (tab switcher disposes off-screen tabs), so
  // listen here to refresh the starter greeting as soon as language changes.
  ref.listen<Locale>(appLocaleProvider, (previous, next) {
    if (previous != next) {
      notifier.refreshStarterGreetingIfApplicable();
    }
  });

  return notifier;
});
