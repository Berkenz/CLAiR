import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(historyProvider.notifier).loadConversations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next == 2) {
        ref.read(historyProvider.notifier).loadConversations();
      }
    });

    final state = ref.watch(historyProvider);

    ref.listen<HistoryState>(historyProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(historyProvider.notifier).clearError();
      }
    });

    return Column(
      children: [
        const ClairAppBar(),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  void _openConversation(ConversationEntity conversation) {
    ref.read(chatProvider.notifier).loadConversation(
          conversation.id,
          title: conversation.title,
          isPinned: conversation.isPinned,
        );
    ref.read(mainShellTabProvider.notifier).state = 1;
  }

  void _deleteConversation(String id) {
    ref.read(historyProvider.notifier).deleteConversation(id);
  }

  void _togglePin(String id) {
    ref.read(historyProvider.notifier).togglePin(id);
  }

  Widget _buildBody(HistoryState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkBrown),
      );
    }

    if (state.conversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.darkBrown,
      onRefresh: () => ref.read(historyProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: state.conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildConversationCard(state.conversations[index]),
      ),
    );
  }

  Widget _buildConversationCard(ConversationEntity conversation) {
    final dateStr = _formatDate(conversation.updatedAt ?? conversation.createdAt);

    return GestureDetector(
      onTap: () => _openConversation(conversation),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 4, 16),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBrown.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (conversation.isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 16,
                  color: AppColors.darkBrown.withOpacity(0.5),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                      fontFamily: 'Satoshi',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last message: $dateStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkBrown.withOpacity(0.45),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.darkBrown.withOpacity(0.45),
                size: 20,
              ),
              splashRadius: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.offWhite,
              elevation: 4,
              onSelected: (value) {
                switch (value) {
                  case 'pin':
                    _togglePin(conversation.id);
                    break;
                  case 'rename':
                    _showRenameDialog(conversation);
                    break;
                  case 'delete':
                    _confirmDelete(conversation);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                        conversation.isPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        size: 18,
                        color: AppColors.darkBrown,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        conversation.isPinned ? 'Unpin' : 'Pin',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.darkBrown,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Rename',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(ConversationEntity conversation) {
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename conversation',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: const TextStyle(fontFamily: 'Satoshi'),
          decoration: InputDecoration(
            hintText: 'Enter new title',
            hintStyle: TextStyle(
              fontFamily: 'Satoshi',
              color: AppColors.darkBrown.withOpacity(0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBrown, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkBrown, fontFamily: 'Satoshi')),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                ref.read(historyProvider.notifier).renameConversation(
                      conversation.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename',
                style: TextStyle(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ConversationEntity conversation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete conversation?',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will permanently delete this conversation and all its messages.',
          style: TextStyle(fontFamily: 'Satoshi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkBrown)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteConversation(conversation.id);
            },
            child: Text('Delete',
                style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.tan.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkBrown.withOpacity(0.4),
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat and your conversations will appear here',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkBrown.withOpacity(0.3),
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMMM d, y').format(date);
  }
}
