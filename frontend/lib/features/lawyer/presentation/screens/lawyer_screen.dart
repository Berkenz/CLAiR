import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_sharing_provider.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_overview_screen.dart';
import 'package:clair/features/lawyer/presentation/sheets/lawyer_booking_sheet.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

// ── Category model ────────────────────────────────────────────────────────────

class _LegalCategory {
  final IconData icon;
  final String label;
  final String practiceArea;
  final Color color;
  const _LegalCategory(this.icon, this.label, this.practiceArea, this.color);
}

const _kCategories = [
  _LegalCategory(Icons.gavel_rounded, 'Criminal', 'Criminal Law',
      Color(0xFFE53E3E)),
  _LegalCategory(Icons.family_restroom_rounded, 'Family', 'Family Law',
      Color(0xFFD69E2E)),
  _LegalCategory(Icons.business_rounded, 'Corporate', 'Corporate Law',
      Color(0xFF3182CE)),
  _LegalCategory(Icons.real_estate_agent_rounded, 'Property', 'Real Estate Law',
      Color(0xFF38A169)),
  _LegalCategory(Icons.account_balance_rounded, 'Finance', 'Banking & Finance Law',
      Color(0xFF805AD5)),
  _LegalCategory(Icons.work_outline_rounded, 'Labor', 'Labor Law',
      Color(0xFFDD6B20)),
  _LegalCategory(Icons.people_outline_rounded, 'Civil', 'Civil Law',
      Color(0xFF00B5D8)),
  _LegalCategory(Icons.flight_outlined, 'Immigration', 'Immigration Law',
      Color(0xFF319795)),
  _LegalCategory(Icons.inventory_2_outlined, 'Contracts', 'Contract Law',
      Color(0xFFB7791F)),
  _LegalCategory(Icons.favorite_border_rounded, 'Wills', 'Estate & Wills',
      Color(0xFF9F7AEA)),
  _LegalCategory(Icons.local_police_outlined, 'Administrative', 'Administrative Law',
      Color(0xFF2B6CB0)),
  _LegalCategory(Icons.eco_outlined, 'Environmental', 'Environmental Law',
      Color(0xFF276749)),
];

// ── Entry points ──────────────────────────────────────────────────────────────

/// Tab-embedded (no Scaffold, no back button).
class LawyerTabScreen extends ConsumerWidget {
  const LawyerTabScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [ClairAppBar(), Expanded(child: _LawyerBody())],
    );
  }
}

/// Standalone full-screen (/lawyers route).
class LawyerFullScreen extends ConsumerWidget {
  const LawyerFullScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
          child: _LawyerBody(onBack: () => Navigator.pop(context))),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _LawyerBody extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const _LawyerBody({this.onBack});
  @override
  ConsumerState<_LawyerBody> createState() => _LawyerBodyState();
}

class _LawyerBodyState extends ConsumerState<_LawyerBody>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final Set<int> _selectedCats = {};
  bool _searching = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    Future.microtask(
        () => ref.read(lawyerProvider.notifier).loadLawyers());
  }

  @override
  void dispose() {
    _anim.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _isFiltered =>
      _selectedCats.isNotEmpty || _searchCtrl.text.trim().isNotEmpty;

  List<LawyerEntity> _filtered(List<LawyerEntity> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final selectedAreas = _selectedCats
        .map((i) => _kCategories[i].practiceArea.toLowerCase())
        .toSet();

    return all.where((l) {
      final matchQ = q.isEmpty ||
          l.name.toLowerCase().contains(q) ||
          l.practiceAreas.any((a) => a.toLowerCase().contains(q)) ||
          (l.designation?.toLowerCase().contains(q) ?? false);
      final matchArea = selectedAreas.isEmpty ||
          l.practiceAreas.any((a) =>
              selectedAreas.any((sa) => a.toLowerCase().contains(sa)));
      return matchQ && matchArea;
    }).toList();
  }

  void _toggleCat(int i) {
    setState(() {
      if (_selectedCats.contains(i)) {
        _selectedCats.remove(i);
      } else {
        _selectedCats.add(i);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCats.clear();
      _searchCtrl.clear();
      _searching = false;
    });
  }

  void _openLawyer(LawyerEntity l) {
    final sharing = ref.read(lawyerSharingProvider);
    if (sharing != null) {
      showLawyerBookingSheet(
        context,
        l,
        preAttachedConversationId: sharing.conversationId,
        preAttachedConversationTitle: sharing.title,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => LawyerOverviewScreen(lawyer: l)),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final state = ref.watch(lawyerProvider);
    final sharing = ref.watch(lawyerSharingProvider);
    final filtered = _filtered(state.lawyers);

    return Container(
      color: cl.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sharing banner ───────────────────────────────────────────────
          if (sharing != null) _SharingBanner(data: sharing, cl: cl, ref: ref),

          // ── Scrollable area ──────────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header + search
                SliverToBoxAdapter(
                    child: _buildHeader(cl, state.isLoading)),

                // Category chips (hidden when searching)
                if (!_searching)
                  SliverToBoxAdapter(
                      child: _buildCategoryGrid(cl)),

                // Active filter pill + results label
                SliverToBoxAdapter(
                    child: _buildResultsBar(cl, filtered.length, state)),

                // Lawyer list
                if (state.error != null)
                  SliverFillRemaining(
                      child: _buildError(cl))
                else if (!state.isLoading && state.lawyers.isEmpty)
                  SliverFillRemaining(
                      child: _buildEmpty(cl))
                else if (!state.isLoading && filtered.isEmpty)
                  SliverFillRemaining(
                      child: _buildNoResults(cl))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final a = CurvedAnimation(
                          parent: _anim,
                          curve: Interval(
                            (i * 0.1).clamp(0, 0.6),
                            ((i * 0.1) + 0.4).clamp(0, 1),
                            curve: Curves.easeOut,
                          ),
                        );
                        return FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero)
                                .animate(a),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _LawyerCard(
                                lawyer: filtered[i],
                                onTap: () => _openLawyer(filtered[i]),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppColorTheme cl, bool loading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (widget.onBack != null) ...[
              GestureDetector(
                onTap: widget.onBack,
                child: Icon(Icons.arrow_back_rounded,
                    color: cl.textDark, size: 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text('Find a Lawyer',
                  style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark)),
            ),
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cl.accent),
              ),
          ]),
          const SizedBox(height: 14),
          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: cl.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _searching ? cl.accent : cl.border),
              boxShadow: [
                BoxShadow(
                    color: cl.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style:
                  GoogleFonts.nunito(fontSize: 14, color: cl.textDark),
              onTap: () => setState(() => _searching = true),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() => _searching = false),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by name or specialty…',
                hintStyle: GoogleFonts.nunito(
                    color: cl.textLight, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: _searching ? cl.accent : cl.textLight, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: cl.textLight),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searching = false);
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category grid ──────────────────────────────────────────────────────────

  Widget _buildCategoryGrid(AppColorTheme cl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Browse by practice area',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cl.textMid),
              ),
              if (_selectedCats.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedCats.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cl.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Clear (${_selectedCats.length})',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cl.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _kCategories.length,
              (i) => _buildCategoryChip(cl, i),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(AppColorTheme cl, int i) {
    final cat = _kCategories[i];
    final sel = _selectedCats.contains(i);
    return GestureDetector(
      onTap: () => _toggleCat(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? cat.color.withValues(alpha: 0.13) : cl.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? cat.color : cl.border,
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: cat.color.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sel ? Icons.check_circle_rounded : cat.icon,
              size: 15,
              color: sel ? cat.color : cat.color.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Text(
              cat.label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                color: sel ? cat.color : cl.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results bar ────────────────────────────────────────────────────────────

  Widget _buildResultsBar(
      AppColorTheme cl, int count, LawyerState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox.shrink(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isFiltered
                  ? '$count result${count == 1 ? '' : 's'}'
                  : 'All registered lawyers',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cl.textMid,
              ),
            ),
          ),
          if (_isFiltered)
            GestureDetector(
              onTap: _clearFilters,
              child: Text('Clear all',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cl.accent)),
            ),
        ],
      ),
    );
  }

  // ── State views ────────────────────────────────────────────────────────────

  Widget _buildError(AppColorTheme cl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: cl.textLight),
          const SizedBox(height: 16),
          Text('Couldn\'t load lawyers.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.nunito(fontSize: 14, color: cl.textMid)),
          const SizedBox(height: 16),
          SpringButton(
            onTap: () =>
                ref.read(lawyerProvider.notifier).loadLawyers(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: cl.accent,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('Retry',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty(AppColorTheme cl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_search_rounded,
              size: 48, color: cl.textLight),
          const SizedBox(height: 16),
          Text('No registered lawyers yet.',
              style:
                  GoogleFonts.nunito(fontSize: 14, color: cl.textMid)),
        ]),
      ),
    );
  }

  Widget _buildNoResults(AppColorTheme cl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: cl.textLight),
          const SizedBox(height: 14),
          Text('No lawyers match your filters.',
              style: GoogleFonts.nunito(
                  fontSize: 14, color: cl.textMid)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _clearFilters,
            child: Text('Clear filters',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: cl.accent)),
          ),
        ]),
      ),
    );
  }
}

// ── Lawyer card ───────────────────────────────────────────────────────────────

class _LawyerCard extends StatelessWidget {
  const _LawyerCard({required this.lawyer, required this.onTap});
  final LawyerEntity lawyer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final areas = lawyer.practiceAreas.take(2).toList();

    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
                color: cl.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  cl.accent.withValues(alpha: 0.12),
                  cl.accentLight.withValues(alpha: 0.3),
                ]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(lawyer.initials,
                    style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cl.accent)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(lawyer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cl.textDark)),
                      ),
                      // Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 10,
                                  color: Colors.green.shade600),
                              const SizedBox(width: 3),
                              Text('Verified',
                                  style: GoogleFonts.nunito(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade700)),
                            ]),
                      ),
                    ],
                  ),
                  if (lawyer.designation != null &&
                      lawyer.designation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(lawyer.designation!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 11.5, color: cl.textMid)),
                  ],
                  if (areas.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...areas.map((a) => _AreaPill(area: a, cl: cl)),
                        if (lawyer.practiceAreas.length > 2)
                          _AreaPill(
                              area:
                                  '+${lawyer.practiceAreas.length - 2}',
                              cl: cl,
                              muted: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: cl.textLight),
          ],
        ),
      ),
    );
  }
}

class _AreaPill extends StatelessWidget {
  const _AreaPill(
      {required this.area, required this.cl, this.muted = false});
  final String area;
  final AppColorTheme cl;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: muted
            ? cl.fieldBg
            : cl.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: muted ? cl.border : cl.accent.withValues(alpha: 0.2)),
      ),
      child: Text(area,
          style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: muted ? cl.textLight : cl.accent)),
    );
  }
}

// ── Sharing banner ────────────────────────────────────────────────────────────

class _SharingBanner extends StatelessWidget {
  const _SharingBanner(
      {required this.data, required this.cl, required this.ref});
  final ConversationSharingData data;
  final AppColorTheme cl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: cl.accent.withValues(alpha: 0.08),
        border: Border(
            bottom: BorderSide(
                color: cl.accent.withValues(alpha: 0.2))),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cl.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.chat_bubble_rounded,
              size: 16, color: cl.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sharing conversation with a lawyer',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cl.accent)),
                const SizedBox(height: 1),
                Text(
                  '"${data.title}" — tap any lawyer below to book with this pre-attached',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: cl.accent.withValues(alpha: 0.8),
                      height: 1.35),
                ),
              ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () =>
              ref.read(lawyerSharingProvider.notifier).state = null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: cl.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.close_rounded,
                size: 16, color: cl.accent),
          ),
        ),
      ]),
    );
  }
}
