import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/pdf_converter/screens/pdf_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'dart:io';

@GenerateMocks([Process, IFileService])
import 'pdf_converter_test.mocks.dart';

void main() {
  group('PdfConverterScreen Widget Test (Lightweight)', () {
    late MockProcess mockProcess;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockProcess = MockProcess();
    });

    testWidgets('renders initial components', (WidgetTester tester) async {
       await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PdfConverterScreen())));
       await tester.pump();

       expect(find.text('No PDF selected...'), findsOneWidget);
       expect(find.text('Browse'), findsOneWidget);
       expect(find.text('Convert to Markdown'), findsOneWidget);
    });
  });
}
