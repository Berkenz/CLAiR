import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/dialogs/guest_auth_prompt.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/appointments/data/datasources/appointment_remote_datasource.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/lawyer/data/datasources/lawyer_remote_datasource.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_attachments_section.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_display_avatar.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/spring_button.dart';

/// Shows a prompt asking the guest to log in or sign up before booking.
/// Returns `true` if the user is a guest (i.e. booking should be blocked).
bool showGuestBookingPrompt(BuildContext context, WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  if (user?.isAnonymous != true) return false;

  final l10n = AppLocalizations.of(context)!;
  showGuestAuthPrompt(
    context,
    title: l10n.guestAuthBookingTitle,
    message: l10n.guestAuthBookingMessage,
  );
  return true;
}

Future<void> showLawyerBookingSheet(
  BuildContext context,
  LawyerEntity lawyer, {
  String? preAttachedConversationId,
  String? preAttachedConversationTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => LawyerBookingSheet(
      lawyer: lawyer,
      preAttachedConversationId: preAttachedConversationId,
      preAttachedConversationTitle: preAttachedConversationTitle,
    ),
  );
}

class LawyerBookingSheet extends ConsumerStatefulWidget {
  const LawyerBookingSheet({
    super.key,
    required this.lawyer,
    this.preAttachedConversationId,
    this.preAttachedConversationTitle,
  });

  final LawyerEntity lawyer;

  /// When non-null the "Attach CLAiR conversation" checkbox is pre-checked
  /// and this conversation is shown. null = current chat.
  final String? preAttachedConversationId;
  final String? preAttachedConversationTitle;

  @override
  ConsumerState<LawyerBookingSheet> createState() =>
      _LawyerBookingSheetState();
}

class _LawyerBookingSheetState extends ConsumerState<LawyerBookingSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _attachConversation = false;
  List<PlatformFile> _pickedFiles = [];

  /// From history picker / Share-to-lawyer; null means submit uses live chat id.
  String? _explicitAttachConversationId;
  String? _explicitAttachConversationTitle;

  bool _loading = false;
  String? _error;

  List<String> _appointmentTypes = const [];
  bool _typesLoading = true;
  String? _typesLoadError;
  String? _selectedAppointmentType;

  @override
  void initState() {
    super.initState();
    _explicitAttachConversationId = widget.preAttachedConversationId;
    _explicitAttachConversationTitle = widget.preAttachedConversationTitle;
    // Pre-check the attachment when opened in sharing mode.
    if (widget.preAttachedConversationTitle != null ||
        widget.preAttachedConversationId != null) {
      _attachConversation = true;
    }
    if (_explicitAttachConversationTitle?.trim().isNotEmpty == true &&
        _titleCtrl.text.isEmpty) {
      _titleCtrl.text = _explicitAttachConversationTitle!.trim();
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadAppointmentTypes());
  }

  Future<void> _loadAppointmentTypes() async {
    final ds = ref.read(appointmentDataSourceProvider);
    if (mounted) {
      setState(() {
        _typesLoading = true;
        _typesLoadError = null;
      });
    }
    try {
      final types = await ds.getAppointmentTypes();
      if (!mounted) return;
      setState(() {
        _appointmentTypes = types;
        _typesLoading = false;
        _typesLoadError = null;
        _selectedAppointmentType =
            types.isNotEmpty ? types.first : null;
      });
    } on AppointmentException catch (e) {
      if (!mounted) return;
      setState(() {
        _typesLoading = false;
        _typesLoadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _typesLoading = false;
        _typesLoadError = friendlyErrorMessage(e);
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _openBookedAppointment(NavigatorState nav, AppointmentEntity appointment) {
    nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit(LawyerRemoteDataSource ds) async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a title for your appointment.');
      return;
    }

    final type = _selectedAppointmentType?.trim();
    if (type == null || type.isEmpty) {
      setState(() => _error = l10n.bookingAppointmentTypeRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final chatState = ref.read(chatProvider);
    final attachedConversationId = _attachConversation
        ? (_explicitAttachConversationId ?? chatState.conversationId)
        : null;

    final descTrim = _descCtrl.text.trim();

    final now = DateTime.now();
    final bookingDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final created = await ds.bookAppointment(
        lawyerProfileId: widget.lawyer.id.trim(),
        appointmentDate: bookingDate,
        appointmentTime: '00:00',
        appointmentType: type,
        caseTitle: title,
        description: descTrim.isEmpty ? null : descTrim,
        attachedConversationId: attachedConversationId,
        files: _pickedFiles,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final rootNav = Navigator.of(context, rootNavigator: true);
      final accent = context.c.accent;
      Navigator.pop(context);

      await ref.read(appointmentProvider.notifier).loadAppointments(force: true);

      messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.bookingSuccessSnackbar,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            backgroundColor: accent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: l10n.bookingViewAppointmentAction,
              textColor: Colors.white,
              onPressed: () => _openBookedAppointment(rootNav, created),
            ),
          ),
        );
    } on LawyerException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final ds = ref.watch(lawyerDataSourceProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: cl.cardShadow,
                blurRadius: 24,
                offset: const Offset(0, -4))
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cl.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),

              // Lawyer mini-header
              Row(children: [
                LawyerDisplayAvatar(
                  lawyer: widget.lawyer,
                  size: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      cl.accent.withValues(alpha: 0.12),
                      cl.accentLight.withValues(alpha: 0.3),
                    ]),
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
                      Text(widget.lawyer.name,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cl.textDark)),
                      if (widget.lawyer.designation != null &&
                          widget.lawyer.designation!.isNotEmpty)
                        Text(widget.lawyer.designation!,
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: cl.textMid)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Divider(height: 1, color: cl.border),
              const SizedBox(height: 20),

              Text('Book an Appointment',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark)),
              const SizedBox(height: 18),

              // Title field
              _fieldLabel(cl, 'Title', Icons.title_rounded,
                  child: Container(
                    decoration: _inputDeco(cl),
                    child: TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: cl.textDark),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Advice on property dispute',
                        hintStyle: GoogleFonts.nunito(
                            fontSize: 13, color: cl.textLight),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  )),
              const SizedBox(height: 14),

              // Appointment type
              _fieldLabel(
                cl,
                l10n.bookingAppointmentTypeLabel,
                Icons.category_outlined,
                child: _typesLoading
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        alignment: Alignment.centerLeft,
                        decoration: _inputDeco(cl),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cl.accent,
                          ),
                        ),
                      )
                    : _typesLoadError != null
                        ? GestureDetector(
                            onTap: _loadAppointmentTypes,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: _inputDeco(cl),
                              child: Text(
                                l10n.bookingAppointmentTypeLoadError,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: _inputDeco(cl),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedAppointmentType != null &&
                                        _appointmentTypes
                                            .contains(_selectedAppointmentType)
                                    ? _selectedAppointmentType
                                    : null,
                                isExpanded: true,
                                hint: Text(
                                  l10n.bookingAppointmentTypeHint,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: cl.textLight,
                                  ),
                                ),
                                items: _appointmentTypes
                                    .map(
                                      (t) => DropdownMenuItem<String>(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            color: cl.textDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => _selectedAppointmentType = v,
                                ),
                              ),
                            ),
                          ),
              ),
              const SizedBox(height: 14),

              // Description
              _fieldLabel(cl, 'Description', Icons.notes_rounded,
                  child: Container(
                    decoration: _inputDeco(cl),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: cl.textDark),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            'Describe your legal concern or question…\n(or use "Summarize with AI" below)',
                        hintStyle: GoogleFonts.nunito(
                            fontSize: 13, color: cl.textLight),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  )),
              const SizedBox(height: 18),

              // Attachments
              LawyerAttachmentsSection(
                attachConversation: _attachConversation,
                onAttachConversationChanged: (v) =>
                    setState(() => _attachConversation = v),
                pickedFiles: _pickedFiles,
                onPickedFilesChanged: (f) => setState(() => _pickedFiles = f),
                initialConversationId: widget.preAttachedConversationId,
                initialConversationTitle: widget.preAttachedConversationTitle,
                onAttachedConversationSelectionChanged: (id, title) =>
                    setState(() {
                  _explicitAttachConversationId = id;
                  _explicitAttachConversationTitle = title;
                }),
                onSummaryGenerated: (text) => setState(() {
                  _descCtrl.value = TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200)),
                  child: Text(_error!,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: Colors.red.shade700)),
                ),
              ],
              const SizedBox(height: 24),

              // Submit
              SpringButton(
                onTap: (_loading || _typesLoading) ? null : () => _submit(ds),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (_loading || _typesLoading)
                        ? cl.accent.withValues(alpha: 0.6)
                        : cl.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: cl.accent.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: (_loading || _typesLoading)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Request appointment',
                            style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cl.textMid)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(AppColorTheme cl, String label, IconData icon,
      {required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: cl.accent),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700, color: cl.accent)),
      ]),
      const SizedBox(height: 6),
      child,
    ]);
  }

  BoxDecoration _inputDeco(AppColorTheme cl) => BoxDecoration(
        color: cl.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cl.border),
      );
}
