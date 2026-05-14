import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/screens/terms_of_use_screen.dart';
import 'package:clair/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:clair/l10n/app_localizations.dart';

/// First step of sign-up: collect first name and last name.
/// Also used when a new Google user needs to provide their name and agree to T&C.
class SignUpNameScreen extends StatefulWidget {
  const SignUpNameScreen({super.key, this.isGoogleFlow = false});

  final bool isGoogleFlow;

  @override
  State<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends State<SignUpNameScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _proceed() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showError(l10n.signupTermsPrivacyRequired);
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (widget.isGoogleFlow) {
      context.push('/signup/google-complete', extra: {
        'first_name': firstName,
        'last_name': lastName,
      });
    } else {
      context.push('/signup/email', extra: {
        'first_name': firstName,
        'last_name': lastName,
      });
    }
  }

  void _showError(String message) {
    final cl = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cl.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isGoogleFlow ? l10n.signupCompleteProfileTitle : l10n.signupTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
            fontFamily: 'Satoshi',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cl.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isGoogleFlow) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cl.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cl.accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.g_mobiledata_rounded, color: cl.accent, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.signupGoogleNameBanner,
                          style: TextStyle(
                            fontSize: 13,
                            color: cl.textMid,
                            fontFamily: 'Satoshi',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // First Name
              _buildInputField(
                context: context,
                controller: _firstNameController,
                label: l10n.signupFirstNameLabel,
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.signupFirstNameRequired : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              _buildInputField(
                context: context,
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
              ),
              const SizedBox(height: 24),

              // T&C Agreement
              _buildTermsCheckbox(context, cl, l10n),
              const SizedBox(height: 24),

              // Proceed Button
              AnimatedOpacity(
                opacity: _agreedToTerms ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [cl.accent, cl.accentDark],
                    ),
                    boxShadow: _agreedToTerms
                        ? [
                            BoxShadow(
                              color: cl.accent.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _agreedToTerms ? _proceed : null,
                      child: Center(
                        child: Text(
                          widget.isGoogleFlow ? l10n.signupCompleteSignUpButton : l10n.signupContinueButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(
      BuildContext context, AppColorTheme cl, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _agreedToTerms ? cl.accent.withOpacity(0.08) : cl.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _agreedToTerms ? cl.accent : cl.border,
            width: _agreedToTerms ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                activeColor: cl.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w400,
                    color: cl.textMid,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: l10n.signupAgreementLead),
                    TextSpan(
                      text: l10n.termsOfUse,
                      style: TextStyle(
                        color: cl.accent,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsOfUseScreen(),
                            ),
                          );
                        },
                    ),
                    TextSpan(text: l10n.signupAgreementMiddle),
                    TextSpan(
                      text: l10n.privacyPolicy,
                      style: TextStyle(
                        color: cl.accent,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                    ),
                    TextSpan(
                      text: l10n.signupAgreementTail,
                      style: TextStyle(color: cl.textMid),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    final cl = context.c;
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: cl.textDark,
        fontFamily: 'Satoshi',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14,
          color: cl.textMid,
          fontFamily: 'Satoshi',
        ),
        prefixIcon: Icon(icon, color: cl.accent.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: cl.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cl.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cl.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cl.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
