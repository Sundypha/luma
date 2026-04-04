import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack/main.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  testWidgets('shows domain and data package labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      const PtrackApp(
        homeOverride: HomePage(),
      ),
    );

    expect(find.textContaining(PtrackDomain.packageName), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('About opens from home AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const PtrackApp(
        homeOverride: HomePage(),
      ),
    );
    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();
    expect(find.text('About ptrack'), findsOneWidget);
    expect(find.text('Your privacy & how estimates work'), findsOneWidget);
  });
}
