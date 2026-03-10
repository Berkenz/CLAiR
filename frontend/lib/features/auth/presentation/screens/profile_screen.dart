import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _currentPasswordCtrl;
  late final TextEditingController _newPasswordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final parts = (user?.displayName ?? '').trim().split(' ');
    _firstNameCtrl =
        TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _lastNameCtrl = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _locationCtrl = TextEditingController();
    _currentPasswordCtrl = TextEditingController();
    _newPasswordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _locationCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    final fi = f.isNotEmpty ? f[0].toUpperCase() : '';
    final li = l.isNotEmpty ? l[0].toUpperCase() : '';
    final combined = '$fi$li';
    return combined.isNotEmpty ? combined : '?';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    // TODO: wire to your auth/user repository to persist changes
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile updated successfully.',
            style:
                TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.darkBrown,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _Header(
            initials: _initials,
            photoUrl: user?.photoUrl,
            onBack: () => Navigator.of(context).pop(),
            onPhotoTap: _pickPhoto,
          ),

          // ── Form ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personal Info ────────────────────────────
                    const _SectionLabel(label: 'Personal Information'),
                    const SizedBox(height: 12),
                    _FormGroup(
                      children: [
                        _FieldTile(
                          label: 'First Name',
                          controller: _firstNameCtrl,
                          icon: Icons.person_outline_rounded,
                          hint: 'Enter first name',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        _FieldTile(
                          label: 'Last Name',
                          controller: _lastNameCtrl,
                          icon: Icons.person_outline_rounded,
                          hint: 'Enter last name',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        _FieldTile(
                          label: 'Location',
                          controller: _locationCtrl,
                          icon: Icons.location_on_outlined,
                          hint: 'e.g. Cebu City, Philippines',
                          isLast: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Change Password ──────────────────────────
                    const _SectionLabel(label: 'Change Password'),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Leave blank if you don\'t want to change your password.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkBrown.withOpacity(0.4),
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ),
                    _FormGroup(
                      children: [
                        _FieldTile(
                          label: 'Current Password',
                          controller: _currentPasswordCtrl,
                          icon: Icons.lock_outline_rounded,
                          hint: '••••••••',
                          obscure: _obscureCurrent,
                          onToggleObscure: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                        _FieldTile(
                          label: 'New Password',
                          controller: _newPasswordCtrl,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Min. 8 characters',
                          obscure: _obscureNew,
                          onToggleObscure: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (v.length < 8) return 'At least 8 characters';
                            return null;
                          },
                        ),
                        _FieldTile(
                          label: 'Confirm New Password',
                          controller: _confirmPasswordCtrl,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Re-enter new password',
                          obscure: _obscureConfirm,
                          onToggleObscure: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          isLast: true,
                          validator: (v) {
                            if (_newPasswordCtrl.text.isEmpty) return null;
                            if (v != _newPasswordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // ── Save ─────────────────────────────────────
                    _SaveButton(isSaving: _isSaving, onTap: _save),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoPickerSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String initials;
  final String? photoUrl;
  final VoidCallback onBack;
  final VoidCallback onPhotoTap;

  const _Header({
    required this.initials,
    required this.photoUrl,
    required this.onBack,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38), // visual balance
                ],
              ),

              const SizedBox(height: 24),

              // Avatar with camera badge
              GestureDetector(
                onTap: onPhotoTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child:
                                  Image.network(photoUrl!, fit: BoxFit.cover),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Satoshi',
                                ),
                              ),
                            ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Tap to change photo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.45),
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.darkBrown.withOpacity(0.35),
        fontFamily: 'Satoshi',
      ),
    );
  }
}

class _FormGroup extends StatelessWidget {
  final List<Widget> children;
  const _FormGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 54,
                  color: AppColors.darkBrown.withOpacity(0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final bool isLast;

  const _FieldTile({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon chip
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.darkBrown.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.darkBrown),
          ),
          const SizedBox(width: 14),
          // Label + text field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown.withOpacity(0.4),
                    fontFamily: 'Satoshi',
                    letterSpacing: 0.3,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  obscureText: obscure,
                  validator: validator,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkBrown,
                    fontFamily: 'Satoshi',
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBrown.withOpacity(0.25),
                      fontFamily: 'Satoshi',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    suffixIcon: onToggleObscure != null
                        ? GestureDetector(
                            onTap: onToggleObscure,
                            child: Icon(
                              obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.darkBrown.withOpacity(0.3),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save Button
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onTap;

  const _SaveButton({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isSaving ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Satoshi',
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBrown.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Change Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 16),
          _PhotoOption(
            icon: Icons.camera_alt_rounded,
            label: 'Take a Photo',
            onTap: () {
              Navigator.pop(context);
              // TODO: ImagePicker(source: ImageSource.camera)
            },
          ),
          Divider(
              height: 1,
              indent: 60,
              color: AppColors.darkBrown.withOpacity(0.07)),
          _PhotoOption(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () {
              Navigator.pop(context);
              // TODO: ImagePicker(source: ImageSource.gallery)
            },
          ),
          Divider(
              height: 1,
              indent: 60,
              color: AppColors.darkBrown.withOpacity(0.07)),
          _PhotoOption(
            icon: Icons.delete_outline_rounded,
            label: 'Remove Photo',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              // TODO: clear photoUrl from user profile
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.crimson : AppColors.darkBrown;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
