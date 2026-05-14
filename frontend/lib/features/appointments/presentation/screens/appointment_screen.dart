import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_detail_screen.dart';
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
    Future.microtask(
        () => ref.read(appointmentProvider.notifier).loadAppointments());
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

      final pending = ref.read(pendingAppointmentDetailIdProvider);
      if (pending == null || next.isLoading) return;

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
              ref
                  .read(appointmentProvider.notifier)
                  .loadAppointments(force: true);
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
    switch (_filter) {
      case _AppointmentListFilter.all:
        return List<AppointmentEntity>.of(list);
      case _AppointmentListFilter.pending:
        return list.where((a) => a.status == 'pending').toList();
      case _AppointmentListFilter.confirmed:
        return list.where((a) => a.status == 'confirmed').toList();
      case _AppointmentListFilter.cancelled:
        return list.where((a) => a.status == 'cancelled').toList();
    }
  }

  void _applySort(List<AppointmentEntity> list) {
    int dateTimeCmp(AppointmentEntity a, AppointmentEntity b) {
      final d = a.appointmentDate.compareTo(b.appointmentDate);
      if (d != 0) return d;
      return a.appointmentTime.compareTo(b.appointmentTime);
    }

    list.sort((a, b) {
      final c = dateTimeCmp(a, b);
      return _sort == _AppointmentListSort.dateOldest ? c : -c;
    });
  }

  Widget _buildBody(AppointmentState state, AppLocalizations l10n) {
    final cl = context.c;

    if (state.isLoading && state.appointments.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.apptMyTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.apptTotalCount(raw.length),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: cl.textMid,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFilterSortRow(cl, l10n)),
          if (_filter == _AppointmentListFilter.all) ...[
            ..._buildGroupedAppointmentSlivers(cl, sorted, l10n),
          ] else ...[
            _buildSectionHeader(
              _filterSectionTitle(l10n),
              sorted.length,
            ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  List<Widget> _buildGroupedAppointmentSlivers(
    AppColorTheme cl,
    List<AppointmentEntity> sorted,
    AppLocalizations l10n,
  ) {
    final active = sorted
        .where((a) => a.status == 'confirmed' || a.status == 'pending')
        .toList();
    final past = sorted.where((a) => a.status == 'cancelled').toList();

    return [
      if (active.isNotEmpty) ...[
        _buildSectionHeader(l10n.apptSectionActivePending, active.length),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AppointmentCard(
                  appointment: active[i],
                  onTap: () => _openDetail(active[i]),
                ),
              ),
              childCount: active.length,
            ),
          ),
        ),
      ],
      if (past.isNotEmpty) ...[
        _buildSectionHeader(l10n.apptSectionPastCancelled, past.length),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AppointmentCard(
                  appointment: past[i],
                  onTap: () => _openDetail(past[i]),
                  muted: true,
                ),
              ),
              childCount: past.length,
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildFilterSortRow(AppColorTheme cl, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.apptFilterAll, style: GoogleFonts.nunito(fontSize: 13)),
                  selected: _filter == _AppointmentListFilter.all,
                  onSelected: (_) =>
                      setState(() => _filter = _AppointmentListFilter.all),
                  selectedColor: cl.accent.withValues(alpha: 0.18),
                  checkmarkColor: cl.accent,
                  labelStyle: TextStyle(
                    color: _filter == _AppointmentListFilter.all
                        ? cl.textDark
                        : cl.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.apptFilterPending, style: GoogleFonts.nunito(fontSize: 13)),
                  selected: _filter == _AppointmentListFilter.pending,
                  onSelected: (_) =>
                      setState(() => _filter = _AppointmentListFilter.pending),
                  selectedColor: cl.accent.withValues(alpha: 0.18),
                  checkmarkColor: cl.accent,
                  labelStyle: TextStyle(
                    color: _filter == _AppointmentListFilter.pending
                        ? cl.textDark
                        : cl.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.apptFilterAccepted, style: GoogleFonts.nunito(fontSize: 13)),
                  selected: _filter == _AppointmentListFilter.confirmed,
                  onSelected: (_) => setState(
                      () => _filter = _AppointmentListFilter.confirmed),
                  selectedColor: cl.accent.withValues(alpha: 0.18),
                  checkmarkColor: cl.accent,
                  labelStyle: TextStyle(
                    color: _filter == _AppointmentListFilter.confirmed
                        ? cl.textDark
                        : cl.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label:
                      Text(l10n.apptFilterCancelled, style: GoogleFonts.nunito(fontSize: 13)),
                  selected: _filter == _AppointmentListFilter.cancelled,
                  onSelected: (_) => setState(
                      () => _filter = _AppointmentListFilter.cancelled),
                  selectedColor: cl.accent.withValues(alpha: 0.18),
                  checkmarkColor: cl.accent,
                  labelStyle: TextStyle(
                    color: _filter == _AppointmentListFilter.cancelled
                        ? cl.textDark
                        : cl.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<_AppointmentListSort>(
              onSelected: (v) => setState(() => _sort = v),
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
                    Icon(Icons.sort_rounded, size: 18, color: cl.accent),
                    const SizedBox(width: 6),
                    Text(
                      _sort == _AppointmentListSort.dateNewest
                          ? l10n.apptSortChipNewest
                          : l10n.apptSortChipOldest,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cl.textDark,
                      ),
                    ),
                    Icon(Icons.expand_more_rounded,
                        color: cl.textMid, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
            Icon(Icons.filter_alt_off_rounded, size: 48, color: cl.textLight),
            const SizedBox(height: 12),
            Text(
              l10n.apptNoFilterMatch,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cl.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  setState(() => _filter = _AppointmentListFilter.all),
              child: Text(
                l10n.apptShowAll,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: cl.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final cl = context.c;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cl.textMid,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cl.fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cl.textMid,
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
      await ref.read(appointmentProvider.notifier).loadAppointments(force: true);
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final cl = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: 38,
              color: cl.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.apptEmptyTitle,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.apptEmptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: cl.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.muted = false,
  });

  final AppointmentEntity appointment;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(appointment.status);
    final date = DateFormat('MMM d, y').format(appointment.appointmentDate);
    final time = _to12Hour(appointment.appointmentTime);

    return SpringButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
          children: [
            // Colored status strip
            Container(
              width: 4,
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(
                color: muted
                    ? statusColor.withValues(alpha: 0.35)
                    : statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.displayCaseTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: muted
                                      ? cl.textDark.withValues(alpha: 0.5)
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
                                  color: cl.textMid,
                                  fontFamily: 'Satoshi',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          appointment: appointment,
                          muted: muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: cl.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$date  •  $time',
                          style: TextStyle(
                            fontSize: 12,
                            color: cl.textMid,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                        const Spacer(),
                        if (appointment.canStartLawyerChat)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cl.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 11,
                                  color: cl.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.apptCardChat,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cl.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cl.textLight,
              ),
            ),
          ],
          ),
        ),
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

  static String _to12Hour(String value) {
    try {
      final parsed = DateFormat('HH:mm').parse(value);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      return value;
    }
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.appointment, this.muted = false});

  final AppointmentEntity appointment;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final status = appointment.status;
    final (Color bg, Color fg, String label) = switch (status) {
      'pending' => (
          const Color(0xFFFFF4DE),
          const Color(0xFFB26A00),
          l10n.apptStatusPending,
        ),
      'confirmed' => (
          const Color(0xFFE9F9EE),
          const Color(0xFF1E7E34),
          l10n.apptStatusAccepted,
        ),
      'cancelled' => appointment.isClientCancellation
          ? (
              const Color(0xFFFFEAEA),
              const Color(0xFFB02A37),
              l10n.apptStatusCancelled,
            )
          : (
              const Color(0xFFFFEAEA),
              const Color(0xFFB02A37),
              l10n.apptStatusDeclined,
            ),
      _ => (cl.fieldBg, cl.textMid, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: muted ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: muted ? fg.withValues(alpha: 0.6) : fg,
        ),
      ),
    );
  }
}
