import 'dart:io';

class ObsidianService {
  static Future<String?> saveToObsidian(String markdown,String? selectedPdf, String vaultPath) async {
    if (markdown.isEmpty) return null;

      await Directory(vaultPath).create(recursive: true);

      final pdfName =
          selectedPdf?.split(RegExp(r'[/\\]')).last.replaceAll('.pdf', '') ?? 'converted_paper';

      final vaultDir = Directory(vaultPath);
      final output = File('${vaultDir.path}${Platform.pathSeparator}$pdfName.md');

      await output.writeAsString(markdown, flush: true);

      return output.path;

  }
}