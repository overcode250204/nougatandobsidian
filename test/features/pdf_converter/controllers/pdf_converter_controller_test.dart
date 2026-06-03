import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paper_to_obsidian/features/pdf_converter/controllers/pdf_converter_controller.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([Process, IFileService])
import 'pdf_converter_controller_test.mocks.dart';

void main() {
  group('PdfConverterController Test', () {
    late PdfConverterController controller;
    late MockIFileService mockFileService;
    late MockProcess mockProcess;
    late StreamController<List<int>> stdoutController;
    late StreamController<List<int>> stderrController;
    late Completer<int> exitCodeCompleter;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('controller_test');
      SharedPreferences.setMockInitialValues({
        'nougat_exe': 'nougat',
        'output_dir': tempDir.path,
        'vault_path': 'vault',
      });
      mockFileService = MockIFileService();
      mockProcess = MockProcess();
      stdoutController = StreamController<List<int>>();
      stderrController = StreamController<List<int>>();
      exitCodeCompleter = Completer<int>();

      when(mockProcess.stdout).thenAnswer((_) => stdoutController.stream);
      when(mockProcess.stderr).thenAnswer((_) => stderrController.stream);
      when(mockProcess.exitCode).thenAnswer((_) => exitCodeCompleter.future);

      controller = PdfConverterController(
        fileService: mockFileService,
        processStarter: (exe, args, {runInShell = true}) async => mockProcess,
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('pickPdf updates state correctly', () async {
      final result = FilePickerResult(<PlatformFile>[PlatformFile(name: 'test.pdf', path: 'path/to/test.pdf', size: 100)]);
      when(mockFileService.getPdf()).thenAnswer((_) async => result);

      await controller.pickPdf();

      expect(controller.selectedPdf, 'path/to/test.pdf');
      expect(controller.markdown, isEmpty);
    });

    test('convertPdf full success flow', () async {
      final result = FilePickerResult(<PlatformFile>[PlatformFile(name: 'test.pdf', path: 'path/to/test.pdf', size: 100)]);
      when(mockFileService.getPdf()).thenAnswer((_) async => result);
      await controller.pickPdf();

      final future = controller.convertPdf();
      
      expect(controller.loading, isTrue);

      // Simulate process output
      stderrController.add(' 100%|██████████| 1/1'.codeUnits);
      stdoutController.add('dummy stdout'.codeUnits);
      
      // Give streams a moment to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      final outputFile = File('${tempDir.path}/test.mmd');
      await outputFile.writeAsString('Converted Text Contents');

      await Future.delayed(const Duration(milliseconds: 100));
      
      exitCodeCompleter.complete(0);
      await stdoutController.close();
      await stderrController.close();
      
      await future;

      expect(controller.loading, isFalse);
      expect(controller.progress, 1.0);
      expect(controller.markdown, 'Converted Text Contents');
    });
  });
}
