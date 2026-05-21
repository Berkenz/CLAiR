import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/utils/lawyer_nearby.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_sharing_provider.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_overview_screen.dart';
import 'package:clair/features/lawyer/presentation/sheets/lawyer_booking_sheet.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_map_view.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_display_avatar.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';
import 'package:clair/features/lawyer/presentation/lawyer_practice_l10n.dart';
import 'package:clair/l10n/app_localizations.dart';

// ── Category model ────────────────────────────────────────────────────────────

class _LegalCategory {
  final IconData icon;
  final String label;
  final String practiceArea;
  final Color color;
  const _LegalCategory(this.icon, this.label, this.practiceArea, this.color);
}

List<_LegalCategory> _legalCategories(AppLocalizations l) {
  return [
    _LegalCategory(
        Icons.gavel_rounded, l.lawyerChipCriminal, 'Criminal Law',
        const Color(0xFFE53E3E)),
    _LegalCategory(Icons.family_restroom_rounded, l.lawyerChipFamily,
        'Family Law', const Color(0xFFD69E2E)),
    _LegalCategory(Icons.business_rounded, l.lawyerChipCorporate,
        'Corporate Law', const Color(0xFF3182CE)),
    _LegalCategory(Icons.real_estate_agent_rounded, l.lawyerChipProperty,
        'Real Estate Law', const Color(0xFF38A169)),
    _LegalCategory(Icons.account_balance_rounded, l.lawyerChipFinance,
        'Banking & Finance Law', const Color(0xFF805AD5)),
    _LegalCategory(Icons.work_outline_rounded, l.lawyerChipLabor, 'Labor Law',
        const Color(0xFFDD6B20)),
    _LegalCategory(Icons.people_outline_rounded, l.lawyerChipCivil, 'Civil Law',
        const Color(0xFF00B5D8)),
    _LegalCategory(Icons.flight_outlined, l.lawyerChipImmigration,
        'Immigration Law', const Color(0xFF319795)),
    _LegalCategory(Icons.inventory_2_outlined, l.lawyerChipContracts,
        'Contract Law', const Color(0xFFB7791F)),
    _LegalCategory(Icons.favorite_border_rounded, l.lawyerChipWills,
        'Estate & Wills', const Color(0xFF9F7AEA)),
    _LegalCategory(Icons.local_police_outlined, l.lawyerChipAdministrative,
        'Administrative Law', const Color(0xFF2B6CB0)),
    _LegalCategory(Icons.eco_outlined, l.lawyerChipEnvironmental,
        'Environmental Law', const Color(0xFF276749)),
  ];
}

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
  bool _showMap = false;
  bool _practiceAreasExpanded = true;
  late final AnimationController _anim;
  late final StateController<bool> _mapViewActiveCtrl;
  late final StateController<bool> _mapSheetOpenCtrl;

  @override
  void initState() {
    super.initState();
    _mapViewActiveCtrl = ref.read(lawyerMapViewActiveProvider.notifier);
    _mapSheetOpenCtrl = ref.read(lawyerMapSheetOpenProvider.notifier);
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    Future.microtask(() async {
      await ref.read(lawyerProvider.notifier).loadLawyers();
      ref.read(locationProvider.notifier).prefetchIfNeeded();
    });
  }

  @override
  void dispose() {
    _mapViewActiveCtrl.state = false;
    _mapSheetOpenCtrl.state = false;
    _anim.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _setMapView(bool showMap) {
    if (_showMap == showMap) return;
    setState(() {
      _showMap = showMap;
      _practiceAreasExpanded = !showMap;
    });
    _mapViewActiveCtrl.state = showMap;
    if (!showMap) _mapSheetOpenCtrl.state = false;
  }

  bool get _isFiltered =>
      _selectedCats.isNotEmpty || _searchCtrl.text.trim().isNotEmpty;

  List<LawyerEntity> _pinnedForMap(List<LawyerEntity> lawyers) => lawyers
      .where((l) => l.latitude != null && l.longitude != null)
      .toList();

  List<LawyerEntity> _filtered(
      List<LawyerEntity> all, List<_LegalCategory> cats) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final selectedAreas = _selectedCats
        .map((i) => cats[i].practiceArea.toLowerCase())
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

  void _openExpandedMap(
    List<LawyerEntity> filtered,
    LawyerState state,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LawyerExpandedMapScreen(
          lawyers: filtered,
          onLawyerTap: _openLawyer,
          directoryEmpty: !state.isLoading && state.lawyers.isEmpty,
          noFilterMatches:
              _isFiltered && filtered.isEmpty && !state.isLoading,
        ),
      ),
    );
  }

  void _openLawyer(LawyerEntity l) {
    final sharing = ref.read(lawyerSharingProvider);
    if (sharing != null) {
      if (showGuestBookingPrompt(context, ref)) return;
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
    final l10n = AppLocalizations.of(context)!;
    final cats = _legalCategories(l10n);
    final state = ref.watch(lawyerProvider);
    final loc = ref.watch(locationProvider);
    final sharing = ref.watch(lawyerSharingProvider);
    final filtered = _filtered(state.lawyers, cats);
    final nearby = loc.hasLocation
        ? lawyersNearPoint(
            lawyers: filtered,
            userLat: loc.latitude!,
            userLng: loc.longitude!,
          )
        : <LawyerNearbyEntry>[];

    return Container(
      color: cl.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sharing banner ───────────────────────────────────────────────
          if (sharing != null)
            _SharingBanner(data: sharing, cl: cl, ref: ref, l10n: l10n),

          // ── Map view ─────────────────────────────────────────────────────
          if (_showMap)
            Expanded(
              child: Column(
                children: [
                  _buildHeader(cl, state.isLoading, l10n),
                  if (!_searching)
                    _buildCategoryGrid(cl, cats, l10n),
                  if (!state.isLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildResultsBar(
                        cl,
                        _pinnedForMap(filtered).length,
                        state,
                        l10n,
                        mapMode: true,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: LawyerMapView(
                        lawyers: filtered,
                        directoryEmpty:
                            !state.isLoading && state.lawyers.isEmpty,
                        noFilterMatches:
                            _isFiltered && filtered.isEmpty && !state.isLoading,
                        onTap: _openLawyer,
                        onExpand: () => _openExpandedMap(filtered, state),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Scrollable list ──────────────────────────────────────────────
          if (!_showMap)
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header + search
                SliverToBoxAdapter(
                    child: _buildHeader(cl, state.isLoading, l10n)),

                if (!_searching && !state.isLoading)
                  SliverToBoxAdapter(
                    child: _buildNearbySection(
                      cl,
                      l10n,
                      loc,
                      nearby,
                    ),
                  ),

                // Category chips (hidden when searching)
                if (!_searching)
                  SliverToBoxAdapter(
                      child: _buildCategoryGrid(cl, cats, l10n)),

                // Active filter pill + results label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildResultsBar(cl, filtered.length, state, l10n),
                  ),
                ),

                // Lawyer list
                if (state.error != null)
                  SliverFillRemaining(
                      child: _buildError(cl, state.error!, l10n))
                else if (!state.isLoading && state.lawyers.isEmpty)
                  SliverFillRemaining(
                      child: _buildEmpty(cl, l10n))
                else if (!state.isLoading && filtered.isEmpty)
                  SliverFillRemaining(
                      child: _buildNoResults(cl, l10n))
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
                                l10n: l10n,
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

  Widget _buildHeader(AppColorTheme cl, bool loading, AppLocalizations l10n) {
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
              child: Text(l10n.drawerFindLawyer,
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
          const SizedBox(height: 12),
          _LawyerViewModeToggle(
            cl: cl,
            l10n: l10n,
            showMap: _showMap,
            onList: () => _setMapView(false),
            onMap: () => _setMapView(true),
          ),
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
                hintText: l10n.lawyerSearchHint,
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

  Widget _buildNearbySection(
    AppColorTheme cl,
    AppLocalizations l10n,
    LocationState loc,
    List<LawyerNearbyEntry> nearby,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me_rounded, size: 16, color: cl.accent),
              const SizedBox(width: 6),
              Text(
                l10n.chatLawyersNearYou,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cl.textMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loc.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cl.accent,
                  ),
                ),
              ),
            )
          else if (!loc.hasLocation)
            _NearbyLocationPrompt(
              cl: cl,
              message: loc.error ?? l10n.lawyerNearYouEnableLocation,
              onEnable: () => ref
                  .read(locationProvider.notifier)
                  .fetchLocation(force: true),
            )
          else if (nearby.isEmpty)
            Text(
              l10n.lawyerNearYouNoneInRange,
              style: GoogleFonts.nunito(fontSize: 12, color: cl.textLight),
            )
          else
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearby.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final entry = nearby[i];
                  return _NearbyLawyerCard(
                    lawyer: entry.lawyer,
                    distanceKm: entry.distanceKm,
                    l10n: l10n,
                    onTap: () => _openLawyer(entry.lawyer),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Category grid ──────────────────────────────────────────────────────────

  Widget _buildCategoryGrid(
      AppColorTheme cl, List<_LegalCategory> cats, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(
                () => _practiceAreasExpanded = !_practiceAreasExpanded,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.lawyerBrowseByPracticeArea,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cl.textMid,
                        ),
                      ),
                    ),
                    if (_selectedCats.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(() => _selectedCats.clear()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cl.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.lawyerClearWithCount(_selectedCats.length),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cl.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Tooltip(
                      message: _practiceAreasExpanded
                          ? l10n.lawyerHidePracticeAreas
                          : l10n.lawyerShowPracticeAreas,
                      child: Icon(
                        _practiceAreasExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 22,
                        color: cl.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,
            duration: const Duration(milliseconds: 220),
            crossFadeState: _practiceAreasExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    cats.length,
                    (i) => _buildCategoryChip(cl, cats, i),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            secondChild: const SizedBox(height: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      AppColorTheme cl, List<_LegalCategory> cats, int i) {
    final cat = cats[i];
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
    AppColorTheme cl,
    int count,
    LawyerState state,
    AppLocalizations l10n, {
    bool mapMode = false,
  }) {
    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    final label = _isFiltered
        ? (mapMode
            ? l10n.lawyerMapPinsCount(count)
            : l10n.lawyerResultsCount(count))
        : (mapMode
            ? l10n.lawyerMapAllPins(count)
            : l10n.lawyerAllRegistered);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
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
            child: Text(
              l10n.lawyerClearAll,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cl.accent,
              ),
            ),
          ),
      ],
    );
  }

  // ── State views ────────────────────────────────────────────────────────────

  Widget _buildError(AppColorTheme cl, String detail, AppLocalizations l10n) {
    final detailMaxHeight = MediaQuery.sizeOf(context).height * 0.32;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: cl.textLight),
            const SizedBox(height: 16),
            Text(
              l10n.lawyerLoadErrorTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cl.textMid,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: detailMaxHeight),
              child: SingleChildScrollView(
                child: SelectableText(
                  detail.trim().isEmpty ? l10n.lawyerUnknownError : detail.trim(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    height: 1.35,
                    color: cl.textLight,
                  ),
                ),
              ),
            ),
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
                child: Text(l10n.lawyerRetry,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorTheme cl, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_search_rounded,
              size: 48, color: cl.textLight),
          const SizedBox(height: 16),
          Text(l10n.lawyerEmptyState,
              style:
                  GoogleFonts.nunito(fontSize: 14, color: cl.textMid)),
        ]),
      ),
    );
  }

  Widget _buildNoResults(AppColorTheme cl, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: cl.textLight),
          const SizedBox(height: 14),
          Text(l10n.lawyerNoMatches,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: cl.textMid)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _clearFilters,
            child: Text(l10n.lawyerClearFilters,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: cl.accent)),
          ),
        ]),
      ),
    );
  }
}

// ── Nearby lawyer horizontal card ─────────────────────────────────────────────

class _NearbyLawyerCard extends StatelessWidget {
  const _NearbyLawyerCard({
    required this.lawyer,
    required this.distanceKm,
    required this.l10n,
    required this.onTap,
  });

  final LawyerEntity lawyer;
  final double distanceKm;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final kmLabel = distanceKm < 10
        ? distanceKm.toStringAsFixed(1)
        : distanceKm.round().toString();
    final area = lawyer.practiceAreas.isNotEmpty
        ? localizeLawyerPracticeArea(l10n, lawyer.practiceAreas.first)
        : null;

    return SpringButton(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.accent.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LawyerDisplayAvatar(
                  lawyer: lawyer,
                  size: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      cl.accent.withValues(alpha: 0.12),
                      cl.accentLight.withValues(alpha: 0.3),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  initialsStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cl.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lawyer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              l10n.lawyerKmAway(kmLabel),
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cl.accent,
              ),
            ),
            if (area != null) ...[
              const SizedBox(height: 2),
              Text(
                area,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(fontSize: 10.5, color: cl.textMid),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyLocationPrompt extends StatelessWidget {
  const _NearbyLocationPrompt({
    required this.cl,
    required this.message,
    required this.onEnable,
  });

  final AppColorTheme cl;
  final String message;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onTap: onEnable,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cl.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cl.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined, size: 20, color: cl.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(fontSize: 12, color: cl.textMid),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: cl.accent),
          ],
        ),
      ),
    );
  }
}

// ── Lawyer card ───────────────────────────────────────────────────────────────

class _LawyerCard extends StatelessWidget {
  const _LawyerCard({
    required this.lawyer,
    required this.l10n,
    required this.onTap,
  });
  final LawyerEntity lawyer;
  final AppLocalizations l10n;
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
            LawyerDisplayAvatar(
              lawyer: lawyer,
              size: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  cl.accent.withValues(alpha: 0.12),
                  cl.accentLight.withValues(alpha: 0.3),
                ]),
                borderRadius: BorderRadius.circular(15),
              ),
              initialsStyle: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cl.accent,
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
                              Text(l10n.lawyerVerified,
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
                    Text(localizeLawyerDesignation(l10n, lawyer.designation!),
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
                        ...areas.map((a) => _AreaPill(
                              area: localizeLawyerPracticeArea(l10n, a),
                              cl: cl)),
                        if (lawyer.practiceAreas.length > 2)
                          _AreaPill(
                              area: l10n.lawyerExtraAreas(
                                  lawyer.practiceAreas.length - 2),
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
  const _SharingBanner({
    required this.data,
    required this.cl,
    required this.ref,
    required this.l10n,
  });
  final ConversationSharingData data;
  final AppColorTheme cl;
  final WidgetRef ref;
  final AppLocalizations l10n;

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
                Text(l10n.lawyerSharingTitle,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cl.accent)),
                const SizedBox(height: 1),
                Text(
                  l10n.lawyerSharingSubtitle(data.title),
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

// ── List / Map segmented toggle ───────────────────────────────────────────────

class _LawyerViewModeToggle extends StatelessWidget {
  const _LawyerViewModeToggle({
    required this.cl,
    required this.l10n,
    required this.showMap,
    required this.onList,
    required this.onMap,
  });

  final AppColorTheme cl;
  final AppLocalizations l10n;
  final bool showMap;
  final VoidCallback onList;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cl.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cl.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LawyerViewModeSegment(
              cl: cl,
              icon: Icons.view_list_rounded,
              label: l10n.lawyerList,
              selected: !showMap,
              onTap: onList,
            ),
          ),
          Expanded(
            child: _LawyerViewModeSegment(
              cl: cl,
              icon: Icons.map_rounded,
              label: l10n.lawyerMap,
              selected: showMap,
              onTap: onMap,
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerViewModeSegment extends StatelessWidget {
  const _LawyerViewModeSegment({
    required this.cl,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppColorTheme cl;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cl.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cl.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cl.accent : cl.textMid,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? cl.accentDark : cl.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
