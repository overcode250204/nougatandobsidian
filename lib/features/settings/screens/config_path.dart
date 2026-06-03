import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paper_to_obsidian/core/constants/app_path.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';


class ConfigPathScreen extends StatefulWidget {
  const ConfigPathScreen({super.key});

  @override
  State<ConfigPathScreen> createState() => _ConfigPathScreenState();
}

class _ConfigPathScreenState extends State<ConfigPathScreen> {

  String _nougatExe = AppPathConfig.nougatExe;

  String _outputDir = AppPathConfig.outputDir;

  String _vaultPath = AppPathConfig.vaultPath;

  late TextEditingController _nougatExeCtrl;
  late TextEditingController _outputDirCtrl;
  late TextEditingController _vaultPathCtrl;

  @override
  void initState()  {
    super.initState();

    _nougatExeCtrl = TextEditingController(text: _nougatExe);

    _outputDirCtrl = TextEditingController(text: _outputDir);

    _vaultPathCtrl = TextEditingController(text: _vaultPath);

    _loadInitialData();
  }
  Future<void> _loadInitialData() async {

  final pathConfig = await loadPathConfig();

  if (!mounted) return;

  setState(() {

    _nougatExe =
        pathConfig.nougatExe ?? _nougatExe;

    _outputDir =
        pathConfig.outputDir ?? _outputDir;

    _vaultPath =
        pathConfig.vaultPath ?? _vaultPath;

    _nougatExeCtrl.text = _nougatExe;

    _outputDirCtrl.text = _outputDir;

    _vaultPathCtrl.text = _vaultPath;
  });
}
  Future<void> _savePathConfig(String nougatExe, String outputDir, String vaultPath) async {
  savePathConfig(nougatExe, outputDir, vaultPath);
  snack(context,'Settings saved');
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up the paths required for the conversion process.',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            _BrowseField(
              label: 'Nougat EXE Path',
              icon: Icons.terminal,
              value: _nougatExeCtrl.text,
              onBrowse: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['exe'],
                  dialogTitle: 'Select nougat.exe',
                );
                if (result?.files.single.path != null) {
                  setState(() => _nougatExeCtrl.text = result!.files.single.path!);
                }
              },
            ),
            const SizedBox(height: 20),
            _BrowseField(
              label: 'Output Directory',
              icon: Icons.output,
              value: _outputDirCtrl.text,
              onBrowse: () async {
                final path = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: 'Select output folder for .mmd files',
                );
                if (path != null) setState(() => _outputDirCtrl.text = path);
              },
            ),
            const SizedBox(height: 20),
            _BrowseField(
              label: 'Obsidian Vault Folder',
              icon: Icons.book_outlined,
              value: _vaultPathCtrl.text,
              onBrowse: () async {
                final path = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: 'Select your Obsidian vault folder',
                );
                if (path != null) setState(() => _vaultPathCtrl.text = path);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async => _savePathConfig(_nougatExe, _outputDir, _vaultPath),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseField extends StatelessWidget {
  const _BrowseField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onBrowse,
  });
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  value.isEmpty ? 'Not set' : value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.white30 : Colors.white70,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Browse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 20 / 255)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


