import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/main.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders without crashing and toggles settings', (WidgetTester tester) async {
    await tester.pumpWidget(const Paper2VaultApp());
    expect(find.text('Paper2Vault'), findsOneWidget);
    
    // Toggle settings
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    
    expect(find.text('Configuration'), findsOneWidget);
  });
}
