import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/obsidian_service.dart';

void main() {
  group('ObsidianService Test', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('obsidian_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveToObsidian saves content correctly', () async {
      const markdown = '# Hello World\nLine 2';
      const pdfPath = 'C:\\documents\\my_paper.pdf';
      final vaultPath = tempDir.path;

      final resultPath = await ObsidianService.saveToObsidian(markdown, pdfPath, vaultPath);

      expect(resultPath, isNotNull);
      final outputFile = File(resultPath!);
      expect(await outputFile.exists(), isTrue);
      expect(outputFile.path, contains('my_paper.md'));
      
      final savedContent = await outputFile.readAsString();
      expect(savedContent, markdown);
    });

    test('saveToObsidian returns null if markdown is empty', () async {
       final resultPath = await ObsidianService.saveToObsidian('', 'test.pdf', tempDir.path);
       expect(resultPath, isNull);
    });

    test('saveToObsidian uses default name if pdfPath is null', () async {
      const markdown = 'content';
      final resultPath = await ObsidianService.saveToObsidian(markdown, null, tempDir.path);
      
      expect(resultPath, isNotNull);
      expect(resultPath, contains('paper.md'));
    });
  });
}
