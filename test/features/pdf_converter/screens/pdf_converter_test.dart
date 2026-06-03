import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:paper_to_obsidian/features/pdf_converter/screens/pdf_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:paper_to_obsidian/core/services/file_service_interface.dart';

import 'dart:io';

@GenerateMocks([Process, IFileService])
import 'pdf_converter_test.mocks.dart';

void main() {
  group('PdfConverterScreen Widget Test', () {
    late MockProcess mockProcess;
    late StreamController<List<int>> stdoutController;
    late StreamController<List<int>> stderrController;
    late Completer<int> exitCodeCompleter;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockProcess = MockProcess();
      stdoutController = StreamController<List<int>>();
      stderrController = StreamController<List<int>>();
      exitCodeCompleter = Completer<int>();

      when(mockProcess.stdout).thenAnswer((_) => stdoutController.stream);
      when(mockProcess.stderr).thenAnswer((_) => stderrController.stream);
      when(mockProcess.exitCode).thenAnswer((_) => exitCodeCompleter.future);
    });

    testWidgets('Full Success Flow: pick, convert, save', (WidgetTester tester) async {
       final mockFileService = MockIFileService();
       final pdfResult = FilePickerResult(<PlatformFile>[PlatformFile(name: 'paper.pdf', path: 'C:\\docs\\paper.pdf', size: 100)]);
       
       when(mockFileService.getPdf()).thenAnswer((_) async => pdfResult);
       
       await tester.pumpWidget(MaterialApp(home: Scaffold(body: PdfConverterScreen(
         processStarter: (exe, args, {runInShell = true}) async => mockProcess,
         fileService: mockFileService,
       ))));
       await tester.pump();

       // 1. Pick PDF
       await tester.tap(find.text('Browse'));
       await tester.pumpAndSettle();
       expect(find.text('paper.pdf'), findsOneWidget);

       // 2. Convert
       await tester.tap(find.text('Convert to Markdown'));
       await tester.pump(const Duration(milliseconds: 100)); // Show indicator
       
       expect(find.byType(LinearProgressIndicator), findsOneWidget);

       // Simulate output to cover progress branches
       stderrController.add(' 50%|█████     | 5/10'.codeUnits);
       await tester.pump(const Duration(milliseconds: 100));
       
       stderrController.add(' 100%|██████████| 10/10'.codeUnits);
       stdoutController.add('Converted Content'.codeUnits);
       
       exitCodeCompleter.complete(0);
       await stdoutController.close();
       await stderrController.close();
       
       // Wait for conversion completion (async)
       for (int i = 0; i < 10; i++) {
         await tester.pump(const Duration(milliseconds: 100));
       }
       
       expect(find.textContaining('✅'), findsOneWidget);
       expect(find.text('Converted Content'), findsOneWidget);

       // 3. Save
       await tester.tap(find.text('Save to Vault'));
       await tester.pumpAndSettle();
    });

    testWidgets('Error Flow: Process failure', (WidgetTester tester) async {
       final mockFileService = MockIFileService();
       final pdfResult = FilePickerResult(<PlatformFile>[PlatformFile(name: 'paper.pdf', path: 'C:\\docs\\paper.pdf', size: 100)]);
       when(mockFileService.getPdf()).thenAnswer((_) async => pdfResult);
       
       await tester.pumpWidget(MaterialApp(home: Scaffold(body: PdfConverterScreen(
         processStarter: (exe, args, {runInShell = true}) async => mockProcess,
         fileService: mockFileService,
       ))));
       await tester.pumpAndSettle();

       await tester.tap(find.text('Browse'));
       await tester.pumpAndSettle();

       await tester.tap(find.text('Convert to Markdown'));
       await tester.pump(const Duration(milliseconds: 100));
       
       exitCodeCompleter.complete(1); // Error code
       await stdoutController.close();
       await stderrController.close();
       
       for (int i = 0; i < 10; i++) {
         await tester.pump(const Duration(milliseconds: 100));
       }
       
       expect(find.textContaining('❌'), findsOneWidget);
    });
  });
}
