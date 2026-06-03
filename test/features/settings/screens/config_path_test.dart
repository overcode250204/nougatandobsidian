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
       expect(find.text('Save Settings'), findsOneWidget);
    });

    testWidgets('shows placeholder if paths are empty', (WidgetTester tester) async {
       await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ConfigPathScreen())));
       await tester.pumpAndSettle();
       
       // Default values are empty strings in AppPathConfig usually or handled in screen
       // Check if 'Not set' or default text appears
    });
  });
}
