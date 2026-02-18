import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clair/shared/widgets/loading_indicator.dart';

void main() {
  testWidgets('LoadingIndicator displays', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(message: 'Loading...'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
