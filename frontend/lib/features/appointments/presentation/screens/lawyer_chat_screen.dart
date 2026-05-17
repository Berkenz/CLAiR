import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/domain/entities/direct_message_entity.dart';
import 'package:clair/features/appointments/presentation/providers/direct_message_provider.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';

Widget _dmChatAvatar({
  required String initials,
  String? photoUrl,
  required AppColorTheme cl,
  double size = 36,
  double fontSize = 13,
}) {
  final trimmed = photoUrl?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _dmChatAvatarInitials(
          initials: initials,
          cl: cl,
          size: size,
          fontSize: fontSize,
        ),
      ),
    );
  }
  return _dmChatAvatarInitials(
    initials: initials,
    cl: cl,
    size: size,
    fontSize: fontSize,
  );
}

Widget _dmChatAvatarInitials({
  required String initials,
  required AppColorTheme cl,
  required double size,
  required double fontSize,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          cl.accent.withValues(alpha: 0.18),
          cl.accentLight.withValues(alpha: 0.4),
        ],
      ),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        initials,
        style: GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: cl.accent,
        ),
      ),
    ),
  );
}

class LawyerChatScreen extends ConsumerStatefulWidget {
  const LawyerChatScreen({super.key, required this.appointment});

  final AppointmentEntity appointment;

  @override
  ConsumerState<LawyerChatScreen> createState() => _LawyerChatScreenState();
}

class _LawyerChatScreenState extends ConsumerState<LawyerChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  AppointmentEntity get appt => widget.appointment;

  String get _lawyerInitials {
    final name = appt.displayLawyerName;
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'L';
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual<DirectMessageState>(
      directMessageProvider(appt.id),
      (prev, next) {
        if (!mounted) return;
        if ((prev?.messages.length ?? 0) < next.messages.length) {
          _scrollToBottom();
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(directMessageProvider(appt.id).notifier).startPolling();
      // Inbox refresh rebuilds the shell; defer one frame so DM listeners finish
      // attaching before markRead mutates notification state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(notificationInboxProvider.notifier).markReadForAppointment(appt.id);
      });
    });
  }

  @override
  void dispose() {
    ref.read(directMessageProvider(appt.id).notifier).stopPolling();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final ok = await ref
        .read(directMessageProvider(appt.id).notifier)
        .sendMessage(text);
    if (ok) _scrollToBottom();
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final mimeType = _mimeFromExtension(file.extension ?? '');

    if (!mounted) return;
    final ok = await ref
        .read(directMessageProvider(appt.id).notifier)
        .sendAttachment(
          filePath: file.path!,
          fileName: file.name,
          mimeType: mimeType,
        );
    if (ok) _scrollToBottom();
  }

  String _mimeFromExtension(String ext) {
    return switch (ext.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final chatState = ref.watch(directMessageProvider(appt.id));

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: _buildAppBar(cl),
      body: Column(
        children: [
          _CaseBanner(appointment: appt),

          // Error banner
          if (chatState.error != null)
            _ErrorBanner(
              message: chatState.error!,
              onDismiss: () =>
                  ref.read(directMessageProvider(appt.id).notifier).clearError(),
            ),

          // Message list
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? _EmptyState(lawyerName: appt.displayLawyerName)
                    : _MessageList(
                        messages: chatState.messages,
                        scrollController: _scrollController,
                        lawyerInitials: _lawyerInitials,
                        lawyerPhotoUrl: appt.lawyerPhotoUrl,
                        cl: cl,
                      ),
          ),

          // Input bar
          _InputBar(
            controller: _controller,
            isSending: chatState.isSending,
            onSend: _sendText,
            onAttach: _pickAndSendFile,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppColorTheme cl) {
    return AppBar(
      backgroundColor: cl.surface,
      foregroundColor: cl.textDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: cl.textDark),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          _dmChatAvatar(
            initials: _lawyerInitials,
            photoUrl: appt.lawyerPhotoUrl,
            cl: cl,
            size: 36,
            fontSize: 13,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.displayLawyerName,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cl.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Appointment Chat',
                  style: GoogleFonts.nunito(fontSize: 11, color: cl.textMid),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: cl.border),
      ),
    );
  }
}

// ── Case context banner ───────────────────────────────────────────────────────

class _CaseBanner extends StatelessWidget {
  const _CaseBanner({required this.appointment});
  final AppointmentEntity appointment;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: cl.accent.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: cl.accent.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 15, color: cl.accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              appointment.displayCaseTitle,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cl.accent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F9EE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Accepted',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E7E34),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF856404)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF856404),
                fontFamily: 'Satoshi',
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: Color(0xFF856404)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lawyerName});
  final String lawyerName;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: cl.textLight),
            const SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cl.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to $lawyerName to get started. You can also share documents or images related to your case.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
    required this.lawyerInitials,
    required this.lawyerPhotoUrl,
    required this.cl,
  });

  final List<DirectMessageEntity> messages;
  final ScrollController scrollController;
  final String lawyerInitials;
  final String? lawyerPhotoUrl;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final showDate = i == 0 ||
            !_sameDay(messages[i - 1].createdAt, msg.createdAt);
        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.createdAt),
            _MessageBubble(
              message: msg,
              lawyerInitials: lawyerInitials,
              lawyerPhotoUrl: lawyerPhotoUrl,
              cl: cl,
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Date divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: cl.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cl.textLight,
                fontFamily: 'Satoshi',
              ),
            ),
          ),
          Expanded(child: Divider(color: cl.border)),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.lawyerInitials,
    required this.lawyerPhotoUrl,
    required this.cl,
  });

  final DirectMessageEntity message;
  final String lawyerInitials;
  final String? lawyerPhotoUrl;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    // From the client's perspective, lawyer messages are on the left
    final isIncoming = message.isFromLawyer;
    final timeStr = DateFormat('h:mm a').format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isIncoming ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isIncoming) ...[
            _dmChatAvatar(
              initials: lawyerInitials,
              photoUrl: lawyerPhotoUrl,
              cl: cl,
              size: 30,
              fontSize: 11,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isIncoming ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isIncoming ? cl.surface : cl.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isIncoming ? 4 : 16),
                      bottomRight: Radius.circular(isIncoming ? 16 : 4),
                    ),
                    border: isIncoming ? Border.all(color: cl.border) : null,
                    boxShadow: [
                      BoxShadow(
                        color: cl.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _BubbleContent(
                    message: message,
                    isIncoming: isIncoming,
                    cl: cl,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: cl.textLight,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                    if (!isIncoming) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 12,
                        color: message.isRead
                            ? cl.accent
                            : cl.textLight,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bubble content (text + attachment) ───────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.isIncoming,
    required this.cl,
  });

  final DirectMessageEntity message;
  final bool isIncoming;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    final textColor = isIncoming ? cl.textDark : Colors.white;

    if (message.hasAttachment) {
      return _AttachmentBubble(
        message: message,
        isIncoming: isIncoming,
        textColor: textColor,
        cl: cl,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.content ?? '',
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontFamily: 'Satoshi',
          height: 1.45,
        ),
      ),
    );
  }
}

// ── Attachment bubble ─────────────────────────────────────────────────────────

class _AttachmentBubble extends StatelessWidget {
  const _AttachmentBubble({
    required this.message,
    required this.isIncoming,
    required this.textColor,
    required this.cl,
  });

  final DirectMessageEntity message;
  final bool isIncoming;
  final Color textColor;
  final AppColorTheme cl;

  Future<void> _open() async {
    final url = message.attachmentUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isImg = message.isImage;

    return GestureDetector(
      onTap: _open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImg)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                message.attachmentUrl!,
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 80,
                  color: cl.fieldBg,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image_outlined, color: cl.textLight),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 20,
                    color: isIncoming ? cl.accent : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.attachmentName ?? 'File',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Satoshi',
                        decoration: TextDecoration.underline,
                        decorationColor: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (message.content != null && message.content!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Text(
                message.content!,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontFamily: 'Satoshi',
                  height: 1.4,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(top: BorderSide(color: cl.border)),
        boxShadow: [
          BoxShadow(
            color: cl.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            GestureDetector(
              onTap: isSending ? null : onAttach,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cl.fieldBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cl.border),
                ),
                child: Icon(
                  Icons.attach_file_rounded,
                  size: 18,
                  color: isSending ? cl.textLight : cl.textMid,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  color: cl.textDark,
                  fontFamily: 'Satoshi',
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: cl.textLight,
                    fontFamily: 'Satoshi',
                  ),
                  filled: true,
                  fillColor: cl.fieldBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cl.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cl.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cl.accent, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: isSending ? null : onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSending ? cl.textLight : cl.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isSending)
                      BoxShadow(
                        color: cl.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
