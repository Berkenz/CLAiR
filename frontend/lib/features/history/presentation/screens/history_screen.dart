import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/data/chat_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ClairAppBar(),
      Expanded(child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F4F5), AppColors.bg]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Conversations', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: const Offset(0, 1))]),
                child: Text('${sharedChatHistory.length} total', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMid)),
              ),
            ]),
          ),
          Expanded(
            child: sharedChatHistory.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: sharedChatHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final anim = CurvedAnimation(parent: _anim,
                          curve: Interval((i * 0.15).clamp(0.0, 0.5), ((i * 0.15) + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut));
                      return FadeTransition(opacity: anim,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                            child: _card(sharedChatHistory[i], i),
                          ));
                    },
                  ),
          ),
        ]),
      )),
    ]);
  }

  Widget _card(ChatEntry c, int i) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 4, height: 52,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(c.preview, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMid)),
          const SizedBox(height: 6),
          Text(c.date, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight)),
        ])),
        Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => setState(() => c.saved = !c.saved),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                c.saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                key: ValueKey(c.saved),
                size: 20,
                color: c.saved ? const Color(0xFFE9A020) : AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => sharedChatHistory.removeAt(i)),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textLight),
          ),
        ]),
      ]),
    );
  }

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.fieldBg, shape: BoxShape.circle),
        child: const Icon(Icons.history_rounded, size: 28, color: AppColors.textLight)),
    const SizedBox(height: 16),
    Text('No conversations yet', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    const SizedBox(height: 6),
    Text('Start a new chat to get legal assistance.', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMid)),
  ]));
}
