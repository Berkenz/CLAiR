import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class _Msg {
  final String text;
  final bool isUser;
  const _Msg(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  int _dots = 1;
  Timer? _dotTimer;
  bool _showPanel = false;
  bool _saved = false;

  final List<_Msg> _msgs = [
    const _Msg("Hi! I'm CLAiR, how may I assist you today?", false),
    const _Msg("I need assistance for a specific land dispute with my family.", true),
  ];

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); _dotTimer?.cancel(); super.dispose(); }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() { _msgs.add(_Msg(t, true)); _typing = true; });
    _ctrl.clear();
    _dots = 1;
    _dotTimer?.cancel();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dots = (_dots % 3) + 1);
    });
    _toBottom();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _dotTimer?.cancel();
      setState(() { _typing = false; _msgs.add(const _Msg(
        "I understand your concern. Land dispute cases can be complex. Could you provide more details about the specific nature of the dispute and the parties involved?", false)); });
      _toBottom();
    });
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        ClairAppBar(chatTitle: 'Land Dispute Assistance', trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _saved = !_saved),
              child: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  size: 22, color: _saved ? const Color(0xFFE9A020) : AppColors.textMid),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _showPanel = !_showPanel),
              child: Icon(_showPanel ? Icons.close_rounded : Icons.more_vert_rounded,
                  size: 20, color: AppColors.textMid),
            ),
          ],
        )),
        Expanded(child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F6F7), AppColors.bg]),
          ),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: _msgs.length + (_typing ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length && _typing) return _indicator();
              final m = _msgs[i];
              return m.isUser ? _userBubble(m.text) : _aiBubble(m.text);
            },
          ),
        )),
        _input(),
      ]),

      // right side panel
      if (_showPanel) _rightPanel(),
    ]);
  }

  Widget _rightPanel() {
    return Positioned(
      top: 0, right: 0, bottom: 0,
      child: GestureDetector(
        onTap: () {},
        child: Material(
          color: Colors.transparent,
          child: Row(children: [
            GestureDetector(onTap: () => setState(() => _showPanel = false),
                child: Container(color: Colors.black12)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.08), blurRadius: 24, offset: const Offset(-4, 0))],
              ),
              child: SafeArea(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Actions', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      GestureDetector(onTap: () => setState(() => _showPanel = false),
                          child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMid)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  _panelAction(_saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      _saved ? 'Unsave Chat' : 'Save Chat',
                      onTap: () => setState(() { _saved = !_saved; _showPanel = false; })),
                  _panelAction(Icons.share_outlined, 'Share'),
                  _panelAction(Icons.download_outlined, 'Download'),
                  _panelAction(Icons.flag_outlined, 'Report'),
                  _panelAction(Icons.lightbulb_outline_rounded, 'Suggest'),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _panelAction(IconData icon, String label, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => setState(() => _showPanel = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 34, height: 34,
                decoration: BoxDecoration(color: AppColors.fieldBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 16, color: AppColors.accent)),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ]),
        ),
      ),
    );
  }

  Widget _aiBubble(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.fieldBg, shape: BoxShape.circle),
        padding: const EdgeInsets.all(6),
        child: Image.asset('assets/images/CLAiR-icon.png', fit: BoxFit.contain,
            color: AppColors.accent, colorBlendMode: BlendMode.srcIn)),
      const SizedBox(width: 10),
      Flexible(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(t, style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, height: 1.55)),
      )),
    ]),
  );

  Widget _userBubble(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Align(alignment: Alignment.centerRight, child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(t, style: GoogleFonts.nunito(fontSize: 14, color: Colors.white, height: 1.55)),
    )),
  );

  Widget _indicator() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.fieldBg, shape: BoxShape.circle),
        padding: const EdgeInsets.all(6),
        child: Image.asset('assets/images/CLAiR-icon.png', fit: BoxFit.contain,
            color: AppColors.accent, colorBlendMode: BlendMode.srcIn)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Text('${'•' * _dots}', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 3)),
      ),
    ]),
  );

  Widget _input() {
    final bp = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bp),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.fieldBg, borderRadius: BorderRadius.circular(24)),
          child: TextField(
            controller: _ctrl, maxLines: 3, minLines: 1,
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Ask anything...', hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
              border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            onSubmitted: (_) => _send(),
          ),
        )),
        const SizedBox(width: 10),
        SpringButton(
          onTap: _send,
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18)),
        ),
      ]),
    );
  }
}
