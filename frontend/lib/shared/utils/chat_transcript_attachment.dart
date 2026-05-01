import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';

/// Formats chat messages for inclusion in lawyer appointment / report descriptions.
String buildChatTranscriptForAttachment(
  List<ChatMessageEntity> messages, {
  int maxChars = 15000,
}) {
  final buf = StringBuffer();
  for (final m in messages) {
    final role = m.isUser ? 'User' : 'CLAiR';
    buf.writeln('$role:\n${m.text}\n');
    if (buf.length > maxChars) break;
  }
  final s = buf.toString().trimRight();
  if (s.length <= maxChars) return s;
  return '${s.substring(0, maxChars)}\n…[truncated]';
}
