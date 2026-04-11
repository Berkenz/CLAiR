import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/data/chat_history.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<ChatEntry> get _saved => sharedChatHistory.where((c) => c.saved).toList();

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return Column(children: [
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
              Text('Saved Chats', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: const Offset(0, 1))]),
                child: Text('${saved.length} saved', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMid)),
              ),
            ]),
          ),
          Expanded(
            child: saved.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(saved[i]),
                  ),
          ),
        ]),
      )),
    ]);
  }

  Widget _card(ChatEntry c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(width: 4, height: 52,
          decoration: BoxDecoration(color: const Color(0xFFE9A020), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text(c.preview, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMid)),
        const SizedBox(height: 6),
        Text(c.date, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight)),
      ])),
      GestureDetector(
        onTap: () => setState(() => c.saved = false),
        child: const Icon(Icons.bookmark_rounded, size: 20, color: Color(0xFFE9A020)),
      ),
    ]),
  );

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.fieldBg, shape: BoxShape.circle),
        child: const Icon(Icons.bookmark_outline_rounded, size: 28, color: AppColors.textLight)),
    const SizedBox(height: 16),
    Text('No saved chats', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    const SizedBox(height: 6),
    Text('Bookmark chats to find them easily later.', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMid)),
  ]));
}
