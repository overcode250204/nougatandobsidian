import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';
import 'package:paper_to_obsidian/core/constants/app_path.dart';

void main() {
  group('PrefService Test', () {
    test('loadPathConfig returns default values when no data is saved', () async {
      SharedPreferences.setMockInitialValues({});
      
      final config = await loadPathConfig();
      
      expect(config.nougatExe, AppPathConfig.nougatExe);
      expect(config.outputDir, AppPathConfig.outputDir);
      expect(config.vaultPath, AppPathConfig.vaultPath);
    });

    test('savePathConfig and loadPathConfig work together', () async {
      SharedPreferences.setMockInitialValues({});
      
      const testNougat = 'path/to/nougat.exe';
      const testOutput = 'path/to/output';
      const testVault = 'path/to/vault';
      
      await savePathConfig(testNougat, testOutput, testVault);
      
      final config = await loadPathConfig();
      
      expect(config.nougatExe, testNougat);
      expect(config.outputDir, testOutput);
      expect(config.vaultPath, testVault);
    });
  });
}
