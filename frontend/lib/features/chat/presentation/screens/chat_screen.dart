import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/shared/widgets/app_drawer.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _didInitialEntryJump = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBottomOnEntry();
    });
  }

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
    ref.read(chatProvider.notifier).hideDisclaimer();
    _scrollToBottom();
  }

  void _newChat() {
    ref.read(chatProvider.notifier).reset();
  }

  void _showConversationSwitcher() {
    ref.read(historyProvider.notifier).loadConversations();
    final cl = context.c;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(historyProvider);
          final currentId = ref.watch(chatProvider).conversationId;
          final cl = context.c;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            decoration: BoxDecoration(
              color: cl.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cl.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Conversations',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cl.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _newChat();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cl.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 16, color: cl.accent),
                              const SizedBox(width: 4),
                              Text(
                                'New Chat',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cl.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: cl.border, height: 1),
                if (state.isLoading && state.conversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: cl.accent),
                  )
                else if (state.conversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No conversations yet',
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: cl.textLight),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.conversations.length,
                      separatorBuilder: (_, __) => Divider(
                        color: cl.border,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      itemBuilder: (_, i) {
                        final conv = state.conversations[i];
                        final isActive = conv.id == currentId;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 2),
                          leading: Icon(
                            conv.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: isActive ? cl.accent : cl.textLight,
                          ),
                          title: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive ? cl.accent : cl.textDark,
                            ),
                          ),
                          trailing: isActive
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: cl.accent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            if (!isActive) {
                              ref.read(chatProvider.notifier).loadConversation(
                                    conv.id,
                                    title: conv.title,
                                    isPinned: conv.isPinned,
                                  );
                            }
                          },
                        );
                      },
                    ),
                  ),
                SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom + 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showActionsMenu() {
    final chatState = ref.read(chatProvider);
    final cl = context.c;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final padding = MediaQuery.of(context).padding;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay.size.width - 220,
        padding.top + 90,
        16,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cl.surface,
      elevation: 8,
      shadowColor: cl.cardShadow,
      items: [
        _popupItem(
          cl,
          chatState.conversationIsPinned
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          chatState.conversationIsPinned ? 'Unsave Chat' : 'Save Chat',
          'save',
        ),
        _popupItem(cl, Icons.share_outlined, 'Share', 'share'),
        _popupItem(cl, Icons.download_rounded, 'Download', 'download'),
        _popupItem(cl, Icons.flag_outlined, 'Report', 'report'),
        _popupItem(
            cl, Icons.balance_rounded, 'Share to Lawyer', 'lawyer'),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'save':
          ref.read(chatProvider.notifier).toggleCurrentPin();
        case 'share':
          _generatePdf();
        case 'download':
          _generatePdf();
        case 'report':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report submitted. Thank you.'),
              backgroundColor: cl.textDark,
            ),
          );
        case 'lawyer':
          ref.read(mainShellTabProvider.notifier).state = 3;
      }
    });
  }

  PopupMenuItem<String> _popupItem(
    AppColorTheme cl,
    IconData icon,
    String label,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cl.accent),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cl.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    final cl = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Generating PDF summary...'),
        backgroundColor: cl.textDark,
        duration: const Duration(seconds: 10),
      ),
    );

    final bytes = await ref.read(chatProvider.notifier).downloadPdf();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (bytes == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final title =
          ref.read(chatProvider).conversationTitle ?? 'conversation';
      final safeName =
          title.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
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

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _ensureBottomOnEntry() {
    if (_didInitialEntryJump || !mounted) return;
    final tab = ref.read(mainShellTabProvider);
    final messages = ref.read(chatProvider).messages;
    if (tab == 1 && messages.isNotEmpty) {
      _didInitialEntryJump = true;
      _jumpToBottom();
      Future.delayed(const Duration(milliseconds: 140), _jumpToBottom);
      Future.delayed(const Duration(milliseconds: 320), _jumpToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final cl = context.c;

    ref.listen<int>(mainShellTabProvider, (prev, next) {
      final currentMessages = ref.read(chatProvider).messages;
      if (next == 1 && currentMessages.isNotEmpty) {
        _jumpToBottom();
        Future.delayed(const Duration(milliseconds: 140), _jumpToBottom);
      }
    });

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
      if (prev?.conversationId != next.conversationId && next.messages.isNotEmpty) {
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 150), _jumpToBottom);
        Future.delayed(const Duration(milliseconds: 320), _jumpToBottom);
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

    return Scaffold(
      backgroundColor: cl.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ClairAppBar(
              chatTitle: chatState.conversationTitle ?? 'New Chat',
              onTitleTap: _showConversationSwitcher,
              onNewChat: _newChat,
              onActionsTap: hasConversation ? _showActionsMenu : null,
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
                      ? _buildUserMessage(msg, index)
                      : _buildAiMessage(msg, index);
                },
              ),
            ),
            if (chatState.isLoadedConversation) _buildDisclaimer(),
            _buildInputBar(chatState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessage(ChatMessageEntity message, int index) {
    final cl = context.c;
    final text = message.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cl.accent.withValues(alpha: 0.15),
                  cl.accentLight.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: cl.accent,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: cl.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                        color: cl.border.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: cl.cardShadow,
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                        height: 1.6,
                      ),
                      strong: TextStyle(
                        fontSize: 14,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                      em: TextStyle(
                        fontSize: 14,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      h3: TextStyle(
                        fontSize: 16,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      listBullet: TextStyle(
                        fontSize: 14,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                        height: 1.6,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: cl.accent.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                      ),
                      blockquotePadding:
                          const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      blockSpacing: 10,
                      code: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: cl.accent,
                        backgroundColor:
                            cl.accent.withValues(alpha: 0.06),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: cl.textDark.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cl.border),
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildActionChip(
                      Icons.copy_rounded,
                      'copy',
                      text,
                      message,
                      index,
                    ),
                    _buildActionChip(
                      Icons.thumb_up_outlined,
                      'like',
                      text,
                      message,
                      index,
                    ),
                    _buildActionChip(
                      Icons.thumb_down_outlined,
                      'dislike',
                      text,
                      message,
                      index,
                    ),
                    _buildActionChip(
                      Icons.refresh_rounded,
                      'regenerate',
                      text,
                      message,
                      index,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(ChatMessageEntity message, int index) {
    final cl = context.c;
    final text = message.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cl.accent, cl.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: cl.accentDark.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: 'Satoshi',
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionChip(
                Icons.copy_rounded,
                'copy',
                text,
                message,
                index,
              ),
              _buildActionChip(
                Icons.edit_outlined,
                'edit',
                text,
                message,
                index,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cl.accent.withValues(alpha: 0.15),
                  cl.accentLight.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: cl.accent,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cl.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cl.border.withValues(alpha: 0.6)),
            ),
            child: _TypingDots(accent: cl.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String action, String text, ChatMessageEntity message, int messageIndex) {
    final cl = context.c;
    
    Color? backgroundColor;
    Color? iconColor;
    
    if (action == 'like' && message.feedback == 'like') {
      backgroundColor = Colors.green.shade700;
      iconColor = Colors.white;
    } else if (action == 'dislike' && message.feedback == 'dislike') {
      backgroundColor = Colors.red.shade700;
      iconColor = Colors.white;
    } else {
      backgroundColor = cl.fieldBg;
      iconColor = cl.textLight;
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => _handleActionChip(action, text, message, messageIndex),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    final cl = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cl.accent.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: cl.accent.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: cl.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Start a new conversation to explore a different topic.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cl.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleActionChip(String action, String text, ChatMessageEntity message, int messageIndex) {
    final cl = context.c;

    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Copied to clipboard'),
            backgroundColor: cl.textDark,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'like':
        final newFeedback = message.feedback == 'like' ? null : 'like';
        final updatedMessage = message.copyWith(feedback: newFeedback);
        final messages = [...ref.read(chatProvider).messages];
        messages[messageIndex] = updatedMessage;
        ref.read(chatProvider.notifier).updateMessages(messages);
        break;
      case 'dislike':
        final newFeedback = message.feedback == 'dislike' ? null : 'dislike';
        final updatedMessage = message.copyWith(feedback: newFeedback);
        final messages = [...ref.read(chatProvider).messages];
        messages[messageIndex] = updatedMessage;
        ref.read(chatProvider.notifier).updateMessages(messages);
        break;
      case 'edit':
        _showEditDialog(text);
        break;
      case 'regenerate':
        _regenerateResponse();
        break;
    }
  }

  void _showEditDialog(String currentText) {
    final cl = context.c;
    final editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cl.surface,
        title: Text(
          'Edit Message',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
          ),
        ),
        content: TextField(
          controller: editController,
          maxLines: 4,
          minLines: 2,
          style: TextStyle(color: cl.textDark),
          decoration: InputDecoration(
            hintText: 'Edit your message',
            hintStyle: TextStyle(color: cl.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cl.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cl.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cl.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: cl.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final editedText = editController.text.trim();
              if (editedText.isNotEmpty && editedText != currentText) {
                // Find and replace the user message
                final messages = ref.read(chatProvider).messages;
                final messageIndex =
                    messages.indexWhere((m) => m.text == currentText && m.isUser);

                if (messageIndex != -1) {
                  final updatedMessages = [...messages];
                  updatedMessages[messageIndex] =
                      ChatMessageEntity(text: editedText, isUser: true);

                  // Keep only up to the edited message
                  ref.read(chatProvider.notifier).reset();
                  _controller.text = editedText;
                }
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                color: cl.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _regenerateResponse() {
    final chatState = ref.read(chatProvider);
    final messages = chatState.messages;

    if (messages.isEmpty) return;

    // Remove the last AI message if it exists
    final lastMessageIsAi =
        messages.isNotEmpty && !messages.last.isUser;

    if (!lastMessageIsAi) return;

    // Get the last user message
    final lastUserMessageIndex =
        messages.lastIndexWhere((m) => m.isUser);

    if (lastUserMessageIndex == -1) return;

    final lastUserMessage = messages[lastUserMessageIndex].text;

    // Remove all messages after the last user message
    final updatedMessages = messages.sublist(0, lastUserMessageIndex + 1);

    // Update state and resend
    ref.read(chatProvider.notifier).reset();
    _controller.text = lastUserMessage;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _sendMessage();
      }
    });
  }

  Widget _buildInputBar(bool isLoading) {
    final cl = context.c;
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cl.bg,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    color: cl.border,
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
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                      ),
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              required maxLength}) =>
                          null,
                      decoration: InputDecoration(
                        hintText: 'Ask anything',
                        hintStyle: TextStyle(
                          color: cl.textLight,
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                            ? cl.accent.withOpacity(0.5)
                            : cl.accent,
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
              color: cl.border,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color accent;
  const _TypingDots({required this.accent});
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _bounce(int i) {
    final t = ((_ctrl.value * 1.0) - i * 0.15) % 1.0;
    if (t < 0.4) return Curves.easeOut.transform(t / 0.4);
    if (t < 0.6) return Curves.easeIn.transform(1.0 - (t - 0.4) / 0.2);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final b = _bounce(i);
        return Container(
          margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
          child: Transform.translate(
            offset: Offset(0, -5 * b),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.35 + 0.5 * b),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
