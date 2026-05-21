import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/chat/utils/guest_chat_reset.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_overview_screen.dart';
import 'package:clair/features/lawyer/presentation/widgets/lawyer_display_avatar.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class _QuickAction {
  final IconData icon;
  final String Function(AppLocalizations l) label;
  final Color color;
  final int tabIndex;
  final bool resetChat;
  const _QuickAction(this.icon, this.label, this.color, this.tabIndex,
      [this.resetChat = false]);
}

List<_QuickAction> _quickActions(Color accent) => [
      _QuickAction(
          Icons.chat_bubble_outline_rounded,
          (l) => l.navChat,
          accent,
          1,
          true),
      _QuickAction(Icons.balance_rounded, (l) => l.navLawyers,
          const Color(0xFF6B8A7A), 3),
      _QuickAction(Icons.library_books_outlined, (l) => l.navLibrary,
          const Color(0xFF8B7A6A), 2),
    ];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    Future.microtask(() {
      final lawyerState = ref.read(lawyerProvider);
      if (lawyerState.lawyers.isEmpty && !lawyerState.isLoading) {
        ref.read(lawyerProvider.notifier).loadLawyers();
      }
      final userId = ref.read(currentUserProvider)?.id;
      ref.read(historyProvider.notifier).syncWithUser(userId);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  CurvedAnimation _stagger(double start) => CurvedAnimation(
      parent: _anim,
      curve: Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut));

  Widget _fadeSlide(Widget w, double start) {
    final a = _stagger(start);
    return FadeTransition(
        opacity: a,
        child: SlideTransition(
            position: Tween(
                    begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(a),
            child: w));
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final lawyerState = ref.watch(lawyerProvider);
    final historyState = ref.watch(historyProvider);
    final firstName = user == null
        ? null
        : (user.firstName ?? user.displayName.split(' ').first);
    final greeting =
        firstName == null ? l10n.homeHelloGuest : l10n.homeHelloName(firstName);
    final quickActions = _quickActions(cl.accent);

    // Pick first 2 lawyers
    final suggestedLawyers = lawyerState.lawyers.take(2).toList();

    // Most recent 3 saved/pinned conversations
    final savedConvs = historyState.conversations
        .where((c) => c.isPinned)
        .toList()
      ..sort((a, b) {
        final ta = a.updatedAt ?? a.createdAt;
        final tb = b.updatedAt ?? b.createdAt;
        return tb.compareTo(ta);
      });
    final recentSaved = savedConvs.take(3).toList();

    return Column(children: [
      const ClairAppBar(),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cl.surface, cl.bg]),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              _fadeSlide(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting,
                      style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: cl.textDark)),
                  const SizedBox(height: 4),
                  Text(l10n.homeTagline,
                      style:
                          GoogleFonts.nunito(fontSize: 14, color: cl.textMid)),
                ]),
                0.0,
              ),
              const SizedBox(height: 16),

              _fadeSlide(
                SpringButton(
                  onTap: () async {
                    if (!await resetChatWithGuestGuard(
                          context: context,
                          ref: ref,
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    ref.read(mainShellTabProvider.notifier).state = 1;
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cl.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cl.border),
                      boxShadow: [
                        BoxShadow(
                            color: cl.cardShadow,
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cl.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add_comment_rounded,
                              size: 19, color: cl.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.homeStartNewChatTitle,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: cl.textDark,
                                ),
                              ),
                              Text(
                                l10n.homeStartNewChatSubtitle,
                                style: GoogleFonts.nunito(
                                    fontSize: 12, color: cl.textMid),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded,
                            size: 18, color: cl.textLight),
                      ],
                    ),
                  ),
                ),
                0.08,
              ),
              const SizedBox(height: 18),

              _fadeSlide(
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    l10n.homeQuickActions,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cl.textMid,
                    ),
                  ),
                ),
                0.1,
              ),
              const SizedBox(height: 10),

              _fadeSlide(
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: quickActions
                      .map((a) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 60) / 3,
                            child: _chip(a, context, ref),
                          ))
                      .toList(),
                ),
                0.14,
              ),
              const SizedBox(height: 28),

              // ── Suggested Lawyers ──────────────────────────────────────────
              _fadeSlide(
                _sectionHead(
                  l10n.homeSuggestedLawyers,
                  l10n.homeSeeAll,
                  () => ref.read(mainShellTabProvider.notifier).state = 3,
                ),
                0.2,
              ),
              const SizedBox(height: 12),
              _fadeSlide(
                _buildLawyersRow(
                    lawyerState.isLoading, suggestedLawyers, l10n),
                0.25,
              ),
              const SizedBox(height: 28),

              // ── Saved Chats quick-access ──────────────────────────────────
              if (recentSaved.isNotEmpty) ...[
                _fadeSlide(
                  _sectionHead(
                    l10n.homeSavedChats,
                    l10n.homeSeeAll,
                    () {
                      ref.read(librarySegmentProvider.notifier).state = 1;
                      ref.read(mainShellTabProvider.notifier).state = 2;
                    },
                  ),
                  0.35,
                ),
                const SizedBox(height: 10),
                ...recentSaved.asMap().entries.map((e) => _fadeSlide(
                    _savedChatRow(e.value), 0.4 + e.key * 0.05)),
              ],

              const SizedBox(height: 28),
            ]),
          ),
        ),
      ),
    ]);
  }

  // ── Lawyers section ──────────────────────────────────────────────────────

  Widget _buildLawyersRow(
      bool isLoading, List<LawyerEntity> lawyers, AppLocalizations l10n) {
    if (isLoading && lawyers.isEmpty) {
      return Row(children: [
        Expanded(child: _LawyerSkeleton()),
        const SizedBox(width: 12),
        Expanded(child: _LawyerSkeleton()),
      ]);
    }
    if (lawyers.isEmpty) {
      return _LawyerEmptyCard();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _lawyerCard(lawyers[0], l10n)),
        if (lawyers.length > 1) ...[
          const SizedBox(width: 12),
          Expanded(child: _lawyerCard(lawyers[1], l10n)),
        ] else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _lawyerCard(LawyerEntity lawyer, AppLocalizations l10n) {
    final cl = context.c;
    return SpringButton(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LawyerOverviewScreen(lawyer: lawyer),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
                color: cl.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LawyerDisplayAvatar(
            lawyer: lawyer,
            size: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                cl.accent.withValues(alpha: 0.1),
                cl.accentLight.withValues(alpha: 0.25)
              ]),
              borderRadius: BorderRadius.circular(13),
            ),
            initialsStyle: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: cl.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(lawyer.name,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cl.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(lawyer.specialty,
              style: GoogleFonts.nunito(fontSize: 11, color: cl.textMid),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (lawyer.practiceAreas.length > 1) ...[
            const SizedBox(height: 3),
            Text(
              lawyer.categoryLine,
              style: GoogleFonts.nunito(fontSize: 10, color: cl.textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cl.accent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: cl.accent.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Text(l10n.homeConnect,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  // ── Saved chats section ──────────────────────────────────────────────────

  Widget _savedChatRow(ConversationEntity conv) {
    final cl = context.c;
    final date = DateFormat('MMM d, y')
        .format(conv.updatedAt ?? conv.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SpringButton(
        onTap: () {
          ref.read(chatProvider.notifier).loadConversation(
                conv.id,
                title: conv.title,
                isPinned: conv.isPinned,
              );
          ref.read(mainShellTabProvider.notifier).state = 1;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cl.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cl.border),
            boxShadow: [
              BoxShadow(
                  color: cl.cardShadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bookmark_rounded,
                    color: Color(0xFFE9A020), size: 17)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(conv.title,
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cl.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(
                    date,
                    style: GoogleFonts.nunito(fontSize: 11, color: cl.textMid),
                  ),
                ])),
            Icon(Icons.chevron_right_rounded, size: 18, color: cl.textLight),
          ]),
        ),
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────

  Widget _chip(_QuickAction a, BuildContext ctx, WidgetRef ref) {
    final cl = ctx.c;
    final l10n = AppLocalizations.of(ctx)!;
    return SpringButton(
      onTap: () async {
        if (a.resetChat) {
          if (!await resetChatWithGuestGuard(context: ctx, ref: ref) ||
              !ctx.mounted) {
            return;
          }
        }
        ref.read(mainShellTabProvider.notifier).state = a.tabIndex;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
                color: cl.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(a.icon, color: a.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(a.label(l10n),
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cl.textDark)),
        ]),
      ),
    );
  }

  Widget _sectionHead(String title, String action, VoidCallback onAction) {
    final cl = context.c;
    return Row(
      children: [
        Flexible(
          child: Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cl.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(action,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cl.accent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

// ── Skeleton helpers ──────────────────────────────────────────────────────────

class _LawyerSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cl.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _shimmer(cl, 42, 42, radius: 13),
        const SizedBox(height: 10),
        _shimmer(cl, double.infinity, 12, radius: 6),
        const SizedBox(height: 5),
        _shimmer(cl, 80, 10, radius: 5),
        const SizedBox(height: 10),
        _shimmer(cl, double.infinity, 32, radius: 10),
      ]),
    );
  }

  Widget _shimmer(AppColorTheme cl, double w, double h, {double radius = 6}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: cl.fieldBg,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _LawyerEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cl.border),
      ),
      child: Center(
        child: Text(
          'No lawyers available yet',
          style: GoogleFonts.nunito(fontSize: 13, color: cl.textLight),
        ),
      ),
    );
  }
}
