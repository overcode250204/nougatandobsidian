import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/nougat_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/obsidian_service.dart';

class PdfConverterController extends ChangeNotifier {
  final Future<Process> Function(String, List<String>, {bool runInShell})? processStarter;
  final IFileService fileService;

  PdfConverterController({
    this.processStarter,
    IFileService? fileService,
  }) : fileService = fileService ?? FileServiceWrapper();

  String? _selectedPdf;
  String _markdown = '';
  bool _loading = false;
  double _progress = 0.0;
  String _pageInfo = '';
  String _status = '';

  String? get selectedPdf => _selectedPdf;
  String get markdown => _markdown;
  bool get loading => _loading;
  double get progress => _progress;
  String get pageInfo => _pageInfo;
  String get status => _status;

  Future<void> pickPdf() async {
    final result = await fileService.getPdf();
    if (result != null) {
      _selectedPdf = result.files.single.path!;
      _markdown = '';
      _status = '';
      notifyListeners();
    }
  }

  Future<void> convertPdf() async {
    if (_selectedPdf == null) return;

    _loading = true;
    _progress = 0.0;
    _pageInfo = '';
    _status = '⏳ Starting Nougat...';
    _markdown = '';
    notifyListeners();

    try {
      final pathConfig = await loadPathConfig();
      final convertResult = await NougatService.convertPdf(
        pathConfig.nougatExe!,
        pathConfig.outputDir!,
        _selectedPdf,
        (data) {
          final newPct = data.percent / 100;
          
          if (_progress > 0.5 && newPct < 0.1) {
            _progress = newPct;
          } else if (newPct >= _progress) {
            _progress = newPct;
          }
          _pageInfo = 'Page ${data.current} / ${data.total}';
          _status = '⏳ Converting... ${data.current}/${data.total} (${data.percent}%)';
          notifyListeners();
        },
        processStarter: processStarter,
      );

      if (convertResult.exitCode == -1) {
        _loading = false;
        _status = '❌ Timeout — PDF may be too large.';
        notifyListeners();
        return;
      }

      if (convertResult.resultCode == -1) {
        _loading = false;
        _progress = 0;
        _status = '❌ No .mmd output found.\n\nExit: ${convertResult.exitCode}\n${convertResult.stdoutBuf}';
        notifyListeners();
        return;
      }

      if (convertResult.resultCode == 0) {
        _loading = false;
        _status = '❌ Output file is empty.';
        notifyListeners();
        return;
      }

      _markdown = convertResult.content!;
      _loading = false;
      _progress = 1.0;
      _pageInfo = '';
      _status = '✅ Conversion complete! (${convertResult.fileName})';
      notifyListeners();
    } on TimeoutException {
      _loading = false;
      _status = '❌ Timeout.';
      notifyListeners();
    } catch (e) {
      _loading = false;
      _status = '❌ Exception:\n$e';
      notifyListeners();
    }
  }

  Future<String?> saveToObsidian() async {
    final pathConfig = await loadPathConfig();
    try {
      final result = await ObsidianService.saveToObsidian(
        _markdown,
        _selectedPdf,
        pathConfig.vaultPath!,
      );
      if (result != null) {
        _status = 'Saved to:\n$result';
        notifyListeners();
      }
      return result;
    } catch (e) {
      _status = 'Save failed:\n$e';
      notifyListeners();
      return null;
    }
  }

  void copyToClipboard(Function(String) onCopy) {
    onCopy(_markdown);
  }
}
