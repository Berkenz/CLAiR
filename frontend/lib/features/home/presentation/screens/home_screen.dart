import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class _Lawyer {
  final String name, specialty, initials;
  final double rating;
  final int cases;
  const _Lawyer({required this.name, required this.specialty, required this.rating,
      required this.cases, required this.initials});
}

class _Document {
  final String name, date, size;
  const _Document({required this.name, required this.date, required this.size});
}

const _lawyers = [
  _Lawyer(name: 'Atty. Maria Santos', specialty: 'Family Law', rating: 4.8, cases: 142, initials: 'MS'),
  _Lawyer(name: 'Atty. Juan Reyes', specialty: 'Property Law', rating: 4.6, cases: 98, initials: 'JR'),
];

const _documents = [
  _Document(name: 'Land Dispute Petition.pdf', date: 'Mar 6, 2026', size: '184 KB'),
  _Document(name: 'Affidavit of Ownership.pdf', date: 'Feb 20, 2026', size: '96 KB'),
  _Document(name: 'Settlement Agreement.pdf', date: 'Jan 10, 2026', size: '212 KB'),
];

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction(this.icon, this.label, this.color);
}

final _quickActions = [
  _QuickAction(Icons.chat_bubble_outline_rounded, 'Chat', AppColors.accent),
  _QuickAction(Icons.balance_rounded, 'Lawyers', const Color(0xFF6B8A7A)),
  _QuickAction(Icons.description_outlined, 'Cases', const Color(0xFF7A7A8B)),
  _QuickAction(Icons.bookmark_outline_rounded, 'Saved', const Color(0xFF8B7A6A)),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  CurvedAnimation _stagger(double start) =>
      CurvedAnimation(parent: _anim, curve: Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut));

  Widget _fadeSlide(Widget w, double start) {
    final a = _stagger(start);
    return FadeTransition(opacity: a,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(a), child: w));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final firstName = user == null
        ? 'there'
        : (user.firstName ?? user.displayName.split(' ').first);

    return Column(children: [
      const ClairAppBar(),
      Expanded(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F4F5), AppColors.bg]),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              _fadeSlide(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hello, $firstName', style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('How can CLAiR help you today?', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMid)),
                ]),
                0.0,
              ),
              const SizedBox(height: 22),

              _fadeSlide(
                Row(children: _quickActions.asMap().entries.map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: e.key == _quickActions.length - 1 ? 0 : 10),
                    child: _chip(e.value, context),
                  ),
                )).toList()),
                0.1,
              ),
              const SizedBox(height: 28),

              _fadeSlide(_sectionHead('Suggested Lawyers', 'See All', () => context.push('/lawyers')), 0.2),
              const SizedBox(height: 12),
              _fadeSlide(Row(children: [
                Expanded(child: _lawyerCard(_lawyers[0])),
                const SizedBox(width: 12),
                Expanded(child: _lawyerCard(_lawyers[1])),
              ]), 0.25),
              const SizedBox(height: 28),

              _fadeSlide(_sectionHead('Generated Documents', 'View All', () {}), 0.35),
              const SizedBox(height: 10),
              ..._documents.asMap().entries.map((e) =>
                  _fadeSlide(_docRow(e.value), 0.4 + e.key * 0.05)),
              const SizedBox(height: 28),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _chip(_QuickAction a, BuildContext ctx) => SpringButton(
    onTap: () {
      if (a.label == 'Lawyers') ctx.push('/lawyers');
      if (a.label == 'Chat') {
        ref.read(chatProvider.notifier).reset();
        ref.read(mainShellTabProvider.notifier).state = 1;
      }
      if (a.label == 'Saved') {
        ref.read(mainShellTabProvider.notifier).state = 2;
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: a.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(a.icon, color: a.color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(a.label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ]),
    ),
  );

  Widget _sectionHead(String title, String action, VoidCallback onAction) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      GestureDetector(
        onTap: onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(action, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
        ),
      ),
    ],
  );

  Widget _lawyerCard(_Lawyer l) => SpringButton(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent.withValues(alpha: 0.1), AppColors.accentLight.withValues(alpha: 0.25)]),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(child: Text(l.initials, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent))),
        ),
        const SizedBox(height: 10),
        Text(l.name, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(l.specialty, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMid)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFE9A020)),
          const SizedBox(width: 3),
          Text('${l.rating}  ·  ${l.cases} cases', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMid)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text('Connect', textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    ),
  );

  Widget _docRow(_Document d) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SpringButton(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC6B6B), size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text('${d.date}  ·  ${d.size}', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMid)),
          ])),
          const Icon(Icons.download_outlined, size: 18, color: AppColors.textLight),
        ]),
      ),
    ),
  );
}
