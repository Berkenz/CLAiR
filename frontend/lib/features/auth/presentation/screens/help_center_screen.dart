import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/l10n/app_localizations.dart';

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class _FaqSection {
  final IconData icon;
  final String title;
  final Color color;
  final List<_FaqItem> items;
  const _FaqSection(this.icon, this.title, this.color, this.items);
}

const _faqUsingItems = [
  _FaqItem(
    'What is CLAiR?',
    'CLAiR is an AI-powered legal assistant that helps you understand Philippine laws, get quick answers to legal questions, and connect with registered lawyers. It is not a substitute for formal legal advice.',
  ),
  _FaqItem(
    'How do I start a conversation?',
    'Tap the Chat tab at the bottom of the screen and type your legal question. CLAiR will respond based on current Philippine laws and legal resources.',
  ),
  _FaqItem(
    'Can I bookmark my conversations?',
    'Yes. All conversations are stored automatically and accessible from the History tab. Bookmark important ones from History or Library to find them quickly.',
  ),
  _FaqItem(
    'Is CLAiR\'s advice legally binding?',
    'No. CLAiR provides general legal information for educational purposes only. For formal legal advice, consult a licensed lawyer through the Lawyers tab.',
  ),
];

const _faqLawyerItems = [
  _FaqItem(
    'How do I find a lawyer?',
    'Go to the Lawyers tab and browse by practice area, or search by name or specialty. Tap a lawyer\'s card to view their profile, then book an appointment.',
  ),
  _FaqItem(
    'What information do I need to book an appointment?',
    'Provide a brief title and description of your concern. You can optionally attach a CLAiR conversation or a file to give the lawyer more context.',
  ),
  _FaqItem(
    'How does "Share to Lawyer" work?',
    'Open any conversation in the History tab, tap the menu, and choose "Share to Lawyer." This takes you to the Lawyers screen with your conversation pre-attached — just tap a lawyer to book.',
  ),
  _FaqItem(
    'Are the lawyers on CLAiR verified?',
    'Lawyers listed on CLAiR are registered professionals. Look for the verified badge on their profile. Always verify credentials before engaging for formal legal work.',
  ),
];

const _faqPrivacyItems = [
  _FaqItem(
    'Is my data safe?',
    'CLAiR uses industry-standard encryption for data in transit and at rest. We do not sell your personal information to third parties.',
  ),
  _FaqItem(
    'Who can see my conversations?',
    'Only you can see your conversations. If you choose to share a conversation with a lawyer via the booking feature, that lawyer will have access to the content you explicitly attached.',
  ),
  _FaqItem(
    'How do I delete my account and data?',
    'Go to Settings → Delete Account. This permanently removes your account and all associated data from our servers.',
  ),
];

const _faqAccountItems = [
  _FaqItem(
    'How do I change my password?',
    'Go to Settings → Security and follow the steps to update your password.',
  ),
  _FaqItem(
    'Can I change the app appearance?',
    'Yes. Go to Settings → Appearance to switch between Light, Dark, and System themes.',
  ),
  _FaqItem(
    'How do I reset all settings to default?',
    'Go to Settings and scroll to the bottom. Tap "Reset All to Default" and confirm. This restores all appearance and preferences to their original values.',
  ),
];

const _faqReportingItems = [
  _FaqItem(
    'How do I report a problem with CLAiR?',
    'Go to Settings → Report. Select the category that best describes the issue, add a description, and submit. Our team reviews all reports.',
  ),
  _FaqItem(
    'What if CLAiR gives incorrect legal information?',
    'Tap the dislike button on the message or go to Settings → Report and select "Wrong AI Response." Include a description so our team can review and improve the model.',
  ),
  _FaqItem(
    'How do I report a concern about a lawyer?',
    'Open the lawyer\'s profile and tap "Report Concern." Fill in the category and explanation. Reports are reviewed by our moderation team.',
  ),
];

List<_FaqSection> _faqSections(AppLocalizations l) => [
      _FaqSection(
        Icons.chat_bubble_outline_rounded,
        l.helpSecUsing,
        const Color(0xFF3182CE),
        _faqUsingItems,
      ),
      _FaqSection(
        Icons.people_outline_rounded,
        l.helpSecLawyers,
        const Color(0xFF38A169),
        _faqLawyerItems,
      ),
      _FaqSection(
        Icons.shield_outlined,
        l.helpSecPrivacy,
        const Color(0xFF805AD5),
        _faqPrivacyItems,
      ),
      _FaqSection(
        Icons.tune_rounded,
        l.helpSecAccount,
        const Color(0xFFD69E2E),
        _faqAccountItems,
      ),
      _FaqSection(
        Icons.flag_outlined,
        l.helpSecReporting,
        const Color(0xFFE53E3E),
        _faqReportingItems,
      ),
    ];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<int> _expanded = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<({_FaqSection section, List<_FaqItem> items})> get _filtered {
    final l10n = AppLocalizations.of(context)!;
    final allSections = _faqSections(l10n);
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) {
      return allSections
          .map((s) => (section: s, items: s.items))
          .toList();
    }
    final results = <({_FaqSection section, List<_FaqItem> items})>[];
    for (final section in allSections) {
      final matching = section.items
          .where((it) =>
              it.question.toLowerCase().contains(q) ||
              it.answer.toLowerCase().contains(q))
          .toList();
      if (matching.isNotEmpty) {
        results.add((section: section, items: matching));
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final sections = _filtered;

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: cl.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.helpCenter,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cl.border),
        ),
      ),
      body: Column(
        children: [
          _buildHero(cl, l10n),
          _buildSearchBar(cl, l10n),
          Expanded(
            child: sections.isEmpty
                ? _buildEmpty(cl, l10n)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: sections.length,
                    itemBuilder: (_, si) {
                      final sec = sections[si];
                      return _buildSection(cl, sec.section, sec.items, si);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(AppColorTheme cl, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: cl.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3182CE).withValues(alpha: 0.15),
                  const Color(0xFF805AD5).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.support_agent_rounded,
                size: 26, color: Color(0xFF3182CE)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helpHeroTitle,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cl.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.helpHeroSubtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: cl.textMid,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.helpFaqEnglishNotice,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                    color: cl.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorTheme cl, AppLocalizations l10n) {
    return Container(
      color: cl.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.nunito(fontSize: 14, color: cl.textDark),
        decoration: InputDecoration(
          hintText: l10n.helpSearchHint,
          hintStyle:
              GoogleFonts.nunito(fontSize: 14, color: cl.textLight),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: cl.textLight),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  child: Icon(Icons.close_rounded,
                      size: 18, color: cl.textLight),
                )
              : null,
          filled: true,
          fillColor: cl.bg,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cl.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cl.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: cl.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    AppColorTheme cl,
    _FaqSection section,
    List<_FaqItem> items,
    int sectionIdx,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(section.icon,
                    size: 16, color: section.color),
              ),
              const SizedBox(width: 10),
              Text(
                section.title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cl.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cl.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cl.border),
            ),
            child: Column(
              children: List.generate(items.length, (qi) {
                final key = sectionIdx * 100 + qi;
                final open = _expanded.contains(key);
                final isLast = qi == items.length - 1;
                return _buildFaqTile(
                  cl: cl,
                  item: items[qi],
                  open: open,
                  isLast: isLast,
                  onTap: () => setState(() {
                    if (open) {
                      _expanded.remove(key);
                    } else {
                      _expanded.add(key);
                    }
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile({
    required AppColorTheme cl,
    required _FaqItem item,
    required bool open,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight:
                          open ? FontWeight.w700 : FontWeight.w600,
                      color: open ? cl.accent : cl.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: open ? cl.accent : cl.textMid,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: open
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: cl.accent.withValues(alpha: 0.04),
                    borderRadius: isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          )
                        : BorderRadius.zero,
                  ),
                  child: Text(
                    item.answer,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      height: 1.6,
                      color: cl.textMid,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: cl.border),
      ],
    );
  }

  Widget _buildEmpty(AppColorTheme cl, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: cl.textLight),
            const SizedBox(height: 16),
            Text(
              l10n.helpEmptyNoResults(_query),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cl.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.helpEmptySuggest,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: cl.textMid),
            ),
          ],
        ),
      ),
    );
  }
}
