import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/settings/screens/config_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConfigPathScreen Widget Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders all browse fields', (WidgetTester tester) async {
       await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ConfigPathScreen())));
       await tester.pumpAndSettle();

       expect(find.text('Configuration'), findsOneWidget);
       expect(find.text('Nougat EXE Path'), findsOneWidget);
       expect(find.text('Output Directory'), findsOneWidget);
       expect(find.text('Obsidian Vault Folder'), findsOneWidget);
    });

    testWidgets('can tap Save Settings', (WidgetTester tester) async {
       await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ConfigPathScreen())));
       await tester.pumpAndSettle();
       
       await tester.tap(find.text('Save Settings'));
       await tester.pumpAndSettle();
       
       // Success snackbar should appear if data is valid (or defaults)
       expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
