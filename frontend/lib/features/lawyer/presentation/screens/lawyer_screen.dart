import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class _Category {
  final IconData icon;
  final String label;
  const _Category(this.icon, this.label);
}

class _Lawyer {
  final String name, specialty, location, initials;
  final double rating;
  final int cases;
  const _Lawyer({required this.name, required this.specialty, required this.location,
      required this.rating, required this.cases, required this.initials});
}

const _categories = [
  _Category(Icons.business_rounded, 'Corporate'),
  _Category(Icons.account_balance_rounded, 'Bankruptcy'),
  _Category(Icons.family_restroom_rounded, 'Family'),
  _Category(Icons.gavel_rounded, 'Criminal'),
  _Category(Icons.real_estate_agent_rounded, 'Property'),
];

const _lawyers = [
  _Lawyer(name: 'Atty. Maria Santos', specialty: 'Family Law', location: 'Cebu',
      rating: 4.8, cases: 142, initials: 'MS'),
  _Lawyer(name: 'Atty. Juan Reyes', specialty: 'Property Law', location: 'Manila',
      rating: 4.6, cases: 98, initials: 'JR'),
  _Lawyer(name: 'Atty. Ana Cruz', specialty: 'Corporate Law', location: 'Davao',
      rating: 4.9, cases: 210, initials: 'AC'),
  _Lawyer(name: 'Atty. Carlos Tan', specialty: 'Criminal Law', location: 'Cebu',
      rating: 4.5, cases: 76, initials: 'CT'),
];

/// Tab-embedded version (no Scaffold, no back button) for MainShell navbar.
class LawyerTabScreen extends StatelessWidget {
  const LawyerTabScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ClairAppBar(),
        Expanded(child: _LawyerBody()),
      ],
    );
  }
}

/// Standalone page with Scaffold + back button (for /lawyers route)
class LawyerFullScreen extends StatelessWidget {
  const LawyerFullScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(child: _LawyerBody(onBack: () => Navigator.pop(context))),
    );
  }
}

class _LawyerBody extends StatefulWidget {
  final VoidCallback? onBack;
  const _LawyerBody({this.onBack});
  @override
  State<_LawyerBody> createState() => _LawyerBodyState();
}

class _LawyerBodyState extends State<_LawyerBody> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  int _selectedCat = -1;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() { _anim.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [cl.surface, cl.bg]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
          child: Row(children: [
            if (widget.onBack != null)
              GestureDetector(onTap: widget.onBack,
                  child: Icon(Icons.arrow_back_rounded, color: cl.textDark, size: 22)),
            if (widget.onBack != null) const SizedBox(width: 12),
            Expanded(child: Text("Find a Lawyer", style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: cl.textDark))),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 46,
            decoration: BoxDecoration(color: cl.surface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cl.border),
                boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 8, offset: const Offset(0, 2))]),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.nunito(fontSize: 14, color: cl.textDark),
              decoration: InputDecoration(
                border: InputBorder.none, hintText: 'Search lawyers, specialties...',
                hintStyle: GoogleFonts.nunito(color: cl.textLight, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: cl.textLight, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text('Select a category', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: cl.textMid)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (_, i) => _catChip(i),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text('Suggested for you', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: cl.textMid)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _lawyers.length,
            itemBuilder: (_, i) {
              final a = CurvedAnimation(parent: _anim,
                  curve: Interval((i * 0.12).clamp(0, 0.6), ((i * 0.12) + 0.4).clamp(0, 1), curve: Curves.easeOut));
              return FadeTransition(opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(a),
                    child: _lawyerTile(_lawyers[i]),
                  ));
            },
          ),
        ),
      ]),
    );
  }

  Widget _catChip(int i) {
    final cl = context.c;
    final c = _categories[i];
    final sel = _selectedCat == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCat = sel ? -1 : i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: sel ? cl.accent : cl.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? cl.accent : cl.border),
            boxShadow: sel ? [BoxShadow(color: cl.accent.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : [BoxShadow(color: cl.cardShadow, blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(c.icon, size: 15, color: sel ? Colors.white : cl.textMid),
            const SizedBox(width: 6),
            Text(c.label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : cl.textDark)),
          ]),
        ),
      ),
    );
  }

  Widget _lawyerTile(_Lawyer l) {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SpringButton(
        onTap: () => _showConnectModal(l),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cl.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cl.border),
            boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cl.accent.withValues(alpha: 0.12), cl.accentLight.withValues(alpha: 0.3)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(l.initials, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: cl.accent))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: cl.textDark)),
              const SizedBox(height: 2),
              Text('${l.specialty} · ${l.location}', style: GoogleFonts.nunito(fontSize: 12, color: cl.textMid)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFE9A020)),
                const SizedBox(width: 2),
                Text('${l.rating}', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: cl.textDark)),
              ]),
              const SizedBox(height: 2),
              Text('${l.cases} cases', style: GoogleFonts.nunito(fontSize: 11, color: cl.textLight)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showConnectModal(_Lawyer l) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ConnectModal(lawyer: l),
    );
  }
}

class _ConnectModal extends StatelessWidget {
  final _Lawyer lawyer;
  const _ConnectModal({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cl.surface, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 24, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: cl.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cl.accent.withValues(alpha: 0.12), cl.accentLight.withValues(alpha: 0.3)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(child: Text(lawyer.initials, style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: cl.accent))),
        ),
        const SizedBox(height: 16),
        Text(lawyer.name, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: cl.textDark)),
        const SizedBox(height: 4),
        Text('${lawyer.specialty} · ${lawyer.location}', style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFE9A020)),
          const SizedBox(width: 4),
          Text('${lawyer.rating}', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: cl.textDark)),
          const SizedBox(width: 12),
          Text('${lawyer.cases} cases handled', style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid)),
        ]),
        const SizedBox(height: 28),
        SpringButton(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              color: cl.accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: cl.accent.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text('Connect', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: cl.textMid))),
      ]),
    );
  }
}
