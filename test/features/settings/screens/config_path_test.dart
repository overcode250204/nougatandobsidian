import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/settings/screens/config_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([IFileService])
import 'config_path_test.mocks.dart';

void main() {
  group('ConfigPathScreen Widget Test', () {
    late MockIFileService mockFileService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockFileService = MockIFileService();
    });

    testWidgets('renders all browse fields', (WidgetTester tester) async {
       await tester.pumpWidget(MaterialApp(home: Scaffold(body: ConfigPathScreen(fileService: mockFileService))));
       await tester.pumpAndSettle();

       expect(find.text('Configuration'), findsOneWidget);
    });

    testWidgets('picks a path and saves', (WidgetTester tester) async {
       final result = FilePickerResult(<PlatformFile>[PlatformFile(name: 'nougat.exe', path: 'C:\\bin\\nougat.exe', size: 100)]);
       when(mockFileService.getPdf()).thenAnswer((_) async => result);

       await tester.pumpWidget(MaterialApp(home: Scaffold(body: ConfigPathScreen(fileService: mockFileService))));
       await tester.pumpAndSettle();

       // Tap Browse for Nougat
       await tester.tap(find.text('Browse').first);
       await tester.pumpAndSettle();

       expect(find.text('C:\\bin\\nougat.exe'), findsOneWidget);

       // Save
       await tester.tap(find.text('Save Settings'));
       await tester.pumpAndSettle();

       expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
