import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/lawyer/presentation/lawyer_practice_l10n.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_display_avatar.dart';
import 'package:clair/l10n/app_localizations.dart';

const _kDefaultCentre = LatLng(12.8797, 121.7740);
const _kDefaultZoom = 6.0;
const _kUserLocationZoom = 14.0;

/// Minimal basemap — less visual noise than default OSM streets.
const _kTileUrl =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

class LawyerMapView extends ConsumerStatefulWidget {
  const LawyerMapView({
    super.key,
    required this.lawyers,
    required this.onTap,
    this.directoryEmpty = false,
    this.noFilterMatches = false,
  });

  /// Lawyers to show (already filtered by search / practice area).
  final List<LawyerEntity> lawyers;
  final void Function(LawyerEntity) onTap;
  final bool directoryEmpty;
  final bool noFilterMatches;

  @override
  ConsumerState<LawyerMapView> createState() => _LawyerMapViewState();
}

class _LawyerMapViewState extends ConsumerState<LawyerMapView> {
  LawyerEntity? _selected;
  final _mapCtrl = MapController();
  bool _autoCenteredOnUser = false;

  List<LawyerEntity> get _pinned => widget.lawyers
      .where((l) => l.latitude != null && l.longitude != null)
      .toList();

  LatLng _centerFor(LocationState loc) {
    if (loc.hasLocation) {
      return LatLng(loc.latitude!, loc.longitude!);
    }
    return _kDefaultCentre;
  }

  double _zoomFor(LocationState loc) =>
      loc.hasLocation ? _kUserLocationZoom : _kDefaultZoom;

  void _centerOnUser({bool force = false}) {
    final loc = ref.read(locationProvider);
    if (!loc.hasLocation) return;
    if (_autoCenteredOnUser && !force) return;
    _autoCenteredOnUser = true;
    _mapCtrl.move(
      LatLng(loc.latitude!, loc.longitude!),
      _kUserLocationZoom,
    );
  }

  Future<void> _goToMyLocation() async {
    final loc = ref.read(locationProvider);
    if (loc.hasLocation) {
      _centerOnUser(force: true);
      return;
    }
    final success = await ref.read(locationProvider.notifier).fetchLocation();
    if (success && mounted) {
      _centerOnUser(force: true);
    }
  }

  void _updateSelection(LawyerEntity? lawyer) {
    if (_selected?.id == lawyer?.id) return;
    setState(() => _selected = lawyer);
    ref.read(lawyerMapSheetOpenProvider.notifier).state = lawyer != null;
  }

  void _selectLawyer(LawyerEntity lawyer) {
    _updateSelection(lawyer);
    _mapCtrl.move(
      LatLng(lawyer.latitude!, lawyer.longitude!),
      _kUserLocationZoom,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = ref.read(locationProvider);
      if (!loc.hasLocation && !loc.loading) {
        await ref.read(locationProvider.notifier).fetchLocation();
      }
      if (mounted) _centerOnUser();
    });
  }

  @override
  void dispose() {
    ref.read(lawyerMapSheetOpenProvider.notifier).state = false;
    super.dispose();
  }

  @override
  void didUpdateWidget(LawyerMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null &&
        !widget.lawyers.any((l) => l.id == _selected!.id)) {
      _updateSelection(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final pinned = _pinned;
    final locState = ref.watch(locationProvider);

    ref.listen<LocationState>(locationProvider, (prev, next) {
      if (next.hasLocation && !(prev?.hasLocation ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _centerOnUser();
        });
      }
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: cl.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _centerFor(locState),
                initialZoom: _zoomFor(locState),
                onMapReady: () => _centerOnUser(),
                onTap: (_, __) => _updateSelection(null),
              ),
              children: [
                TileLayer(
                  urlTemplate: _kTileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.clair.app',
                ),
                if (locState.hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(locState.latitude!, locState.longitude!),
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const _UserLocationMarker(),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: pinned.map((lawyer) {
                    final isSelected = _selected?.id == lawyer.id;
                    return Marker(
                      point: LatLng(lawyer.latitude!, lawyer.longitude!),
                      width: 48,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: _LawyerMapPin(
                        lawyer: lawyer,
                        selected: isSelected,
                        onTap: () => _selectLawyer(lawyer),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Soft top fade so header/search reads cleanly over the map
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cl.surface.withValues(alpha: 0.85),
                        cl.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (pinned.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: _MapChip(
                  icon: Icons.gavel_rounded,
                  label: l10n.lawyerMapPinsCount(pinned.length),
                  cl: cl,
                ),
              ),

            if (widget.noFilterMatches)
              Center(child: _MapMessageState(cl: cl, message: l10n.lawyerMapNoFilterMatches, icon: Icons.search_off_rounded))
            else if (widget.directoryEmpty)
              Center(child: _MapEmptyState(cl: cl))
            else if (widget.lawyers.isNotEmpty && pinned.isEmpty)
              Center(child: _MapMessageState(cl: cl, message: l10n.lawyerMapNoPinsForResults, icon: Icons.location_off_rounded))
            else if (pinned.isEmpty)
              Center(child: _MapEmptyState(cl: cl)),

            Positioned(
              right: 12,
              bottom: _selected != null ? 108 : 16,
              child: _MapCircleButton(
                cl: cl,
                loading: locState.loading,
                active: locState.hasLocation,
                onTap: locState.loading ? null : _goToMyLocation,
                icon: Icons.my_location_rounded,
                tooltip: 'My location',
              ),
            ),

            if (locState.error != null)
              Positioned(
                top: 52,
                left: 12,
                right: 12,
                child: _MapBanner(
                  message: locState.error!,
                  cl: cl,
                  isError: true,
                ),
              ),

            if (_selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _LawyerMapSheet(
                  lawyer: _selected!,
                  cl: cl,
                  l10n: l10n,
                  onOpen: () => widget.onTap(_selected!),
                  onClose: () => _updateSelection(null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── User location ───────────────────────────────────────────────────────────

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB).withValues(alpha: 0.18),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lawyer pin ──────────────────────────────────────────────────────────────

class _LawyerMapPin extends StatelessWidget {
  const _LawyerMapPin({
    required this.lawyer,
    required this.selected,
    required this.onTap,
  });

  final LawyerEntity lawyer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final ring = selected ? cl.accentDark : cl.accent;
    final scale = selected ? 1.08 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cl.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ring,
                  width: selected ? 3 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ring.withValues(alpha: 0.35),
                    blurRadius: selected ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LawyerDisplayAvatar(
                lawyer: lawyer,
                size: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ring, cl.accent],
                  ),
                ),
                initialsStyle: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
              ),
            ),
            CustomPaint(
              size: const Size(12, 7),
              painter: _PinTailPainter(color: ring),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ─── Overlays ────────────────────────────────────────────────────────────────

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.label,
    required this.cl,
  });

  final IconData icon;
  final String label;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cl.surface.withValues(alpha: 0.94),
      elevation: 2,
      shadowColor: cl.cardShadow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cl.border.withValues(alpha: 0.8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cl.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cl.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({
    required this.cl,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.active = false,
    this.tooltip,
  });

  final AppColorTheme cl;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: cl.surface,
      elevation: 3,
      shadowColor: cl.cardShadow,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cl.accent,
                    ),
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: active ? const Color(0xFF2563EB) : cl.accent,
                  ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _MapBanner extends StatelessWidget {
  const _MapBanner({
    required this.message,
    required this.cl,
    this.isError = false,
  });

  final String message;
  final AppColorTheme cl;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isError ? Colors.red.shade50 : cl.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError ? Colors.red.shade200 : cl.border,
          ),
        ),
        child: Text(
          message,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: isError ? Colors.red.shade700 : cl.textMid,
          ),
        ),
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.cl});
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return _MapMessageState(
      cl: cl,
      icon: Icons.map_outlined,
      title: 'No office locations yet',
      message:
          'When lawyers add their office pin on the web portal, they will appear here.',
    );
  }
}

class _MapMessageState extends StatelessWidget {
  const _MapMessageState({
    required this.cl,
    required this.icon,
    this.title,
    required this.message,
  });

  final AppColorTheme cl;
  final IconData icon;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(28),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: cl.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cl.border),
        boxShadow: [
          BoxShadow(
            color: cl.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: cl.accent),
          ),
          if (title != null) ...[
            const SizedBox(height: 12),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: cl.textDark,
              ),
            ),
          ],
          SizedBox(height: title != null ? 6 : 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              height: 1.4,
              color: cl.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerMapSheet extends StatelessWidget {
  const _LawyerMapSheet({
    required this.lawyer,
    required this.cl,
    required this.l10n,
    required this.onOpen,
    required this.onClose,
  });

  final LawyerEntity lawyer;
  final AppColorTheme cl;
  final AppLocalizations l10n;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final areas = lawyer.practiceAreas.take(2).toList();

    return Material(
      color: cl.surface,
      elevation: 8,
      shadowColor: cl.cardShadow,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cl.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cl.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LawyerDisplayAvatar(
                    lawyer: lawyer,
                    size: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cl.accent.withValues(alpha: 0.12),
                          cl.accentLight.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    initialsStyle: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cl.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lawyer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: cl.textDark,
                          ),
                        ),
                        if (lawyer.designation != null &&
                            lawyer.designation!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            localizeLawyerDesignation(
                              l10n,
                              lawyer.designation!,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              color: cl.textMid,
                            ),
                          ),
                        ],
                        if (areas.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: areas
                                .map(
                                  (a) => _AreaPill(
                                    label: localizeLawyerPracticeArea(
                                      l10n,
                                      a,
                                    ),
                                    cl: cl,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, color: cl.textLight),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: cl.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.lawyerViewProfile,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaPill extends StatelessWidget {
  const _AreaPill({required this.label, required this.cl});
  final String label;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cl.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cl.accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: cl.accentDark,
        ),
      ),
    );
  }
}
