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
    expect(out, contains('specific ** Republic Act'));
    expect(out, contains('how to ** interpret'));
    expect(out, contains('about ** recent'));
    expect(out, isNot(contains('specificRepublic')));
    expect(out, isNot(contains('tointerpret')));
    expect(out, isNot(contains('aboutrecent')));
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
}
