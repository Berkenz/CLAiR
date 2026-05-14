import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';

/// Persists which appointment row "version" the user last saw in [AppointmentDetailScreen],
/// so list [NEW] badges dismiss after open (Gmail-style) and return if the row updates.
class AppointmentNewBadgeSeenNotifier extends StateNotifier<Map<String, DateTime>> {
  AppointmentNewBadgeSeenNotifier() : super(const {}) {
    _load();
  }

  static const _prefsKey = 'appointment_new_badge_seen_ref_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final next = <String, DateTime>{};
      for (final e in decoded.entries) {
        final k = '${e.key}'.trim();
        final v = e.value;
        if (k.isEmpty || v is! String) continue;
        try {
          next[k] = DateTime.parse(v);
        } catch (_) {
          continue;
        }
      }
      // In-memory entries (e.g. markSeen before load finished) win over disk.
      state = {...next, ...state};
    } catch (_) {}
  }

  Future<void> markSeen(AppointmentEntity appointment) async {
    final id = appointment.id.trim();
    if (id.isEmpty) return;
    final refAt = appointment.updatedAt ?? appointment.createdAt;
    state = {...state, id: refAt};
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, String>{};
    for (final e in state.entries) {
      out[e.key] = e.value.toUtc().toIso8601String();
    }
    await prefs.setString(_prefsKey, jsonEncode(out));
  }
}

final appointmentNewBadgeSeenProvider =
    StateNotifierProvider<AppointmentNewBadgeSeenNotifier, Map<String, DateTime>>(
  (ref) => AppointmentNewBadgeSeenNotifier(),
);
