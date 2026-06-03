import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:paper_to_obsidian/features/pdf_converter/models/conver_progress.dart';

class NougatService {
  static Future<
    ({
      int exitCode,
      int resultCode,
      String? content,
      String? fileName,
      StringBuffer? stdoutBuf,
    })
  >
  convertPdf(
    String nougatExe,
    String outputDir,
    selectedPdf,
    Function(ConverProgress data) onProgress,
  ) async {
    await Directory(outputDir).create(recursive: true);

    // Clear old outputs
    final oldFiles = Directory(outputDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.mmd') || f.path.endsWith('.md'));
    for (final f in oldFiles) {
      try {
        await f.delete();
      } catch (_) {}
    }

    // Start nougat process (streaming)
    final process = await Process.start(nougatExe, [
      selectedPdf!,
      '-o',
      outputDir,
    ], runInShell: true);

    final stdoutBuf = StringBuffer();

    // Nougat writes tqdm progress to stderr.
    // It has 2 tqdm bars: (1) fast page-scan that hits 100% in seconds,
    // (2) slow model inference — the real progress.
    // We detect bar reset (progress drops significantly) to ignore the scan.
    process.stderr.transform(const SystemEncoding().decoder).listen((chunk) {
      debugPrint('[STDERR] $chunk');
      final match = RegExp(r'(\d+)%.*?\|\s*(\d+)/(\d+)').firstMatch(chunk);
      if (match != null) {
        final percent = int.tryParse(match.group(1) ?? '0') ?? 0;
        final current = match.group(2) ?? '?';
        final total = match.group(3) ?? '?';
        onProgress(
          ConverProgress(percent: percent, current: current, total: total),
        );
      }
    });

    process.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
      debugPrint('[STDOUT] $chunk');
      stdoutBuf.write(chunk);
    });

    int exitCode = await process.exitCode.timeout(
      const Duration(minutes: 30),
      onTimeout: () {
        process.kill();
        return -1;
      },
    );

    /// SCAN OUTPUT
    final resultScan = await scanFileMd(outputDir);
    return (
      exitCode: exitCode,
      resultCode: resultScan.resultCode,
      content: resultScan.contentData,
      fileName: resultScan.fileName,
      stdoutBuf: stdoutBuf,
    );

    // Scan for output mmd
    // scanFileMd();
  }

  static Future<({int resultCode, String? contentData, String? fileName})>
  scanFileMd(String outputDir) async {
    final files = Directory(outputDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.mmd') || f.path.endsWith('.md'))
        .toList();
    if (files.isEmpty) {
      return (resultCode: -1, contentData: null, fileName: null);
    }

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    final content = await files.first.readAsString();

    if (content.trim().isEmpty) {
      return (resultCode: 0, contentData: null, fileName: null);
    }
    return (
      resultCode: 1,
      contentData: content,
      fileName: files.first.path.split(r"\\").last,
    );
  }
}
