import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data passed when a user shares a conversation directly to the lawyer screen.
class ConversationSharingData {
  const ConversationSharingData({
    required this.title,
    this.conversationId,
  });

  /// Human-readable conversation title shown in the sharing banner.
  final String title;

  /// Optional history conversation ID (null = currently-active chat).
  final String? conversationId;
}

/// Set before navigating to the lawyers tab to pre-attach a conversation.
/// Clear after the booking sheet is dismissed or the user cancels.
final lawyerSharingProvider =
    StateProvider<ConversationSharingData?>((ref) => null);
