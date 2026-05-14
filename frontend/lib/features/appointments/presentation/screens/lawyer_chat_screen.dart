import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';

class LawyerChatScreen extends StatefulWidget {
  const LawyerChatScreen({super.key, required this.appointment});

  final AppointmentEntity appointment;

  @override
  State<LawyerChatScreen> createState() => _LawyerChatScreenState();
}

class _LawyerChatScreenState extends State<LawyerChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  // Placeholder messages shown before real API integration
  final List<_ChatMsg> _messages = [
    _ChatMsg(
      text:
          'Hello! I\'ve reviewed your appointment request and I\'m ready to assist you. Please feel free to ask any questions or share additional details about your case.',
      isLawyer: true,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  bool _isTyping = false;

  AppointmentEntity get appt => widget.appointment;

  String get _lawyerInitials {
    final name = appt.displayLawyerName;
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'L';
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMsg(text: text, isLawyer: false, time: DateTime.now()));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate lawyer typing reply (placeholder)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMsg(
            text:
                'Thank you for your message. This is a placeholder response — full lawyer messaging will be enabled in a future update.',
            isLawyer: true,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: _buildAppBar(cl),
      body: Column(
        children: [
          // Case context banner
          _CaseBanner(appointment: appt),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) {
                  return _TypingBubble(initials: _lawyerInitials);
                }
                final msg = _messages[i];
                return _MessageBubble(
                  message: msg,
                  lawyerInitials: _lawyerInitials,
                );
              },
            ),
          ),

          // Coming-soon notice
          _ComingSoonNotice(),

          // Input bar
          _InputBar(
            controller: _controller,
            onSend: _sendMessage,
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
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: cl.textDark,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Lawyer avatar
          Container(
            width: 36,
            height: 36,
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
                _lawyerInitials,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: cl.accent,
                ),
              ),
            ),
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
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: cl.textMid,
                  ),
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

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.lawyerInitials});

  final _ChatMsg message;
  final String lawyerInitials;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final isLawyer = message.isLawyer;
    final timeStr =
        '${message.time.hour % 12 == 0 ? 12 : message.time.hour % 12}:${message.time.minute.toString().padLeft(2, '0')} ${message.time.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isLawyer ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isLawyer) ...[
            // Lawyer avatar
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: cl.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  lawyerInitials,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cl.accent,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isLawyer
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isLawyer ? cl.surface : cl.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isLawyer ? 4 : 16),
                      bottomRight: Radius.circular(isLawyer ? 16 : 4),
                    ),
                    border: isLawyer
                        ? Border.all(color: cl.border)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: cl.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLawyer ? cl.textDark : Colors.white,
                      fontFamily: 'Satoshi',
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: cl.textLight,
                    fontFamily: 'Satoshi',
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

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.initials});
  final String initials;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.initials,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cl.accent,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cl.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: cl.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(delay: 0),
                  SizedBox(width: 4),
                  _Dot(delay: 150),
                  SizedBox(width: 4),
                  _Dot(delay: 300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: cl.accent
              .withValues(alpha: 0.3 + (_anim.value * 0.5)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Coming soon notice ────────────────────────────────────────────────────────

class _ComingSoonNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cl.fieldBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 12, color: cl.textLight),
          const SizedBox(width: 5),
          Text(
            'Live messaging with lawyers is coming soon',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: cl.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(
          top: BorderSide(color: cl.border),
        ),
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cl.fieldBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cl.border),
                ),
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
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cl.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cl.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ChatMsg {
  const _ChatMsg({
    required this.text,
    required this.isLawyer,
    required this.time,
  });

  final String text;
  final bool isLawyer;
  final DateTime time;
}
