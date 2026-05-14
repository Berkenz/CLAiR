import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/providers/direct_message_provider.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'package:clair/features/appointments/presentation/screens/lawyer_chat_screen.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

enum _AppointmentListFilter { all, pending, confirmed, cancelled }

enum _AppointmentListSort { dateNewest, dateOldest }

class AppointmentTabScreen extends ConsumerStatefulWidget {
  const AppointmentTabScreen({super.key});

  @override
  ConsumerState<AppointmentTabScreen> createState() =>
      _AppointmentTabScreenState();
}

class _AppointmentTabScreenState extends ConsumerState<AppointmentTabScreen> {
  static const int _tabIndex = 4;

  _AppointmentListFilter _filter = _AppointmentListFilter.all;
  _AppointmentListSort _sort = _AppointmentListSort.dateNewest;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(appointmentProvider.notifier).loadAppointments();
      if (!mounted) return;
      _processPendingNotificationRoutes(ref.read(appointmentProvider));
    });
  }

  /// Opens chat or appointment detail when user tapped a matching inbox notification.
  void _processPendingNotificationRoutes(AppointmentState next) {
    if (next.isLoading) return;

    final chatPending = ref.read(pendingLawyerChatAppointmentIdProvider);
    if (chatPending != null) {
      AppointmentEntity? foundChat;
      for (final a in next.appointments) {
        if (a.id == chatPending) {
          foundChat = a;
          break;
        }
      }
      ref.read(pendingLawyerChatAppointmentIdProvider.notifier).state = null;
      if (foundChat != null) {
        final appt = foundChat;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (appt.canStartLawyerChat) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => LawyerChatScreen(appointment: appt),
              ),
            );
          } else {
            Navigator.of(context)
                .push<bool>(
              MaterialPageRoute(
                builder: (_) => AppointmentDetailScreen(appointment: appt),
              ),
            )
                .then((changed) {
              if (changed == true && mounted) {
                ref
                    .read(appointmentProvider.notifier)
                    .loadAppointments(force: true);
              }
            });
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.apptNotFoundSnackbar),
              backgroundColor: Colors.red.shade700,
            ),
          );
        });
      }
      return;
    }

    final pending = ref.read(pendingAppointmentDetailIdProvider);
    if (pending == null) return;

    AppointmentEntity? found;
    for (final a in next.appointments) {
      if (a.id == pending) {
        found = a;
        break;
      }
    }
    ref.read(pendingAppointmentDetailIdProvider.notifier).state = null;
    if (found != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context)
            .push<bool>(
          MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(appointment: found!),
          ),
        )
            .then((changed) {
          if (changed == true && mounted) {
            ref.read(appointmentProvider.notifier).loadAppointments(force: true);
          }
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.apptNotFoundSnackbar),
            backgroundColor: Colors.red.shade700,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next == _tabIndex) {
        ref.read(appointmentProvider.notifier).loadAppointments();
      }
    });

    ref.listen<AppointmentState>(appointmentProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(appointmentProvider.notifier).clearError();
      }

      _processPendingNotificationRoutes(next);
    });

    final state = ref.watch(appointmentProvider);

    return Column(
      children: [
        const ClairAppBar(),
        Expanded(child: _buildBody(state, AppLocalizations.of(context)!)),
      ],
    );
  }

  List<AppointmentEntity> _applyFilter(List<AppointmentEntity> list) {
    return switch (_filter) {
      _AppointmentListFilter.all => List<AppointmentEntity>.of(list),
      _AppointmentListFilter.pending =>
        list.where((a) => a.status == 'pending').toList(),
      _AppointmentListFilter.confirmed =>
        list.where((a) => a.status == 'confirmed').toList(),
      _AppointmentListFilter.cancelled =>
        list.where((a) => a.status == 'cancelled').toList(),
    };
  }

  void _applySort(List<AppointmentEntity> list) {
    int bookedCmp(AppointmentEntity a, AppointmentEntity b) {
      return a.createdAt.compareTo(b.createdAt);
    }

    list.sort((a, b) {
      final c = bookedCmp(a, b);
      return _sort == _AppointmentListSort.dateOldest ? c : -c;
    });
  }

  Widget _buildBody(AppointmentState state, AppLocalizations l10n) {
    final cl = context.c;

    if (state.isLoading && state.appointments.isEmpty) {
      return Center(child: CircularProgressIndicator(color: cl.accent));
    }

    final raw = state.appointments;

    if (raw.isEmpty) {
      return _buildEmptyState(l10n);
    }

    final filtered = _applyFilter(raw);
    final sorted = List<AppointmentEntity>.of(filtered);
    _applySort(sorted);

    if (sorted.isEmpty) {
      return _buildNoFilterMatches(cl, l10n);
    }

    return RefreshIndicator(
      color: cl.accent,
      onRefresh: () =>
          ref.read(appointmentProvider.notifier).loadAppointments(force: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(state, l10n, cl),
          ),
          SliverToBoxAdapter(child: _buildFilterSortRow(cl, l10n)),
          if (_filter == _AppointmentListFilter.all)
            ..._buildGroupedSlivers(cl, sorted, l10n)
          else ...[
            _buildSectionHeader(_filterSectionTitle(l10n), sorted.length),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppointmentCard(
                      appointment: sorted[i],
                      onTap: () => _openDetail(sorted[i]),
                      muted: sorted[i].status == 'cancelled',
                    ),
                  ),
                  childCount: sorted.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(
      AppointmentState state, AppLocalizations l10n, AppColorTheme cl) {
    final pendingCount = state.pendingCount;
    final newCount = state.newCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.apptMyTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: cl.textDark,
                        fontFamily: 'Satoshi',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.apptTotalCount(state.appointments.length),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: cl.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              if (newCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cl.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$newCount new',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 12),
            _PendingBanner(pendingCount: pendingCount),
          ],
        ],
      ),
    );
  }

  String _filterSectionTitle(AppLocalizations l10n) {
    return switch (_filter) {
      _AppointmentListFilter.pending => l10n.apptFilterPending,
      _AppointmentListFilter.confirmed => l10n.apptFilterAccepted,
      _AppointmentListFilter.cancelled => l10n.apptSectionCancelledOrDeclined,
      _AppointmentListFilter.all => '',
    };
  }

  List<Widget> _buildGroupedSlivers(
    AppColorTheme cl,
    List<AppointmentEntity> sorted,
    AppLocalizations l10n,
  ) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todayAppts = sorted.where((a) {
      final d = a.appointmentDate;
      final apptDay = DateTime(d.year, d.month, d.day);
      return apptDay == todayDate && a.status != 'cancelled';
    }).toList();

    final upcoming = sorted.where((a) {
      final d = a.appointmentDate;
      final apptDay = DateTime(d.year, d.month, d.day);
      return apptDay.isAfter(todayDate) && a.status != 'cancelled';
    }).toList();

    final past = sorted.where((a) {
      final d = a.appointmentDate;
      final apptDay = DateTime(d.year, d.month, d.day);
      return apptDay.isBefore(todayDate) && a.status != 'cancelled';
    }).toList();

    final cancelled = sorted.where((a) => a.status == 'cancelled').toList();

    return [
      if (todayAppts.isNotEmpty) ...[
        _buildSectionHeader('Today', todayAppts.length, highlight: true),
        _buildCardList(todayAppts),
      ],
      if (upcoming.isNotEmpty) ...[
        _buildSectionHeader('Upcoming', upcoming.length),
        _buildCardList(upcoming),
      ],
      if (past.isNotEmpty) ...[
        _buildSectionHeader('Past', past.length),
        _buildCardList(past),
      ],
      if (cancelled.isNotEmpty) ...[
        _buildSectionHeader(l10n.apptSectionCancelledOrDeclined, cancelled.length),
        _buildCardList(cancelled, muted: true),
      ],
    ];
  }

  Widget _buildCardList(List<AppointmentEntity> items, {bool muted = false}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AppointmentCard(
              appointment: items[i],
              onTap: () => _openDetail(items[i]),
              muted: muted,
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildFilterSortRow(AppColorTheme cl, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.apptFilterAll,
                  selected: _filter == _AppointmentListFilter.all,
                  onTap: () =>
                      setState(() => _filter = _AppointmentListFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.apptFilterPending,
                  selected: _filter == _AppointmentListFilter.pending,
                  onTap: () =>
                      setState(() => _filter = _AppointmentListFilter.pending),
                  dotColor: const Color(0xFFE59300),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.apptFilterAccepted,
                  selected: _filter == _AppointmentListFilter.confirmed,
                  onTap: () =>
                      setState(() => _filter = _AppointmentListFilter.confirmed),
                  dotColor: const Color(0xFF22A64A),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.apptFilterCancelled,
                  selected: _filter == _AppointmentListFilter.cancelled,
                  onTap: () =>
                      setState(() => _filter = _AppointmentListFilter.cancelled),
                  dotColor: const Color(0xFFD63031),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<_AppointmentListSort>(
              onSelected: (v) => setState(() => _sort = v),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _AppointmentListSort.dateNewest,
                  child: Text(
                    l10n.apptSortNewestFirst,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
                PopupMenuItem(
                  value: _AppointmentListSort.dateOldest,
                  child: Text(
                    l10n.apptSortOldestFirst,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cl.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cl.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: cl.accent),
                    const SizedBox(width: 6),
                    Text(
                      _sort == _AppointmentListSort.dateNewest
                          ? l10n.apptSortChipNewest
                          : l10n.apptSortChipOldest,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cl.textDark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded,
                        color: cl.textMid, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildNoFilterMatches(AppColorTheme cl, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: cl.fieldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.filter_alt_off_rounded,
                  size: 30, color: cl.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.apptNoFilterMatch,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cl.textDark,
                fontFamily: 'Satoshi',
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _filter = _AppointmentListFilter.all),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: cl.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.apptShowAll,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: cl.accent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count,
      {bool highlight = false}) {
    final cl = context.c;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(
          children: [
            if (highlight)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: cl.accent,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: highlight ? cl.accent : cl.textMid,
                fontFamily: 'Satoshi',
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: highlight
                    ? cl.accent.withValues(alpha: 0.12)
                    : cl.fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlight ? cl.accent : cl.textMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(AppointmentEntity appt) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appt),
      ),
    );
    if (changed == true && mounted) {
      await ref
          .read(appointmentProvider.notifier)
          .loadAppointments(force: true);
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final cl = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cl.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_note_rounded, size: 38, color: cl.accent),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.apptEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cl.textDark,
                fontFamily: 'Satoshi',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.apptEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: cl.textMid,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending banner ────────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.pendingCount});
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131008) : const Color(0xFFFFF4DE);
    final border = isDark
        ? const Color(0xFF252008).withValues(alpha: 0.8)
        : const Color(0xFFE59300).withValues(alpha: 0.3);
    final fg = isDark ? const Color(0xFF6B5415) : const Color(0xFFB26A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount == 1
                  ? '1 appointment awaiting confirmation'
                  : '$pendingCount appointments awaiting confirmation',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom filter chip ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cl.accent : cl.fieldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cl.accent : cl.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : cl.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _AppointmentCard extends ConsumerStatefulWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.muted = false,
  });

  final AppointmentEntity appointment;
  final VoidCallback onTap;
  final bool muted;

  @override
  ConsumerState<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<_AppointmentCard> {
  @override
  void initState() {
    super.initState();
    // Lazily peek the DM unread count for confirmed appointments.
    if (widget.appointment.canStartLawyerChat) {
      Future.microtask(() {
        if (mounted) {
          ref
              .read(directMessageProvider(widget.appointment.id).notifier)
              .fetchCountOnly();
        }
      });
    }
  }

  AppointmentEntity get appointment => widget.appointment;
  bool get muted => widget.muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(appointment.status);
    final bookedLocal = appointment.createdAt.toLocal();
    final bookedDate = DateFormat('MMM d, y').format(bookedLocal);
    final bookedTime = DateFormat('h:mm a').format(bookedLocal);
    final bookedLine = l10n.apptCardBookedAt(bookedDate, bookedTime);
    final isNew = appointment.isNew;

    final dmUnread = appointment.canStartLawyerChat
        ? ref.watch(directMessageProvider(appointment.id)).unreadCount
        : 0;

    return SpringButton(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cl.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNew && !muted
                    ? cl.accent.withValues(alpha: 0.35)
                    : cl.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: cl.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 36, 13),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment.displayCaseTitle,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: muted
                                              ? cl.textDark
                                                  .withValues(alpha: 0.45)
                                              : cl.textDark,
                                          fontFamily: 'Satoshi',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        appointment.displayLawyerName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: muted
                                              ? cl.textMid
                                                  .withValues(alpha: 0.55)
                                              : cl.textMid,
                                          fontFamily: 'Satoshi',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _StatusPill(
                                        appointment: appointment,
                                        muted: muted),
                                    if (isNew && !muted) ...[
                                      const SizedBox(height: 4),
                                      _NewBadge(l10n: l10n),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 12,
                                  color: cl.textLight,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    bookedLine,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted
                                          ? cl.textMid
                                              .withValues(alpha: 0.55)
                                          : cl.textMid,
                                      fontFamily: 'Satoshi',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  appointment.appointmentType
                                              .toLowerCase()
                                              .contains('online') ||
                                          appointment.appointmentType
                                              .toLowerCase()
                                              .contains('video')
                                      ? Icons.videocam_outlined
                                      : Icons.place_outlined,
                                  size: 12,
                                  color: cl.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.appointmentType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: muted
                                        ? cl.textLight
                                            .withValues(alpha: 0.55)
                                        : cl.textLight,
                                    fontFamily: 'Satoshi',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: muted
                            ? statusColor.withValues(alpha: 0.3)
                            : statusColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: cl.textLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // DM unread count badge — top-right corner of the card.
          if (dmUnread > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cl.bg, width: 1.5),
                ),
                child: Text(
                  dmUnread > 99 ? '99+' : '$dmUnread',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'confirmed' => const Color(0xFF22A64A),
      'pending' => const Color(0xFFE59300),
      'cancelled' => const Color(0xFFD63031),
      _ => const Color(0xFF6B7280),
    };
  }
}

// ── New badge ─────────────────────────────────────────────────────────────────

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cl.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.apptBadgeNew,
        style: GoogleFonts.nunito(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.appointment, this.muted = false});

  final AppointmentEntity appointment;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = appointment.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pillBg, pillFg;
    final String label;

    if (status == 'pending') {
      pillBg = isDark ? const Color(0xFF181509) : const Color(0xFFFFF4DE);
      pillFg = isDark ? const Color(0xFF7A621A) : const Color(0xFFB26A00);
      label = l10n.apptStatusPending;
    } else if (status == 'confirmed') {
      pillBg = isDark ? const Color(0xFF0D1A10) : const Color(0xFFE9F9EE);
      pillFg = isDark ? const Color(0xFF2D7A48) : const Color(0xFF1E7E34);
      label = l10n.apptStatusAccepted;
    } else if (status == 'cancelled') {
      pillBg = isDark ? const Color(0xFF1A0D0E) : const Color(0xFFFFEAEA);
      pillFg = isDark ? const Color(0xFF8B3040) : const Color(0xFFB02A37);
      label = appointment.isClientCancellation
          ? l10n.apptStatusCancelled
          : l10n.apptStatusDeclined;
    } else {
      pillBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF3F4F6);
      pillFg = const Color(0xFF6B7280);
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: muted ? pillBg.withValues(alpha: 0.5) : pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: muted ? pillFg.withValues(alpha: 0.55) : pillFg,
        ),
      ),
    );
  }
}
