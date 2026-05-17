import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:clair/core/theme/app_colors.dart';

/// Only unwrap a block when it is a single `**...**` pair with no inner markers.
bool _isSingleOuterBoldWrapper(String block) {
  final t = block.trim();
  if (!t.startsWith('**') || !t.endsWith('**') || t.length < 4) return false;
  final inner = t.substring(2, t.length - 2);
  return !inner.contains('**');
}

String _fixEmphasisArtifacts(String text) {
  var t = text;

  // Model sometimes escapes emphasis (e.g. **\*\*Reinstatement**).
  t = t.replaceAll(r'\*\*', '');

  for (var pass = 0; pass < 8; pass++) {
    final before = t;

    // ****phrase** / ****phrase**** — extra open/close asterisks (common after ":").
    t = t.replaceAllMapped(
      RegExp(r'\*{4,}([^*\n]{1,120}?)\*{2,4}'),
      (m) => '**${m[1]!.trim()}**',
    );

    // Duplicate opener before a valid bold span: ****word** → **word**.
    t = t.replaceAll(RegExp(r'\*\*(?=\*\*[^*\n]{1,120}?\*\*)'), '');

    // ** **phrase** — spaced duplicate openers.
    t = t.replaceAllMapped(
      RegExp(r'\*\*\s+\*\*([^*\n]{1,120}?)\*\*'),
      (m) => '**${m[1]!.trim()}**',
    );

    // ***phrase** / ****phrase*** — model often emits an extra leading *.
    t = t.replaceAllMapped(
      RegExp(r'\*{3,}([^*\n]{1,120}?)\*{2,}'),
      (m) => '**${m[1]!.trim()}**',
    );

    // **phrase*** — extra trailing asterisks.
    t = t.replaceAllMapped(
      RegExp(r'\*{2}([^*\n]{1,120}?)\*{3,}'),
      (m) => '**${m[1]!.trim()}**',
    );

    // *Title** or *Title*** → **Title** (single open, multiple close).
    t = t.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*\n]{1,120}?)\*\*+'),
      (m) => '**${m[1]!.trim()}**',
    );

    // **phrase* — single close after bold open.
    t = t.replaceAllMapped(
      RegExp(r'\*{2}([^*\n]{1,120}?)\*(?!\*)'),
      (m) => '**${m[1]!.trim()}**',
    );

    // *title* *  → **title**
    t = t.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*\n]{1,120}?)\*\s+\*(?=\s|$)'),
      (m) => '**${m[1]!.trim()}**',
    );

    // Lone * immediately before **bold** (e.g. "* **R.A. No.**").
    t = t.replaceAll(RegExp(r'(?<!\*)\*(?=\s*\*\*[^*]+\*\*)'), '');

    if (t == before) break;
  }

  return t;
}

/// Opening line: drop mistaken list bullets and normalize the practice-area label.
String _fixLeadingLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return line;

  // * *Category* rest  or  • *Category* rest  →  **Category** rest
  final listNested = RegExp(
    r'^[-*•]\s+\*+([^*\n]{2,80}?)\*+\s*(.*)$',
  ).firstMatch(t);
  if (listNested != null) {
    final rest = listNested.group(2)!.trimLeft();
    return rest.isEmpty
        ? '**${listNested.group(1)!.trim()}**'
        : '**${listNested.group(1)!.trim()}** $rest';
  }

  // * **Category** rest  →  **Category** rest (no list bullet)
  final listBold = RegExp(
    r'^[-*•]\s+\*{2,}([^*\n]{2,80}?)\*{2,}\s*(.*)$',
  ).firstMatch(t);
  if (listBold != null) {
    final rest = listBold.group(2)!.trimLeft();
    return rest.isEmpty
        ? '**${listBold.group(1)!.trim()}**'
        : '**${listBold.group(1)!.trim()}** $rest';
  }

  // *Category* / *Category** rest  →  **Category** rest
  final emphasis = RegExp(
    r'^\*([^*\n]{2,80}?)\*\*?(?:\s*\*)?\s*(.*)$',
  ).firstMatch(t);
  if (emphasis != null) {
    final rest = emphasis.group(2)!.trimLeft();
    return rest.isEmpty
        ? '**${emphasis.group(1)!.trim()}**'
        : '**${emphasis.group(1)!.trim()}** $rest';
  }

  return line;
}

String _fixLeadingCategoryLine(String text) {
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    lines[i] = _fixLeadingLine(lines[i]);
    break;
  }
  return lines.join('\n');
}

final _listLinePrefix = RegExp(r'^\s*(\d+\.|[-*•])\s+');

bool _looksLikeLegalDisclaimer(String text) {
  final plain =
      text.replaceAll(RegExp(r'^[\*_]+|[\*_]+$'), '').trim().toLowerCase();
  if (plain.isEmpty) return false;
  return RegExp(
    r'(please note|not legal advice|information only|for information only|'
    r'consult a licensed attorney|licensed attorney for personalized|'
    r"i'm here to provide|my responses are)",
    caseSensitive: false,
  ).hasMatch(plain);
}

String _stripListMarker(String line) =>
    line.replaceFirst(_listLinePrefix, '').trim();

/// Disclaimers must not be list items — pull them out as separate paragraphs.
String _separateDisclaimersFromListLines(String text) {
  final disclaimerTail = RegExp(
    r'\s+(\*(?:Please note|Note:|Disclaimer|My responses are|I[\u2019\x27]m here to provide)'
    r'[\s\S]*?\*)',
    caseSensitive: false,
  );

  final lines = text.split('\n');
  final out = <String>[];
  for (final line in lines) {
    if (!_listLinePrefix.hasMatch(line)) {
      out.add(line);
      continue;
    }

    final itemBody = _stripListMarker(line);

    // Entire bullet/number is only the disclaimer → plain paragraph.
    if (_looksLikeLegalDisclaimer(itemBody)) {
      if (out.isNotEmpty && out.last.trim().isNotEmpty) out.add('');
      out.add(itemBody);
      continue;
    }

    // Disclaimer glued to the end of a real list item.
    final match = disclaimerTail.firstMatch(line);
    if (match == null) {
      out.add(line);
      continue;
    }
    final body = line.substring(0, match.start).trimRight();
    final disclaimer = match.group(1)!.trim();
    out.add(body);
    out.add('');
    out.add(disclaimer);
  }
  return out.join('\n');
}

/// Unwrap mistaken “entire message is bold” wrappers; keep inline **phrase** bold.
String normalizeChatMarkdown(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return text;

  text = _fixEmphasisArtifacts(text);
  text = _fixLeadingCategoryLine(text);
  text = _separateDisclaimersFromListLines(text);

  if (_isSingleOuterBoldWrapper(text)) {
    text = text.substring(2, text.length - 2).trim();
  }

  final blocks = text.split(RegExp(r'\n{2,}'));
  final normalizedBlocks = blocks.map((block) {
    var b = block.trim();
    if (b.isEmpty) return b;
    if (_isSingleOuterBoldWrapper(b)) {
      b = b.substring(2, b.length - 2).trim();
    }
    return b;
  }).where((b) => b.isNotEmpty);

  text = normalizedBlocks.join('\n\n');

  // Never treat leading `**` as a list bullet (was turning **Label** into * *Label**).
  text = text.replaceAllMapped(
    RegExp(r'^(\s*)([-•])\s*(\S)', multiLine: true),
    (m) => '${m.group(1)}${m.group(2)} ${m.group(3)}',
  );
  text = text.replaceAllMapped(
    RegExp(r'^(\s*)\*(?!\*)(\S)', multiLine: true),
    (m) => '${m.group(1)}* ${m.group(2)}',
  );

  return text;
}

/// Strip markdown for single-line previews (library/history list cards).
String plainTextChatPreview(String raw) {
  var text = normalizeChatMarkdown(raw);
  if (text.isEmpty) return text;

  text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
  // Repeat until stable — handles multiple **segments** on one line.
  for (var i = 0; i < 8; i++) {
    final next = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+?)\*\*'),
      (m) => m.group(1)!,
    );
    if (next == text) break;
    text = next;
  }
  text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1)!);
  text = text.replaceAllMapped(
    RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'),
    (m) => m.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'(?<!_)_([^_\n]+)_(?!_)'),
    (m) => m.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]*\)'),
    (m) => m.group(1)!,
  );
  text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
  text = text.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
  text = text.replaceAll('**', '').replaceAll('__', '');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// User bubble text — medium weight so it reads clearly on the accent gradient.
TextStyle chatUserBubbleText() => const TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 14,
      height: 1.55,
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation.weight(520)],
    );

/// Satoshi is a variable font — [FontWeight] alone often ignores weight in markdown spans.
TextStyle chatMarkdownBody(AppColorTheme cl) => TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 14,
      height: 1.55,
      color: cl.textDark,
      fontWeight: FontWeight.w400,
      fontVariations: const [FontVariation.weight(450)],
    );

TextStyle chatMarkdownStrong(AppColorTheme cl) => TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 14,
      height: 1.55,
      color: cl.textDark,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(750)],
    );

TextStyle chatMarkdownEmphasis(AppColorTheme cl) => TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 13,
      height: 1.5,
      color: cl.textMid,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      fontVariations: const [FontVariation.weight(450)],
    );

MarkdownStyleSheet chatMarkdownStyleSheet(AppColorTheme cl) {
  final body = chatMarkdownBody(cl);
  final strong = chatMarkdownStrong(cl);
  final em = chatMarkdownEmphasis(cl);
  const linkColor = Color(0xFF2563EB);
  return MarkdownStyleSheet(
    p: body,
    strong: strong,
    em: em,
    a: body.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    ),
    h1: strong.copyWith(fontSize: 16, height: 1.35),
    h2: strong.copyWith(fontSize: 15, height: 1.35),
    h3: strong.copyWith(fontSize: 14, height: 1.4),
    listBullet: body,
    listIndent: 22,
    blockSpacing: 12,
    listBulletPadding: const EdgeInsets.only(bottom: 6),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: cl.accent.withValues(alpha: 0.4),
          width: 3,
        ),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
    code: TextStyle(
      fontSize: 13,
      fontFamily: 'monospace',
      color: cl.accent,
      backgroundColor: cl.accent.withValues(alpha: 0.06),
    ),
    codeblockDecoration: BoxDecoration(
      color: cl.textDark.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: cl.border),
    ),
    codeblockPadding: const EdgeInsets.all(12),
  );
}
