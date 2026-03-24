import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell.dart';
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
    ref.read(chatProvider.notifier).loadConversation(conversation.id);
    ref.read(mainShellTabProvider.notifier).state = 1;
  }

  void _deleteConversation(String id) {
    ref.read(historyProvider.notifier).deleteConversation(id);
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
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
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
            IconButton(
              onPressed: () => _confirmDelete(conversation),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.darkBrown.withOpacity(0.45),
                size: 20,
              ),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ConversationEntity conversation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
