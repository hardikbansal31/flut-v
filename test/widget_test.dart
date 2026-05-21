// Basic smoke test for Phase 1 — verifies the app launches without error.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video/app.dart';

void main() {
  testWidgets('App smoke test — home screen renders', (tester) async {
    await tester.pumpWidget(const FluxPlayerApp());
    await tester.pumpAndSettle();

    // Verify the app title / logo is present.
    expect(find.text('FluxPlayer'), findsWidgets);

    // Verify key sections are visible.
    expect(find.text('Continue Watching'), findsOneWidget);
  });
}
