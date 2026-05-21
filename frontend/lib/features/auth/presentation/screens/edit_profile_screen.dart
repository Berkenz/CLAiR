import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/utils/profile_photo_crop.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/shared/widgets/profile_photo_image.dart';
import 'package:clair/shared/widgets/profile_location_field.dart';
import 'package:clair/shared/widgets/spring_button.dart';
import 'package:clair/core/services/location_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _locationCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastCtrl = TextEditingController(text: user?.lastName ?? '');
    _locationCtrl = TextEditingController(text: user?.location ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).prefetchIfNeeded();
    });
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final f = _firstCtrl.text.trim();
    final l = _lastCtrl.text.trim();
    final fi = f.isNotEmpty ? f[0].toUpperCase() : '';
    final li = l.isNotEmpty ? l[0].toUpperCase() : '';
    return '$fi$li'.isNotEmpty ? '$fi$li' : '?';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade600 : context.c.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _pickAndUploadPhoto() async {
    final file = await pickAndCropProfilePhoto(context);
    if (file == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final updatedUser = await repo.updateProfilePhoto(file);
      ref.read(currentUserProvider.notifier).state = updatedUser;
      ref.read(profilePhotoCacheVersionProvider.notifier).state++;
      _showSnackBar('Photo updated');
    } catch (e) {
      _showSnackBar(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final updatedUser = await repo.updateProfile(
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
      );
      ref.read(currentUserProvider.notifier).state = updatedUser;
      _showSnackBar('Profile updated');
    } catch (e) {
      _showSnackBar(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final user = ref.watch(currentUserProvider);
    final photoCacheVersion = ref.watch(profilePhotoCacheVersionProvider);

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: cl.surface, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 4, offset: const Offset(0, 1))]),
                  child: Icon(Icons.arrow_back_rounded, color: cl.textDark, size: 20),
                ),
              ),
              const Spacer(),
              Text('Edit Profile', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: cl.textDark)),
              const Spacer(),
              const SizedBox(width: 38),
            ]),
          ),
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cl.accent.withValues(alpha: 0.12), cl.accentLight.withValues(alpha: 0.3)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: user?.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ProfilePhotoImage(
                      photoUrl: user!.photoUrl!,
                      updatedAt: user.updatedAt,
                      cacheVersion: photoCacheVersion,
                      width: 80,
                      height: 80,
                    ),
                  )
                : Center(child: Text(_initials, style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: cl.accent))),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _saving ? null : _pickAndUploadPhoto,
            child: Text('Change Photo', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: cl.accent)),
          ),
          const SizedBox(height: 20),

          // Form
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionLabel('Personal Information'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field('First Name', _firstCtrl, Icons.person_outline_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _field('Last Name', _lastCtrl, Icons.person_outline_rounded)),
              ]),
              const SizedBox(height: 12),
              ProfileLocationField(controller: _locationCtrl),

              const SizedBox(height: 32),
              SpringButton(
                onTap: _save,
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cl.accent, cl.accentDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: cl.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String s) => Text(s, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: context.c.textMid));

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {String? hint, bool isPass = false, bool obscure = false, VoidCallback? onToggle}) {
    final cl = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: cl.textMid)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cl.border),
          boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: TextField(
          controller: ctrl,
          obscureText: isPass && obscure,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: cl.textDark),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: hint ?? (isPass ? '••••••••' : ''),
            hintStyle: GoogleFonts.nunito(color: cl.textLight, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: cl.textLight),
            suffixIcon: isPass
                ? IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: cl.textLight), onPressed: onToggle)
                : null,
          ),
        ),
      ),
    ]);
  }
}
