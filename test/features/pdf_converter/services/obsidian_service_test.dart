import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/obsidian_service.dart';

void main() {
  group('ObsidianService Exhaustive Unit Test', () {
    test('saveToObsidian cleans file names and handles null pdfPath', () async {
      final tempDir = await Directory.systemTemp.createTemp('obsidian_test');
      try {
        // Case 1: valid saving
        final result1 = await ObsidianService.saveToObsidian(
          '# Markdown', 
          'C:\\path\\to\\file.pdf', 
          tempDir.path
        );
        expect(result1, contains('file.md'));
        expect(File(result1!).existsSync(), isTrue);

        // Case 2: null pdfPath
        final result2 = await ObsidianService.saveToObsidian(
          '# Content', 
          null, 
          tempDir.path
        );
        expect(result2, contains('converted_paper.md'));
        expect(File(result2!).existsSync(), isTrue);

        // Case 3: Empty markdown returns null
        final result3 = await ObsidianService.saveToObsidian('', null, tempDir.path);
        expect(result3, isNull);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
