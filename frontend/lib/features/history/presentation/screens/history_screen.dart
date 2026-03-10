import 'package:flutter/material.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class _Conversation {
  final String title;
  final String lastMessageDate;

  const _Conversation({required this.title, required this.lastMessageDate});
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<_Conversation> _conversations = [
    const _Conversation(
      title: 'Land Dispute Assistance',
      lastMessageDate: 'March 6, 2026',
    ),
    const _Conversation(
      title: 'Vehicular Accident Settlement',
      lastMessageDate: 'January 6, 2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ClairAppBar(),
        Expanded(
          child: _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildConversationCard(_conversations[index], index),
                ),
        ),
      ],
    );
  }

  Widget _buildConversationCard(_Conversation conversation, int index) {
    return GestureDetector(
      onTap: () {},
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last message: ${conversation.lastMessageDate}',
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
              onPressed: () {
                setState(() => _conversations.removeAt(index));
              },
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
        ],
      ),
    );
  }
}
