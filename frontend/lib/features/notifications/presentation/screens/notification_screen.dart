import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';

class _Notif {
  final String title, body, time;
  final IconData icon;
  final bool isNew;
  const _Notif({required this.title, required this.body, required this.time, required this.icon, this.isNew = false});
}

/// Standalone page with back button (for /notifications route)
class NotificationFullScreen extends StatelessWidget {
  const NotificationFullScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _NotificationBody(onBack: () => Navigator.pop(context))),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  final VoidCallback? onBack;
  const _NotificationBody({this.onBack});

  static const _today = [
    _Notif(title: 'Case Update', body: 'Your land dispute case has a new document attached.', time: '2h ago', icon: Icons.description_outlined, isNew: true),
    _Notif(title: 'Appointment Reminder', body: 'You have an appointment with Atty. Santos tomorrow at 2:00 PM.', time: '4h ago', icon: Icons.calendar_today_outlined, isNew: true),
  ];

  static const _earlier = [
    _Notif(title: 'New Feature', body: 'Legal dictionary is now available. Check it out!', time: 'Yesterday', icon: Icons.menu_book_outlined),
    _Notif(title: 'Lawyer Response', body: 'Atty. Reyes has responded to your inquiry.', time: '2 days ago', icon: Icons.person_outline_rounded),
    _Notif(title: 'Welcome to CLAiR', body: 'Thanks for joining. Start by asking a legal question.', time: '1 week ago', icon: Icons.waving_hand_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4F5), AppColors.bg]),
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
            child: Row(children: [
              if (onBack != null)
                GestureDetector(onTap: onBack,
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 22)),
              if (onBack != null) const SizedBox(width: 12),
              Text('Notifications', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const Spacer(),
              GestureDetector(onTap: () {},
                  child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textMid)),
            ]),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Today'),
          ..._today.map(_tile),
          const SizedBox(height: 16),
          _sectionLabel('Earlier'),
          ..._earlier.map(_tile),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String s) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(s, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid)),
  );

  Widget _tile(_Notif n) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.isNew ? Colors.white : AppColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: n.isNew ? AppColors.accent.withValues(alpha: 0.2) : AppColors.border),
        boxShadow: n.isNew ? [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))] : [],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: n.isNew ? AppColors.accent.withValues(alpha: 0.1) : AppColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(n.icon, size: 18, color: n.isNew ? AppColors.accent : AppColors.textMid),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n.title, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
            if (n.isNew) Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 3),
          Text(n.body, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMid, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(n.time, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight)),
        ])),
      ]),
    ),
  );
}
