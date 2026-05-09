import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

class ChatResponseEntity {
  final String reply;
  final String conversationId;
  final String conversationTitle;
  final List<LawyerEntity> suggestedLawyers;

  const ChatResponseEntity({
    required this.reply,
    required this.conversationId,
    required this.conversationTitle,
    this.suggestedLawyers = const [],
  });
}
