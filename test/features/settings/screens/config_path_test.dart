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
  group('ConfigPathScreen Deep Widget Test', () {
    late MockIFileService mockFileService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockFileService = MockIFileService();
    });

    testWidgets('renders and handles all path selections', (WidgetTester tester) async {
       when(mockFileService.getPdf()).thenAnswer((_) async => FilePickerResult(<PlatformFile>[
         PlatformFile(name: 'nougat.exe', path: 'C:\\bin\\nougat.exe', size: 100)
       ]));
       when(mockFileService.getDirectory()).thenAnswer((_) async => 'C:\\selected\\path');

       await tester.pumpWidget(MaterialApp(home: Scaffold(body: ConfigPathScreen(fileService: mockFileService))));
       await tester.pump();

       // 1. Nougat Exe
       await tester.tap(find.text('Browse').at(0));
       await tester.pumpAndSettle();
       expect(find.text('C:\\bin\\nougat.exe'), findsOneWidget);

       // 2. Output Dir
       await tester.tap(find.text('Browse').at(1));
       await tester.pumpAndSettle();
       expect(find.text('C:\\selected\\path'), findsOneWidget);

       // 3. Vault Folder
       await tester.tap(find.text('Browse').at(2));
       await tester.pumpAndSettle();
       // Since I used the same mock for both directory selections, it points to the same path
       expect(find.text('C:\\selected\\path'), findsAtLeastNWidgets(2));

       // Save
       await tester.tap(find.text('Save Settings'));
       await tester.pump(const Duration(milliseconds: 500)); 

       expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
