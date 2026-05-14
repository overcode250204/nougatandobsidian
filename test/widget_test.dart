import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Paper2VaultApp(),
      ),
    );
    // Verify the app bar title appears
    expect(find.text('📄 Paper to Obsidian'), findsOneWidget);
  });
}
