import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/entities/rag_source_entity.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

/// Maps API message JSON (conversation detail or chat send) to [ChatMessageEntity].
ChatMessageEntity chatMessageFromApiMap(Map<String, dynamic> map) {
  final role = map['role'] as String?;
  final isUser = role == 'user';

  final suggestedLawyers = <LawyerEntity>[];
  if (!isUser) {
    final rawLawyers = map['suggested_lawyers'] as List<dynamic>? ?? [];
    for (final e in rawLawyers) {
      if (e is Map) {
        suggestedLawyers.add(
          LawyerEntity.fromJson(Map<String, dynamic>.from(e)),
        );
      }
    }
  }

  final bool? ragEnabled = map.containsKey('rag_enabled')
      ? map['rag_enabled'] == true
      : null;
  final ragSources = <RagSourceEntity>[];
  if (!isUser) {
    final rawRag = map['rag_sources'] as List<dynamic>? ?? [];
    for (final e in rawRag) {
      if (e is Map<String, dynamic>) {
        ragSources.add(RagSourceEntity.fromJson(e));
      } else if (e is Map) {
        ragSources.add(RagSourceEntity.fromJson(Map<String, dynamic>.from(e)));
      }
    }
  }

  return ChatMessageEntity(
    id: map['id']?.toString(),
    text: map['text'] as String,
    isUser: isUser,
    lawyerReported: map['lawyer_reported'] == true,
    suggestedLawyers: suggestedLawyers,
    ragSources: ragSources,
    ragEnabled: ragEnabled,
  );
}
