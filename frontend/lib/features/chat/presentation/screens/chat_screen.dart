import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/shared/widgets/app_drawer.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _newChat() {
    ref.read(chatProvider.notifier).reset();
  }

  void _showRenameDialog(String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
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
              borderSide:
                  const BorderSide(color: AppColors.darkBrown, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.darkBrown, fontFamily: 'Satoshi')),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != currentTitle) {
                ref
                    .read(chatProvider.notifier)
                    .renameCurrentConversation(newTitle);
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

  void _confirmDelete() {
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
              ref.read(chatProvider.notifier).deleteCurrentConversation();
            },
            child: Text('Delete',
                style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF summary...'),
        backgroundColor: AppColors.darkBrown,
        duration: Duration(seconds: 10),
      ),
    );

    final bytes = await ref.read(chatProvider.notifier).downloadPdf();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (bytes == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final title = ref.read(chatProvider).conversationTitle ?? 'conversation';
      final safeName = title.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
      final file = File('${dir.path}/CLAiR_$safeName.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () => ref.read(chatProvider.notifier).clearError(),
            ),
          ),
        );
        ref.read(chatProvider.notifier).clearError();
      }
    });

    final hasConversation = chatState.conversationId != null;
    final user = ref.watch(currentUserProvider);
    final isRegistered = user != null && !user.isAnonymous;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ClairAppBar(
              chatTitle: chatState.conversationTitle,
              actions: [
                // New Chat button
                IconButton(
                  onPressed: _newChat,
                  tooltip: 'New chat',
                  icon: const Icon(
                    Icons.edit_square,
                    color: AppColors.darkBrown,
                    size: 22,
                  ),
                ),
                // Triple-dot menu (only when a saved conversation is open)
                if (hasConversation)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.darkBrown.withOpacity(0.7),
                      size: 22,
                    ),
                    splashRadius: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.offWhite,
                    elevation: 4,
                    onSelected: (value) {
                      switch (value) {
                        case 'pdf':
                          _generatePdf();
                          break;
                        case 'pin':
                          ref.read(chatProvider.notifier).toggleCurrentPin();
                          break;
                        case 'rename':
                          _showRenameDialog(
                              chatState.conversationTitle ?? 'Conversation');
                          break;
                        case 'delete':
                          _confirmDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (isRegistered)
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 18,
                                color: AppColors.darkBrown,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Generate PDF',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              chatState.conversationIsPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin_rounded,
                              size: 18,
                              color: AppColors.darkBrown,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              chatState.conversationIsPinned
                                  ? 'Unpin'
                                  : 'Pin',
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
                            const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.darkBrown),
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
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red.shade700),
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
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount:
                    chatState.messages.length + (chatState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatState.messages.length &&
                      chatState.isLoading) {
                    return _buildTypingIndicator();
                  }
                  final msg = chatState.messages[index];
                  return msg.isUser
                      ? _buildUserMessage(msg.text)
                      : _buildAiMessage(msg.text);
                },
              ),
            ),
            _buildInputBar(chatState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tan, width: 1),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: AppColors.darkBrown,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkBrown.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                        height: 1.5,
                      ),
                      strong: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                      em: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                        height: 1.5,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.crimson.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      blockSpacing: 10,
                      code: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppColors.crimson,
                        backgroundColor: AppColors.tan.withOpacity(0.2),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: AppColors.darkBrown.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildActionIcon(Icons.copy_rounded),
                    _buildActionIcon(Icons.thumb_up_outlined),
                    _buildActionIcon(Icons.thumb_down_outlined),
                    _buildActionIcon(Icons.refresh_rounded),
                    _buildActionIcon(Icons.more_horiz_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.darkBrown,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: 'Satoshi',
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionIcon(Icons.copy_rounded),
              _buildActionIcon(Icons.edit_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tan, width: 1),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: AppColors.darkBrown,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '...CLAiR is typing',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkBrown.withOpacity(0.45),
              fontFamily: 'Satoshi',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Icon(icon, size: 15, color: AppColors.tan),
    );
  }

  Widget _buildInputBar(bool isLoading) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.tan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: 4000,
                      enabled: !isLoading,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                      ),
                      buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                      decoration: const InputDecoration(
                        hintText: 'Ask anything',
                        hintStyle: TextStyle(
                          color: AppColors.tan,
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isLoading ? null : _sendMessage,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isLoading
                            ? AppColors.darkBrown.withOpacity(0.5)
                            : AppColors.darkBrown,
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Icon(
              Icons.mic_none_rounded,
              color: AppColors.tan,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
