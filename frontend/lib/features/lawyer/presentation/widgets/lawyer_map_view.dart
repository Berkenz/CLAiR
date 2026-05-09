import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

// Default centre — Philippines
const _kDefaultCentre = LatLng(12.8797, 121.7740);
const _kDefaultZoom = 6.0;

class LawyerMapView extends ConsumerStatefulWidget {
  final List<LawyerEntity> lawyers;
  final void Function(LawyerEntity) onTap;

  const LawyerMapView({
    super.key,
    required this.lawyers,
    required this.onTap,
  });

  @override
  ConsumerState<LawyerMapView> createState() => _LawyerMapViewState();
}

class _LawyerMapViewState extends ConsumerState<LawyerMapView> {
  LawyerEntity? _selected;
  final _mapCtrl = MapController();

  List<LawyerEntity> get _pinned =>
      widget.lawyers.where((l) => l.latitude != null && l.longitude != null).toList();

  Future<void> _goToMyLocation() async {
    final success = await ref.read(locationProvider.notifier).fetchLocation();
    if (success) {
      final loc = ref.read(locationProvider);
      if (loc.latitude != null && loc.longitude != null) {
        _mapCtrl.move(LatLng(loc.latitude!, loc.longitude!), 14);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinned = _pinned;
    final locState = ref.watch(locationProvider);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _kDefaultCentre,
            initialZoom: _kDefaultZoom,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.clair',
            ),
            // User's own location dot
            if (locState.hasLocation)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(locState.latitude!, locState.longitude!),
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            MarkerLayer(
              markers: pinned.map((lawyer) {
                final isSelected = _selected?.id == lawyer.id;
                return Marker(
                  point: LatLng(lawyer.latitude!, lawyer.longitude!),
                  width: 40,
                  height: 48,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = lawyer);
                      _mapCtrl.move(
                        LatLng(lawyer.latitude!, lawyer.longitude!),
                        14,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentDark
                                : AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              lawyer.initials,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(10, 6),
                          painter: _PinTailPainter(
                            color: isSelected
                                ? AppColors.accentDark
                                : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // No lawyers with pins yet
        if (pinned.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_rounded,
                      size: 36, color: AppColors.accentLight),
                  const SizedBox(height: 8),
                  Text(
                    'No office locations set yet',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lawyers can add their location\nfrom the web portal.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // My location FAB
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 3,
            shadowColor: Colors.black26,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: locState.loading ? null : _goToMyLocation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    locState.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: locState.hasLocation
                                ? Colors.blue.shade600
                                : AppColors.accent,
                          ),
                    const SizedBox(width: 6),
                    Text(
                      'My location',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Location error snackbar-style message
        if (locState.error != null)
          Positioned(
            top: 56,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                locState.error!,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),

        // Selected lawyer card
        if (_selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _LawyerMapCard(
              lawyer: _selected!,
              onOpen: () => widget.onTap(_selected!),
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

// Small triangular tail under the pin bubble
class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

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

class _LawyerMapCard extends StatelessWidget {
  final LawyerEntity lawyer;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const _LawyerMapCard({
    required this.lawyer,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  lawyer.initials,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lawyer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lawyer.categoryLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Open button
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('View'),
            ),
            const SizedBox(width: 6),

            // Dismiss
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
