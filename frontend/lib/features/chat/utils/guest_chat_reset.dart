import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/l10n/app_localizations.dart';

/// True when a guest has sent at least one message in the current session.
bool guestChatHasUnsavedContent(WidgetRef ref) {
  final isGuest = ref.read(currentUserProvider)?.isAnonymous == true;
  if (!isGuest) return false;
  return ref.read(chatProvider).messages.any((m) => m.isUser);
}

/// Shows the clear-chat confirmation for guests. Returns `true` if the user
/// confirmed or no confirmation was needed.
Future<bool> confirmGuestClearChat(BuildContext context) async {
  final cl = context.c;
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.chatGuestClearTitle,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: cl.textDark,
        ),
      ),
      content: Text(
        l10n.chatGuestClearBody,
        style: GoogleFonts.nunito(
          fontSize: 14,
          height: 1.4,
          color: cl.textDark,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.commonCancel,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: cl.textLight,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.chatGuestClearConfirm,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: cl.accent,
            ),
          ),
        ),
      ],
    ),
  );
  return result == true;
}

/// Resets chat after guest confirmation when needed.
/// Returns `true` if reset ran; `false` if the user cancelled.
Future<bool> resetChatWithGuestGuard({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  if (guestChatHasUnsavedContent(ref)) {
    final confirmed = await confirmGuestClearChat(context);
    if (!confirmed) return false;
  }
  ref.read(chatProvider.notifier).reset();
  return true;
}
