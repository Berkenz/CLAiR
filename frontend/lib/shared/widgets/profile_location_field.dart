import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/services/nominatim_service.dart';
import 'package:clair/core/theme/app_colors.dart';

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});

/// Location text field with GPS-based suggestion and address autocomplete.
class ProfileLocationField extends ConsumerStatefulWidget {
  const ProfileLocationField({
    super.key,
    required this.controller,
    this.label = 'Location',
    this.hint = 'e.g. Cebu City',
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  ConsumerState<ProfileLocationField> createState() =>
      _ProfileLocationFieldState();
}

class _ProfileLocationFieldState extends ConsumerState<ProfileLocationField> {
  final _focusNode = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  String? _gpsSuggestion;
  bool _loadingSuggestions = false;
  bool _resolvingGps = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGpsSuggestionIfNeeded();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.controller.text.trim().isNotEmpty) {
        _gpsSuggestion = null;
      }
    });
    _scheduleSearch(widget.controller.text);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _loadGpsSuggestionIfNeeded();
      if (_suggestions.isNotEmpty) {
        setState(() {});
      }
    }
  }

  Future<void> _loadGpsSuggestionIfNeeded() async {
    if (widget.controller.text.trim().isNotEmpty) return;
    if (_resolvingGps || _gpsSuggestion != null) return;

    setState(() => _resolvingGps = true);

    try {
      var loc = ref.read(locationProvider);
      if (!loc.hasLocation) {
        await ref.read(locationProvider.notifier).fetchLocation();
        loc = ref.read(locationProvider);
      }
      if (!loc.hasLocation || !mounted) return;

      final label = await ref.read(nominatimServiceProvider).reverseGeocode(
            loc.latitude!,
            loc.longitude!,
          );
      if (!mounted || label == null || label.isEmpty) return;
      if (widget.controller.text.trim().isNotEmpty) return;

      setState(() => _gpsSuggestion = label);
    } catch (_) {
      // Optional feature — ignore failures.
    } finally {
      if (mounted) setState(() => _resolvingGps = false);
    }
  }

  void _scheduleSearch(String query) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.length < 3) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
        _searchError = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loadingSuggestions = true;
      _searchError = null;
    });

    try {
      final loc = ref.read(locationProvider);
      final results = await ref.read(nominatimServiceProvider).searchPlaces(
            query,
            nearLat: loc.latitude,
            nearLng: loc.longitude,
          );
      if (!mounted || widget.controller.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
        if (results.isEmpty) {
          _searchError = 'No matches. Try a different spelling.';
        }
      });
    } catch (_) {
      if (!mounted || widget.controller.text.trim() != query) return;
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
        _searchError = 'Could not load suggestions. Check your connection.';
      });
    }
  }

  void _applySuggestion(String value) {
    widget.controller.text = value;
    widget.controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() {
      _suggestions = [];
      _gpsSuggestion = null;
      _searchError = null;
    });
    _focusNode.unfocus();
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _searchError = null;
      _gpsSuggestion = null;
      _suggestions = [];
    });

    final ok = await ref.read(locationProvider.notifier).fetchLocation();
    final loc = ref.read(locationProvider);
    if (!ok || !loc.hasLocation) {
      if (!mounted) return;
      setState(() {
        _searchError = loc.error ?? 'Could not get your location.';
      });
      return;
    }

    setState(() => _resolvingGps = true);
    try {
      final label = await ref.read(nominatimServiceProvider).reverseGeocode(
            loc.latitude!,
            loc.longitude!,
          );
      if (!mounted) return;
      if (label == null || label.isEmpty) {
        setState(() {
          _searchError =
              'Got your coordinates but could not resolve a place name.';
        });
        return;
      }
      _applySuggestion(label);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Could not resolve your location. Try typing it.';
      });
    } finally {
      if (mounted) setState(() => _resolvingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final showGpsChip = _gpsSuggestion != null &&
        widget.controller.text.trim().isEmpty &&
        !_resolvingGps;
    final showSuggestions =
        _focusNode.hasFocus && _suggestions.isNotEmpty && !_loadingSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cl.textMid,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cl.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cl.border),
            boxShadow: [
              BoxShadow(
                color: cl.cardShadow,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cl.textDark,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: widget.hint,
              hintStyle: GoogleFonts.nunito(color: cl.textLight, fontSize: 14),
              prefixIcon:
                  Icon(Icons.location_on_outlined, size: 18, color: cl.textLight),
              suffixIcon: _resolvingGps
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cl.accent,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Use my current location',
                      icon: Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: cl.accent,
                      ),
                      onPressed: _resolvingGps ? null : _useMyLocation,
                    ),
            ),
          ),
        ),
        if (showGpsChip) ...[
          const SizedBox(height: 8),
          Material(
            color: cl.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _applySuggestion(_gpsSuggestion!),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.near_me_rounded, size: 18, color: cl.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use your location: $_gpsSuggestion',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cl.accent,
                        ),
                      ),
                    ),
                    Icon(Icons.add_rounded, size: 18, color: cl.accent),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_loadingSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Searching…',
              style: GoogleFonts.nunito(fontSize: 11, color: cl.textLight),
            ),
          ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _searchError!,
              style: GoogleFonts.nunito(fontSize: 11, color: cl.crimson),
            ),
          ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: cl.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cl.border),
              boxShadow: [
                BoxShadow(
                  color: cl.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: cl.border),
                  InkWell(
                    onTap: () => _applySuggestion(_suggestions[i].label),
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(12) : Radius.zero,
                      bottom: i == _suggestions.length - 1
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: cl.textLight,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _suggestions[i].label,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cl.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
