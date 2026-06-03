import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/settings/screens/config_path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';

@GenerateMocks([IFileService])
import 'config_path_test.mocks.dart';

void main() {
  group('ConfigPathScreen Widget Test (Lightweight)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders all fields', (WidgetTester tester) async {
       await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ConfigPathScreen())));
       await tester.pump();

       expect(find.text('Configuration'), findsOneWidget);
       expect(find.text('Nougat EXE Path'), findsOneWidget);
       expect(find.text('Output Directory'), findsOneWidget);
    });
  });
}
