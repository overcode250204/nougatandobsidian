import 'dart:io';

class ObsidianService {
  static Future<String?> saveToObsidian(String markdown,String? selectedPdf, String vaultPath) async {
    if (markdown.isEmpty) return null;

      await Directory(vaultPath).create(recursive: true);

      final pdfName =
          selectedPdf?.split('\\').last.replaceAll('.pdf', '') ?? 'paper';

      final output = File('$vaultPath\\$pdfName.md');

      await output.writeAsString(markdown, flush: true);

      return output.path;

  }
}