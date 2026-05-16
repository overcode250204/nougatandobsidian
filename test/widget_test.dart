import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const Paper2VaultApp());
    expect(find.text('Paper2Vault'), findsOneWidget);
  });
}
