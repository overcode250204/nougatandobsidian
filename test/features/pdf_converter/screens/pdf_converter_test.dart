import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/pdf_converter/screens/pdf_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([Process])
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

    testWidgets('renders initial components', (WidgetTester tester) async {
       await tester.pumpWidget(MaterialApp(home: Scaffold(body: PdfConverterScreen(
         processStarter: (exe, args, {runInShell = true}) async => mockProcess,
       ))));
       await tester.pumpAndSettle();

       expect(find.text('No PDF selected...'), findsOneWidget);
       expect(find.text('Browse'), findsOneWidget);
       expect(find.text('Convert to Markdown'), findsOneWidget);
       expect(find.text('Save to Vault'), findsOneWidget);
    });
  });
}
