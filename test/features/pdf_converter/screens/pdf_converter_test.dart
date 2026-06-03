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

    testWidgets('full flow: select pdf, convert, and save', (WidgetTester tester) async {
       final mockFileService = MockIFileService();
       final pdfResult = FilePickerResult(<PlatformFile>[PlatformFile(name: 'paper.pdf', path: 'C:\\docs\\paper.pdf', size: 100)]);
       
       when(mockFileService.getPdf()).thenAnswer((_) async => pdfResult);
       
       await tester.pumpWidget(MaterialApp(home: Scaffold(body: PdfConverterScreen(
         processStarter: (exe, args, {runInShell = true}) async => mockProcess,
         fileService: mockFileService,
       ))));
       await tester.pumpAndSettle();

       // 1. Pick PDF
       await tester.tap(find.text('Browse'));
       await tester.pumpAndSettle();
       expect(find.text('paper.pdf'), findsOneWidget);

       // 2. Convert
       await tester.tap(find.text('Convert to Markdown'));
       await tester.pump();
       
       expect(find.byType(LinearProgressIndicator), findsOneWidget);

       // Simulate output
       stderrController.add('100%|â–ˆâ–ˆâ–ˆâ–ˆ| 1/1'.codeUnits);
       stdoutController.add('Content'.codeUnits);
       
       exitCodeCompleter.complete(0);
       await stdoutController.close();
       await stderrController.close();
       
       await tester.pumpAndSettle();
       
       expect(find.textContaining('✅'), findsOneWidget);

       // 3. Save
       await tester.tap(find.text('Save to Vault'));
       await tester.pumpAndSettle();
    });

    testWidgets('handles error', (WidgetTester tester) async {
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
       await tester.pump();
       
       exitCodeCompleter.complete(1);
       await stdoutController.close();
       await stderrController.close();
       await tester.pumpAndSettle();
       
       expect(find.textContaining('❌'), findsOneWidget);
    });
  });
}
