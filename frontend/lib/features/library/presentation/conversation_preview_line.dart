import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/l10n/app_localizations.dart';

/// Structured preview for a conversation list row (localized when formatted).
class ConversationPreviewLine {
  final bool isEmpty;
  final bool isUser;
  final String snippet;

  const ConversationPreviewLine.empty()
      : isEmpty = true,
        isUser = false,
        snippet = '';

  ConversationPreviewLine.message({
    required this.isUser,
    required String snippet,
  })  : isEmpty = false,
        snippet = snippet.trim().isNotEmpty ? snippet.trim() : '...';

  factory ConversationPreviewLine.fromMessages(List<ChatMessageEntity> messages) {
    if (messages.isEmpty) return const ConversationPreviewLine.empty();
    final latest = messages.last;
    return ConversationPreviewLine.message(
      isUser: latest.isUser,
      snippet: latest.text,
    );
  }
}

String formatConversationPreviewLine(
  ConversationPreviewLine line,
  AppLocalizations l,
) {
  if (line.isEmpty) return l.libPreviewEmpty;
  final author = line.isUser ? l.libPreviewYou : 'CLAiR';
  return '$author: ${line.snippet}';
}

/// When full message list is unavailable, uses [ConversationEntity.lastMessage].
String conversationListFallbackPreview(String? lastMessage, AppLocalizations l) {
  final t = lastMessage?.trim();
  if (t != null && t.isNotEmpty) return l.libPreviewRecent(t);
  return l.libPreviewEmpty;
}
