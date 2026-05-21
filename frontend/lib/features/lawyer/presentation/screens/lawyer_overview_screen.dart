import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/sheets/lawyer_booking_sheet.dart';
import 'package:clair/features/lawyer/presentation/sheets/lawyer_concern_sheet.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_display_avatar.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_map_view.dart';
import 'package:clair/shared/widgets/spring_button.dart';

// ─── Days meta ────────────────────────────────────────────────────────────────

const _kDayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _kDayLabels = <String, String>{
  'mon': 'Monday',
  'tue': 'Tuesday',
  'wed': 'Wednesday',
  'thu': 'Thursday',
  'fri': 'Friday',
  'sat': 'Saturday',
  'sun': 'Sunday',
};

/// Full professional lawyer profile screen shown before booking.
class LawyerOverviewScreen extends ConsumerWidget {
  const LawyerOverviewScreen({super.key, required this.lawyer});

  final LawyerEntity lawyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;

    return Scaffold(
      backgroundColor: cl.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _ProfileHeader(lawyer: lawyer, cl: cl),

          // ── Scrollable body ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Practice areas
                  if (lawyer.practiceAreas.isNotEmpty) ...[
                    _SectionTitle(label: 'Practice Areas', cl: cl),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lawyer.practiceAreas.map((area) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cl.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: cl.accent.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            area,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cl.accent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // About (bio)
                  _InfoCard(
                    cl: cl,
                    icon: Icons.person_outline_rounded,
                    title: 'About',
                    child: Text(
                      lawyer.bioOrDefault,
                      style: GoogleFonts.nunito(
                          fontSize: 13.5, height: 1.55, color: cl.textDark),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Office location — mini-map if coordinates available
                  _LocationCard(lawyer: lawyer, cl: cl),
                  const SizedBox(height: 14),

                  // Office hours — structured day list or fallback
                  _HoursCard(lawyer: lawyer, cl: cl),
                  const SizedBox(height: 14),

                  // Contact details
                  if (lawyer.hasContactInfo) ...[
                    _ContactCard(lawyer: lawyer, cl: cl),
                    const SizedBox(height: 14),
                  ],

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cl.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cl.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15, color: cl.textLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This directory lists verified, registered lawyers. '
                            'CLAiR does not endorse any listed professional.',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: cl.textLight,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Action bar ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: cl.surface,
              border: Border(top: BorderSide(color: cl.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpringButton(
                    onTap: () {
                      if (showGuestBookingPrompt(context, ref)) return;
                      showLawyerBookingSheet(context, lawyer);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cl.accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: cl.accent.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 17, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Book appointment',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cl.textMid,
                        side: BorderSide(color: cl.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => showLawyerConcernSheet(context, lawyer),
                      icon: Icon(Icons.flag_outlined,
                          size: 16, color: cl.textMid),
                      label: Text(
                        'Report concern',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Location card ─────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    final hasCoords = lawyer.latitude != null && lawyer.longitude != null;
    final hasAddress = lawyer.officeLocation?.trim().isNotEmpty ?? false;

    return _InfoCard(
      cl: cl,
      icon: Icons.location_on_outlined,
      title: 'Office',
      child: hasCoords
          ? _MiniMap(lawyer: lawyer, cl: cl)
          : Text(
              hasAddress
                  ? lawyer.officeLocation!
                  : 'Provided when your appointment is confirmed.',
              style: GoogleFonts.nunito(
                  fontSize: 13, height: 1.45, color: cl.textDark),
            ),
    );
  }
}

void _openFullLawyerMap(BuildContext context, LawyerEntity lawyer) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => _FullMapScreen(lawyer: lawyer),
    ),
  );
}

Marker _lawyerOfficeMarker(LawyerEntity lawyer) {
  return Marker(
    point: LatLng(lawyer.latitude!, lawyer.longitude!),
    width: kLawyerPinMarkerWidthSelected,
    height: kLawyerPinMarkerHeightSelected,
    alignment: Alignment.topCenter,
    child: LawyerMapPin(
      lawyer: lawyer,
      selected: true,
      onTap: () {},
    ),
  );
}

/// Compact non-interactive map preview that opens a full-screen map on tap.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lawyer.latitude!, lawyer.longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lawyer.officeLocation?.trim().isNotEmpty ?? false) ...[
          Text(
            lawyer.officeLocation!,
            style: GoogleFonts.nunito(
                fontSize: 12.5, height: 1.4, color: cl.textMid),
          ),
          const SizedBox(height: 10),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cl.border),
            boxShadow: [
              BoxShadow(
                color: cl.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 176,
              child: Stack(
                children: [
                  LawyerMapChrome(
                    cl: cl,
                    topFade: false,
                    bottomFade: true,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: kLawyerMapPinZoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        lawyerBasemapTileLayer(context),
                        MarkerLayer(markers: [_lawyerOfficeMarker(lawyer)]),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openFullLawyerMap(context, lawyer),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IgnorePointer(
                      child: _TapToExpandHint(cl: cl),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TapToExpandHint extends StatelessWidget {
  const _TapToExpandHint({required this.cl});
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cl.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cl.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: cl.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full_rounded, size: 12, color: cl.accent),
          const SizedBox(width: 5),
          Text(
            'Tap to expand',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: cl.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen map screen pushed when the user taps the mini-map.
class _FullMapScreen extends ConsumerStatefulWidget {
  const _FullMapScreen({required this.lawyer});
  final LawyerEntity lawyer;

  @override
  ConsumerState<_FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends ConsumerState<_FullMapScreen> {
  final _mapCtrl = MapController();

  LatLng get _officePoint =>
      LatLng(widget.lawyer.latitude!, widget.lawyer.longitude!);

  void _frameMap() {
    final hasAddress =
        widget.lawyer.officeLocation?.trim().isNotEmpty ?? false;
    fitLawyerMapToOfficeAndUser(
      _mapCtrl,
      office: _officePoint,
      loc: ref.read(locationProvider),
      padding: EdgeInsets.fromLTRB(48, 48, 48, hasAddress ? 120 : 48),
    );
  }

  Future<void> _goToMyLocation() async {
    var loc = ref.read(locationProvider);
    if (!loc.hasLocation) {
      final ok =
          await ref.read(locationProvider.notifier).fetchLocation(force: true);
      if (!ok || !mounted) return;
      loc = ref.read(locationProvider);
    }
    if (!loc.hasLocation) return;
    _mapCtrl.move(
      LatLng(loc.latitude!, loc.longitude!),
      kLawyerMapPinZoom,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).prefetchIfNeeded();
      if (mounted) _frameMap();
    });
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final lawyer = widget.lawyer;
    final point = _officePoint;
    final hasAddress = lawyer.officeLocation?.trim().isNotEmpty ?? false;
    final locState = ref.watch(locationProvider);

    ref.listen<LocationState>(locationProvider, (prev, next) {
      if (next.hasLocation && !(prev?.hasLocation ?? false) && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _frameMap();
        });
      }
    });

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.surface,
        foregroundColor: cl.textDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: cl.textDark,
        ),
        title: Text(lawyer.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cl.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          LawyerMapChrome(
            cl: cl,
            topFade: false,
            bottomFade: hasAddress,
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: point,
                initialZoom: kLawyerMapPinZoom,
                onMapReady: _frameMap,
                onMapEvent: (_) => setState(() {}),
              ),
              children: [
                lawyerBasemapTileLayer(context),
                ...lawyerMapUserLocationLayers(loc: locState, cl: cl),
                MarkerLayer(markers: [_lawyerOfficeMarker(lawyer)]),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: hasAddress ? 88 : 24,
            child: LawyerMapControlRail(
              cl: cl,
              mapController: _mapCtrl,
              loading: locState.loading,
              locationActive: locState.hasLocation,
              onMyLocation: locState.loading ? null : _goToMyLocation,
            ),
          ),
          if (hasAddress)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cl.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cl.border),
                  boxShadow: [
                    BoxShadow(
                        color: cl.cardShadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 16, color: cl.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lawyer.officeLocation!,
                        style: GoogleFonts.nunito(
                            fontSize: 13, color: cl.textDark, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Hours card ────────────────────────────────────────────────────────────────

class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      cl: cl,
      icon: Icons.schedule_rounded,
      title: 'Office Hours',
      child: _buildHoursContent(),
    );
  }

  Widget _buildHoursContent() {
    final raw = lawyer.officeHoursData;
    if (raw == null || raw.isEmpty) {
      return Text(
        'Typical weekday hours apply; confirm after booking.',
        style: GoogleFonts.nunito(fontSize: 13, height: 1.45, color: cl.textDark),
      );
    }

    final rows = <Widget>[];
    for (final day in _kDayOrder) {
      final dayData = raw[day] as Map<String, dynamic>?;
      if (dayData == null) continue;
      final enabled = dayData['enabled'] as bool? ?? false;
      final label = _kDayLabels[day] ?? day;
      final ranges = dayData['ranges'] as List<dynamic>?;
      String timeText;
      if (!enabled || ranges == null || ranges.isEmpty) {
        timeText = 'Closed';
      } else {
        final range = ranges.first as Map<String, dynamic>;
        final start = range['start'] as String? ?? '';
        final end = range['end'] as String? ?? '';
        timeText = '$start – $end';
      }

      if (rows.isNotEmpty) {
        rows.add(Divider(height: 1, thickness: 0.5, color: cl.border));
      }
      rows.add(_DayRow(
        cl: cl,
        label: label,
        timeText: timeText,
        enabled: enabled,
      ));
    }

    return Column(children: rows);
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.cl,
    required this.label,
    required this.timeText,
    required this.enabled,
  });
  final AppColorTheme cl;
  final String label;
  final String timeText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: enabled ? cl.textDark : cl.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              timeText,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: enabled ? cl.textDark : cl.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      cl: cl,
      icon: Icons.contact_phone_outlined,
      title: 'Contact',
      child: Column(
        children: [
          if (lawyer.mobilePhone?.trim().isNotEmpty ?? false) ...[
            _ContactRow(
              cl: cl,
              icon: Icons.phone_android_rounded,
              label: lawyer.mobilePhone!.trim(),
              onTap: () => _launch('tel:${lawyer.mobilePhone!.trim()}'),
            ),
            const SizedBox(height: 8),
          ],
          if (lawyer.officePhone?.trim().isNotEmpty ?? false) ...[
            _ContactRow(
              cl: cl,
              icon: Icons.phone_outlined,
              label: lawyer.officePhone!.trim(),
              onTap: () => _launch('tel:${lawyer.officePhone!.trim()}'),
            ),
            const SizedBox(height: 8),
          ],
          if (lawyer.officeEmail?.trim().isNotEmpty ?? false)
            _ContactRow(
              cl: cl,
              icon: Icons.mail_outline_rounded,
              label: lawyer.officeEmail!.trim(),
              onTap: () => _launch('mailto:${lawyer.officeEmail!.trim()}'),
            ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.cl,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final AppColorTheme cl;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cl.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: cl.accent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: cl.accent.withValues(alpha: 0.4),
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cl.textLight),
        ],
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(bottom: BorderSide(color: cl.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: cl.textDark),
                  ),
                  const Spacer(),
                  // Verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 13, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Avatar + identity
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  LawyerDisplayAvatar(
                    lawyer: lawyer,
                    size: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cl.accent.withValues(alpha: 0.14),
                          cl.accentLight.withValues(alpha: 0.35),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: cl.accent.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    initialsStyle: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cl.accent,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + designation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lawyer.name,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cl.textDark,
                            height: 1.2,
                          ),
                        ),
                        if (lawyer.designation != null &&
                            lawyer.designation!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: cl.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lawyer.designation!,
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: cl.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section widgets ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.cl});
  final String label;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: cl.textLight,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.cl,
    required this.icon,
    required this.title,
    required this.child,
  });

  final AppColorTheme cl;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cl.border),
        boxShadow: [
          BoxShadow(
              color: cl.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: cl.accent),
              const SizedBox(width: 7),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: cl.textMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
