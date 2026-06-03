import 'package:flutter/foundation.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';

class ConfigPathController extends ChangeNotifier {
  final IFileService fileService;

  ConfigPathController({IFileService? fileService})
      : fileService = fileService ?? FileServiceWrapper();

  String _nougatExe = '';
  String _outputDir = '';
  String _vaultPath = '';

  String get nougatExe => _nougatExe;
  String get outputDir => _outputDir;
  String get vaultPath => _vaultPath;

  Future<void> load() async {
    final config = await loadPathConfig();
    _nougatExe = config.nougatExe ?? '';
    _outputDir = config.outputDir ?? '';
    _vaultPath = config.vaultPath ?? '';
    notifyListeners();
  }

  Future<void> pickNougatExe() async {
    final result = await fileService.getPdf(); // Reusing for EXE for simplicity in this demo
    if (result != null) {
      _nougatExe = result.files.single.path!;
      notifyListeners();
    }
  }

  Future<void> pickOutputDir() async {
    final path = await fileService.getDirectory();
    if (path != null) {
      _outputDir = path;
      notifyListeners();
    }
  }

  Future<void> pickVaultPath() async {
    final path = await fileService.getDirectory();
    if (path != null) {
      _vaultPath = path;
      notifyListeners();
    }
  }

  Future<void> save() async {
    await savePathConfig(
      _nougatExe,
      _outputDir,
      _vaultPath,
    );
  }
}
