import 'package:flutter_test/flutter_test.dart';
import 'package:clair/features/chat/utils/chat_markdown_format.dart';

void main() {
  test('inserts spaces when bold markers are glued to words', () {
    const raw =
        '**Are you looking for information on a specific**Republic Act** '
        'or **Presidential Decree? Do you have questions about how to**interpret '
        'or apply** a particular law? **Would you like to know more about**recent '
        'changes?**';
    final out = normalizeChatMarkdown(raw);
    expect(out, isNot(contains('specificRepublic')));
    expect(out, isNot(contains('tointerpret')));
    expect(out, isNot(contains('aboutrecent')));
    expect(out, contains('Republic Act'));
    expect(out, contains('interpret or apply'));
    expect(out, contains('recent changes'));
  });

  test('does not split bold opener after bullet markers', () {
    const raw = '''Intro **Philippine legal information** here.

• **Do you have a specific law or regulation in mind? **
• **Are you looking for information on a particular court case or ruling? **
• **Would you like to know about a recent change in Philippine law? **''';
    final out = normalizeChatMarkdown(raw);
    expect(out, isNot(contains('* **')));
    expect(out, isNot(contains('• *')));
    expect(out, contains('**Do you have a specific law or regulation in mind?**'));
    expect(out, isNot(contains('in mind? **')));
    expect(out, contains('- **Are you looking for information'));
    expect(out, contains('- **Would you like to know'));
  });

  test('converts asterisk-wrapped disclaimer to underscore italics', () {
    const raw =
        "* I'm providing general information only and not legal advice. "
        "It's always best to consult a licensed attorney for specific guidance.*";
    final out = normalizeChatMarkdown(raw);
    expect(out, startsWith('_'));
    expect(out, endsWith('_'));
    expect(out, isNot(contains("* I'm")));
  });

  test('pulls bold disclaimer off list bullet and demotes to italics', () {
    const raw = '''Senator cases depend on pending charges and court orders.

**If you want, tell me:**
- **Are you asking about an active warrant or case?**
- **Would you like an overview of arrest procedures? ** **Please note that this is a general information response and is not intended to be taken as legal advice. If you have specific concerns about Senator Bato Dela Rosa's situation, I recommend consulting a licensed attorney or seeking updates from reliable news sources.**''';
    final out = normalizeChatMarkdown(raw);
    expect(out, contains('**If you want, tell me:**'));
    expect(out, contains('**Are you asking about an active warrant'));
    expect(out, contains('**Would you like an overview'));
    expect(out, isNot(contains('**Please note that this is a general')));
    expect(out, contains('_Please note that this is a general'));
    expect(out, isNot(contains('reliable news sources.**')));
    final disclaimerLine = out
        .split('\n')
        .firstWhere((l) => l.contains('Please note'));
    expect(disclaimerLine.startsWith('_'), isTrue);
    expect(disclaimerLine.endsWith('_'), isTrue);
    expect(
      out.indexOf('Would you like an overview') <
          out.indexOf('Please note that this is'),
      isTrue,
    );
  });
}
