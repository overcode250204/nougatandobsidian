import 'package:paper_to_obsidian/core/constants/app_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({String? nougatExe, String? outputDir, String? vaultPath})> loadPathConfig() async {
  final p = await SharedPreferences.getInstance();

  return (
    nougatExe: p.getString(KPrefConstant.nougatExe) ?? AppPathConfig.nougatExe,
    outputDir: p.getString(KPrefConstant.outputDir) ?? AppPathConfig.outputDir,
    vaultPath: p.getString(KPrefConstant.vaultPath) ?? AppPathConfig.vaultPath,
  );
}

Future<void> savePathConfig(String nougatExe, String outputDir, String vaultPath) async {
  final p = await SharedPreferences.getInstance();

  await p.setString(KPrefConstant.nougatExe, nougatExe.trim());

  await p.setString(KPrefConstant.outputDir,outputDir.trim());

  await p.setString(KPrefConstant.vaultPath,vaultPath.trim());

}