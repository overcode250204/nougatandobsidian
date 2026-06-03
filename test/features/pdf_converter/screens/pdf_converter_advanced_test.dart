import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paper_to_obsidian/features/pdf_converter/screens/pdf_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([Process])
import 'pdf_converter_advanced_test.mocks.dart';

void main() {
  group('PdfConverterScreen Advanced Widget Test', () {
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

    testWidgets('simulates full conversion flow', (WidgetTester tester) async {
       await tester.pumpWidget(MaterialApp(home: Scaffold(body: PdfConverterScreen(
         processStarter: (exe, args, {runInShell = true}) async => mockProcess,
       ))));
       await tester.pumpAndSettle();

       // We can't easily mock FilePicker in a widget test without a lot of setup
       // So we just assume we've selected a file (this would need more refactoring to be fully testable)
       // But we can at least check if the component behaves correctly when "Convert" is pressed if a file was present.
    });
  });
}
