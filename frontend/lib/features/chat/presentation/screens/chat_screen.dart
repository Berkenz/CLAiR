import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:go_router/go_router.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/dialogs/guest_auth_prompt.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/utils/guest_chat_reset.dart';
import 'package:clair/features/chat/domain/entities/rag_source_entity.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/chat/utils/chat_markdown_format.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/chat/presentation/widgets/message_report_sheet.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_sharing_provider.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_overview_screen.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_display_avatar.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/app_drawer.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _lastMsgKey = GlobalKey();
  bool _didInitialEntryJump = false;
  bool _showScrollToBottom = false;
  bool _guestEphemeralBannerDismissed = false;

  // Voice
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  // Attachment
  File? _attachedFile;
  String? _attachedFileName;
  bool _isExtractingFile = false;

  static const _kScrollThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBottomOnEntry();
      _refreshLawyerReportFlagsIfNeeded();
      ref.read(locationProvider.notifier).prefetchIfNeeded();
    });
    _initSpeech();
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (mounted && status == SpeechToText.doneStatus) {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Speech recognition not available on this device.'),
          backgroundColor: context.c.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
              if (result.finalResult) _isListening = false;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFile = File(result.files.single.path!);
        _attachedFileName = result.files.single.name;
      });
    }
  }

  void _refreshLawyerReportFlagsIfNeeded() {
    final id = ref.read(chatProvider).conversationId;
    if (id != null) {
      ref.read(chatProvider.notifier).refreshLawyerReportFlags();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLawyerReportFlagsIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final distFromBottom = pos.maxScrollExtent - pos.pixels;
    final shouldShow = distFromBottom > _kScrollThreshold;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _hardScrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final file = _attachedFile;
    final fileName = _attachedFileName;
    if (text.isEmpty && file == null) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    if (file != null) {
      setState(() => _isExtractingFile = true);
      try {
        final repo = ref.read(chatRepositoryProvider);
        final extractedText = await repo.extractFileText(file);
        if (!mounted) return;
        final header = '📄 **$fileName**\n\n$extractedText';
        final fullMessage =
            text.isNotEmpty ? '$header\n\n---\n\n$text' : header;
        _controller.clear();
        setState(() {
          _attachedFile = null;
          _attachedFileName = null;
          _isExtractingFile = false;
        });
        ref.read(chatProvider.notifier).sendMessage(fullMessage);
        ref.read(chatProvider.notifier).hideDisclaimer();
        _scrollToLastMessage();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isExtractingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    ref.read(chatProvider.notifier).hideDisclaimer();
    _scrollToLastMessage();
  }

  Future<void> _newChat() async {
    await resetChatWithGuestGuard(context: context, ref: ref);
  }

  void _showConversationSwitcher() {
    ref.read(historyProvider.notifier).loadConversations();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(historyProvider);
          final currentId = ref.watch(chatProvider).conversationId;
          final isGuest = ref.watch(currentUserProvider)?.isAnonymous == true;
          final cl = context.c;
          final l10n = AppLocalizations.of(context)!;

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
                        l10n.chatConversationsTitle,
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
                                l10n.chatNewChatButton,
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
                      isGuest
                          ? l10n.chatGuestNoSavedChats
                          : l10n.chatNoConversationsYet,
                      textAlign: TextAlign.center,
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
    final isGuest = ref.read(currentUserProvider)?.isAnonymous == true;
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final padding = MediaQuery.of(context).padding;

    final menuItems = <PopupMenuEntry<String>>[];
    if (!isGuest) {
      menuItems.addAll([
        _popupItem(
          cl,
          chatState.conversationIsPinned
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          chatState.conversationIsPinned
              ? l10n.chatMenuUnsaveChat
              : l10n.chatMenuSaveChat,
          'save',
        ),
        _popupItem(
            cl, Icons.download_rounded, l10n.chatMenuDownloadPdf, 'download'),
        _popupItem(
            cl, Icons.balance_rounded, l10n.chatMenuShareToLawyer, 'lawyer'),
      ]);
    }
    menuItems.add(
      _popupItem(cl, Icons.flag_outlined, l10n.chatMenuReport, 'report'),
    );
    if (!isGuest && chatState.conversationId != null) {
      menuItems.add(
        _popupItemDestructive(
          cl,
          Icons.delete_outline_rounded,
          l10n.chatMenuDelete,
          'delete',
        ),
      );
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay.size.width - 220,
        padding.top + 90,
        16,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cl.textDark.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      // Slightly off the chat canvas (cl.surface) so the menu reads as a floating card.
      color: cl.fieldBg,
      elevation: 22,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      items: menuItems,
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'save':
          ref.read(chatProvider.notifier).toggleCurrentPin();
        case 'download':
          _generatePdf();
        case 'report':
          context.push('/report');
        case 'lawyer':
          final chatState = ref.read(chatProvider);
          ref.read(lawyerSharingProvider.notifier).state =
              ConversationSharingData(
            title: chatState.conversationTitle ?? l10n.chatTitleCurrentConversation,
            conversationId: chatState.conversationId,
          );
          ref.read(mainShellTabProvider.notifier).state = 3;
        case 'delete':
          _confirmDeleteConversation();
      }
    });
  }

  void _confirmDeleteConversation() {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.histDeleteTitle,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cl.textDark,
          ),
        ),
        content: Text(
          l10n.histDeleteBody,
          style: GoogleFonts.nunito(
            fontSize: 14,
            height: 1.4,
            color: cl.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.commonCancel,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: cl.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).deleteCurrentConversation();
            },
            child: Text(
              l10n.commonDelete,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItemDestructive(
    AppColorTheme cl,
    IconData icon,
    String label,
    String value,
  ) {
    final red = Colors.red.shade700;
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: red),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: red,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
    AppColorTheme cl,
    IconData icon,
    String label,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.chatPdfGeneratingSummary),
        backgroundColor: cl.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: Text(l10n.chatPdfSaveFailed(friendlyErrorMessage(e))),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _scrollToLastMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _lastMsgKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _jumpToLastMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _lastMsgKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: Duration.zero,
        );
      }
    });
  }

  void _ensureBottomOnEntry() {
    if (_didInitialEntryJump || !mounted) return;
    final tab = ref.read(mainShellTabProvider);
    final messages = ref.read(chatProvider).messages;
    if (tab == 1 && messages.isNotEmpty) {
      _didInitialEntryJump = true;
      _jumpToLastMessage();
      Future.delayed(const Duration(milliseconds: 140), _jumpToLastMessage);
      Future.delayed(const Duration(milliseconds: 320), _jumpToLastMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isGuest = ref.watch(currentUserProvider)?.isAnonymous == true;
    final hasUserMessages = chatState.messages.any((m) => m.isUser);
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    ref.listen<int>(mainShellTabProvider, (prev, next) {
      final currentMessages = ref.read(chatProvider).messages;
      if (next == 1) {
        _refreshLawyerReportFlagsIfNeeded();
        if (currentMessages.isNotEmpty) {
          _jumpToLastMessage();
          Future.delayed(const Duration(milliseconds: 140), _jumpToLastMessage);
        }
      }
    });

    ref.listen<ChatState>(chatProvider, (prev, next) {
      final hadUserMessages =
          prev?.messages.any((m) => m.isUser) ?? false;
      final hasUserMessagesNow = next.messages.any((m) => m.isUser);
      if (hadUserMessages && !hasUserMessagesNow) {
        _guestEphemeralBannerDismissed = false;
      }

      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToLastMessage();
      }
      if (prev?.conversationId != next.conversationId && next.messages.isNotEmpty) {
        _scrollToLastMessage();
        Future.delayed(const Duration(milliseconds: 150), _jumpToLastMessage);
        Future.delayed(const Duration(milliseconds: 320), _jumpToLastMessage);
      }
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: l10n.chatDisclaimerDismiss,
              textColor: Colors.white,
              onPressed: () => ref.read(chatProvider.notifier).clearError(),
            ),
          ),
        );
        ref.read(chatProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: cl.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ClairAppBar(
              chatTitle: chatState.conversationTitle ?? l10n.chatTitleNewChat,
              onTitleTap: _showConversationSwitcher,
              onNewChat: _newChat,
              onDownloadTap: ref.watch(currentUserProvider)?.isAnonymous == true
                  ? null
                  : _generatePdf,
              downloadTooltip: l10n.chatMenuDownloadPdf,
              onActionsTap: _showActionsMenu,
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      chatState.isLoadedConversation ? 120 : 88,
                    ),
                    itemCount:
                        chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      final totalItems = chatState.messages.length +
                          (chatState.isLoading ? 1 : 0);
                      final isLast = index == totalItems - 1;

                      if (index == chatState.messages.length &&
                          chatState.isLoading) {
                        return KeyedSubtree(
                          key: isLast ? _lastMsgKey : null,
                          child: _buildTypingIndicator(),
                        );
                      }
                      final msg = chatState.messages[index];
                      final child = msg.isUser
                          ? _buildUserMessage(msg, index)
                          : _buildAiMessage(msg, index);
                      return isLast
                          ? KeyedSubtree(key: _lastMsgKey, child: child)
                          : child;
                    },
                  ),
                  // ── Scroll-to-bottom FAB ───────────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    bottom: _showScrollToBottom ? 12 : -52,
                    right: 16,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showScrollToBottom ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _hardScrollToBottom,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cl.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: cl.border),
                            boxShadow: [
                              BoxShadow(
                                color: cl.cardShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: cl.textMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (chatState.showTermsDisclaimer)
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: _buildTermsDisclaimer(),
              ),
            if (isGuest &&
                hasUserMessages &&
                !_guestEphemeralBannerDismissed)
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: _buildGuestEphemeralBanner(),
              ),
            if (chatState.isLoadedConversation)
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: _buildDisclaimer(),
              ),
            _buildInputBar(chatState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessage(ChatMessageEntity message, int index) {
    final cl = context.c;
    final text = normalizeChatMarkdown(message.text);
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
                    shrinkWrap: true,
                    styleSheet: chatMarkdownStyleSheet(cl),
                    onTapLink: (text, href, title) =>
                        _openChatLink(text, href),
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
                if (message.suggestedLawyers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SuggestedLawyersList(lawyers: message.suggestedLawyers),
                ],
                _buildRagFootnote(message),
                _buildLawyerReportedBanner(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerReportedBanner(ChatMessageEntity message) {
    if (message.isUser || !message.lawyerReported) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.flag_outlined, size: 16, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.chatLawyerReportedBanner,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  height: 1.45,
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(String raw) async {
    var target = raw.trim();
    if (target.isEmpty) return;
    if (!target.toLowerCase().contains('://')) {
      if (target.contains('.') || target.toLowerCase().startsWith('www.')) {
        target = 'https://$target';
      } else {
        return;
      }
    }
    final uri = Uri.tryParse(target);
    if (uri == null || !uri.hasScheme) return;
    // Do not gate on canLaunchUrl — on Android 11+ it returns false unless
    // AndroidManifest <queries> declares https/http VIEW intents.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openChatLink(String text, String? href) async {
    final link = (href != null && href.trim().isNotEmpty) ? href : text;
    await _openExternalUrl(link);
  }

  Future<void> _openRagSourceUrl(String url) async {
    await _openExternalUrl(url);
  }

  Widget _buildRagFootnote(ChatMessageEntity message) {
    if (message.isUser) return const SizedBox.shrink();
    final enabled = message.ragEnabled;
    if (enabled == null) return const SizedBox.shrink();
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.chatRagDisconnectedBanner,
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.orange.shade800),
        ),
      );
    }
    // Only show retrieval UI when sources were actually returned (not greetings).
    if (message.ragSources.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cl.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cl.accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books_outlined, size: 16, color: cl.accent),
                const SizedBox(width: 6),
                Text(
                  l10n.chatRetrievedForAnswer,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cl.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...message.ragSources.map((RagSourceEntity s) {
              final pct = (s.similarity * 100).clamp(0, 100).toStringAsFixed(0);
              final head = s.number?.trim().isNotEmpty == true ? s.number! : l10n.chatSourceLabel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chatMatchPercent(head, pct),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cl.accentDark,
                      ),
                    ),
                    if (s.title.trim().isNotEmpty)
                      Text(
                        s.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(fontSize: 11, color: cl.textMid),
                      ),
                    if (s.category != null && s.category!.trim().isNotEmpty)
                      Text(
                        s.category!,
                        style: GoogleFonts.nunito(fontSize: 10, color: cl.textMid),
                      ),
                    if (s.sourceUrl != null && s.sourceUrl!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: () => _openRagSourceUrl(s.sourceUrl!),
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            l10n.chatOpenSource,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cl.accent,
                              decoration: TextDecoration.underline,
                              decorationColor: cl.accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
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
              style: chatUserBubbleText(),
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

  Widget _buildTermsDisclaimer() {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isDark
            ? cl.surface.withValues(alpha: 0.95)
            : cl.fieldBg,
        border: Border(
          top: BorderSide(color: cl.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.shield_outlined,
              size: 15,
              color: cl.textMid,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: cl.textMid,
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: '${l10n.chatTermsDisclaimerBody} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('/terms'),
                      child: Text(
                        l10n.chatTermsDisclaimerTerms,
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: cl.accent,
                          height: 1.45,
                          decoration: TextDecoration.underline,
                          decorationColor: cl.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: ' ${l10n.chatTermsDisclaimerAnd} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('/privacy-policy'),
                      child: Text(
                        l10n.chatTermsDisclaimerPrivacy,
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: cl.accent,
                          height: 1.45,
                          decoration: TextDecoration.underline,
                          decorationColor: cl.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: l10n.chatTermsDisclaimerPeriod),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestEphemeralBanner() {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: cl.accent.withValues(alpha: 0.08),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: cl.accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.lock_outline_rounded,
                  size: 16, color: cl.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chatGuestEphemeralBanner,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cl.textMid,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => showGuestAuthPrompt(
                      context,
                      title: l10n.guestUpgradeTitle,
                      message: l10n.guestUpgradeMessage,
                    ),
                    child: Text(
                      l10n.chatGuestSignInAction,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cl.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: cl.accent.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  setState(() => _guestEphemeralBannerDismissed = true),
              icon: Icon(Icons.close_rounded, size: 18, color: cl.textLight),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              tooltip: l10n.chatDisclaimerDismiss,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
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
              l10n.chatEmptyExploreTopic,
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
    switch (action) {
      case 'copy':
        final cl = context.c;
        final l10n = AppLocalizations.of(context)!;
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatCopiedClipboard),
            backgroundColor: cl.textDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'like':
        final toggleOff = message.feedback == 'like';
        final updatedMessage = toggleOff
            ? message.copyWith(clearFeedback: true)
            : message.copyWith(feedback: 'like');
        final messages = [...ref.read(chatProvider).messages];
        messages[messageIndex] = updatedMessage;
        ref.read(chatProvider.notifier).updateMessages(messages);
        break;
      case 'dislike':
        showMessageReportSheet(
          context,
          message: message,
          messageIndex: messageIndex,
        );
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
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
        backgroundColor: cl.surface,
        title: Text(
          dl.chatEditMessageTitle,
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
            hintText: dl.chatEditMessageHint,
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              dl.commonCancel,
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
                Navigator.pop(ctx);
              }
            },
            child: Text(
              dl.commonSave,
              style: GoogleFonts.nunito(
                color: cl.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
      },
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

    messages.sublist(0, lastUserMessageIndex + 1);

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
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final isBusy = isLoading || _isExtractingFile;
    final hasContent =
        _controller.text.trim().isNotEmpty || _attachedFile != null;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Attachment chip ──────────────────────────────────────────────
          if (_attachedFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cl.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cl.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file_outlined,
                        size: 14, color: cl.accent),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.55,
                      ),
                      child: Text(
                        _attachedFileName ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cl.accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() {
                        _attachedFile = null;
                        _attachedFileName = null;
                      }),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: cl.textLight),
                    ),
                  ],
                ),
              ),
            ),
          // ── Extracting indicator ─────────────────────────────────────────
          if (_isExtractingFile)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: cl.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reading file…',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cl.accent,
                    ),
                  ),
                ],
              ),
            ),
          // ── Listening indicator ──────────────────────────────────────────
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 6),
                  Text(
                    'Listening…',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          // ── Input row ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cl.bg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: GestureDetector(
                    onTap: isBusy ? null : _pickAttachment,
                    child: Icon(
                      Icons.attach_file_rounded,
                      color:
                          _attachedFile != null ? cl.accent : cl.textLight,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    maxLength: 4000,
                    enabled: !isBusy,
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
                      hintText: _isListening
                          ? 'Listening…'
                          : _isExtractingFile
                              ? 'Reading file…'
                              : l10n.chatComposerHint,
                      hintStyle: TextStyle(
                        color: _isListening
                            ? Colors.red.shade300
                            : cl.textLight,
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.fromLTRB(8, 10, 8, 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 6),
                // Mic (empty) or Send (has content / busy)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: hasContent || isBusy
                      ? GestureDetector(
                          key: const ValueKey('send'),
                          onTap: isBusy ? null : _sendMessage,
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: isBusy
                                  ? cl.accent.withOpacity(0.5)
                                  : cl.accent,
                              shape: BoxShape.circle,
                            ),
                            child: isBusy
                                ? const Padding(
                                    padding: EdgeInsets.all(9),
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
                        )
                      : GestureDetector(
                          key: const ValueKey('mic'),
                          onTap: _toggleListening,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.red.shade500
                                  : cl.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color:
                                  _isListening ? Colors.white : cl.accent,
                              size: 18,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            shape: BoxShape.circle,
          ),
        ),
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

// ── Suggested lawyer cards ────────────────────────────────────────────────────

class _SuggestedLawyersList extends StatelessWidget {
  const _SuggestedLawyersList({required this.lawyers});
  final List<LawyerEntity> lawyers;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_outlined, size: 13, color: cl.accent),
            const SizedBox(width: 5),
            Text(
              l10n.chatLawyersNearYou,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: cl.accent,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lawyers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _LawyerChip(lawyer: lawyers[i], cl: cl),
          ),
        ),
      ],
    );
  }
}

class _LawyerChip extends StatelessWidget {
  const _LawyerChip({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LawyerOverviewScreen(lawyer: lawyer),
        ),
      ),
      child: Container(
        width: 180,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cl.accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: cl.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                LawyerDisplayAvatar(
                  lawyer: lawyer,
                  size: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cl.accent.withValues(alpha: 0.14),
                        cl.accentLight.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  initialsStyle: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: cl.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lawyer.name,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (lawyer.designation != null)
              Text(
                lawyer.designation!,
                style: GoogleFonts.nunito(
                    fontSize: 10, color: cl.accent, height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              lawyer.categoryLine,
              style: GoogleFonts.nunito(
                  fontSize: 10, color: cl.textMid, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cl.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.lawyerViewProfile,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
