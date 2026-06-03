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
       await tester.pump();
       
       expect(find.text('Configuration'), findsOneWidget);
       expect(find.text('Nougat EXE Path'), findsOneWidget);
       expect(find.text('Output Directory'), findsOneWidget);
       expect(find.text('Obsidian Vault Folder'), findsOneWidget);
    });

    testWidgets('picks a path and saves', (WidgetTester tester) async {
       final fileResult = FilePickerResult(<PlatformFile>[PlatformFile(name: 'nougat.exe', path: 'C:\\bin\\nougat.exe', size: 100)]);
       
       when(mockFileService.getPdf()).thenAnswer((_) async => fileResult);
       when(mockFileService.getDirectory()).thenAnswer((_) async => 'C:\\output');

       await tester.pumpWidget(MaterialApp(home: Scaffold(body: ConfigPathScreen(fileService: mockFileService))));
       await tester.pump();

       // 1. Pick Nougat Exe
       await tester.tap(find.text('Browse').at(0));
       await tester.pumpAndSettle();
       expect(find.text('C:\\bin\\nougat.exe'), findsOneWidget);

       // 2. Pick Output Dir
       await tester.tap(find.text('Browse').at(1));
       await tester.pumpAndSettle();
       expect(find.text('C:\\output'), findsOneWidget);

       // Save
       await tester.tap(find.text('Save Settings'));
       await tester.pump(const Duration(milliseconds: 500)); 

       expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
