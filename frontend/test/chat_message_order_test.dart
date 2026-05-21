import 'package:flutter_test/flutter_test.dart';
import 'package:clair/features/chat/data/mappers/chat_message_mapper.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';

void main() {
  test('orders by created_at with user before assistant on ties', () {
    final t = DateTime.utc(2026, 1, 1, 12);
    final messages = [
      ChatMessageEntity(
        id: 'b',
        text: 'assistant late tie',
        isUser: false,
        createdAt: t,
      ),
      ChatMessageEntity(
        id: 'a',
        text: 'user tie',
        isUser: true,
        createdAt: t,
      ),
      ChatMessageEntity(
        id: 'c',
        text: 'user earlier',
        isUser: true,
        createdAt: t.subtract(const Duration(seconds: 1)),
      ),
    ];

    final ordered = orderChatMessages(messages);
    expect(ordered.map((m) => m.text).toList(), [
      'user earlier',
      'user tie',
      'assistant late tie',
    ]);
  });
}
