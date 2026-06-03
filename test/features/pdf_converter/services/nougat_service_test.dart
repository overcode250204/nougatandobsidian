import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/nougat_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/models/conver_progress.dart';

@GenerateMocks([Process])
import 'nougat_service_test.mocks.dart';

void main() {
  group('NougatService Exhaustive Unit Test', () {
    late MockProcess mockProcess;
    late StreamController<List<int>> stdoutController;
    late StreamController<List<int>> stderrController;
    late Completer<int> exitCodeCompleter;

    setUp(() {
      mockProcess = MockProcess();
      stdoutController = StreamController<List<int>>();
      stderrController = StreamController<List<int>>();
      exitCodeCompleter = Completer<int>();

      when(mockProcess.stdout).thenAnswer((_) => stdoutController.stream);
      when(mockProcess.stderr).thenAnswer((_) => stderrController.stream);
      when(mockProcess.exitCode).thenAnswer((_) => exitCodeCompleter.future);
    });

    test('convertPdf parses various tqdm formats', () async {
      final progressList = <ConverProgress>[];
      final resultFuture = NougatService.convertPdf(
        'nougat', 'output', 'paper.pdf', 
        (data) => progressList.add(data),
        processStarter: (exe, args, {runInShell = true}) async => mockProcess,
      );

      // Format 1: normal
      stderrController.add(utf8.encode(' 20%|██        | 1/5 [00:01<00:04,  1.10s/pages]\n'));
      // Format 2: no duration
      stderrController.add(utf8.encode(' 40%|████      | 2/5\n'));
      // Format 3: extra info
      stderrController.add(utf8.encode(' 100%|██████████| 5/5 [00:05<00:00,  1.00s/pages] Done!\n'));

      exitCodeCompleter.complete(0);
      await stdoutController.close();
      await stderrController.close();
      await resultFuture;

      expect(progressList.length, 3);
      expect(progressList[0].percent, 20);
      expect(progressList[1].percent, 40);
      expect(progressList[2].percent, 100);
    });

    test('scanFileMd handles multiple files and sorts by date', () async {
      final tempDir = await Directory.systemTemp.createTemp('sort_test');
      try {
        final f1 = File('${tempDir.path}/old.mmd');
        await f1.writeAsString('old content');
        await Future.delayed(const Duration(milliseconds: 1000)); // 1 second delay for Windows
        
        final f2 = File('${tempDir.path}/new.mmd');
        await f2.writeAsString('new content');

        final result = await NougatService.scanFileMd(tempDir.path);
        expect(result.resultCode, 1);
        expect(result.contentData, 'new content');
        expect(result.fileName, 'new.mmd');
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('scanFileMd returns resultCode 0 for empty files', () async {
       final tempDir = await Directory.systemTemp.createTemp('empty_test');
         final result = await NougatService.scanFileMd(tempDir.path);
         expect(result.resultCode, 0);
       } finally {
         await tempDir.delete(recursive: true);
       }
    });
  });
}
