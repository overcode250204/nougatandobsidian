import 'package:flutter/material.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';

class ConfigPathScreen extends StatefulWidget {
  final IFileService? fileService;
  
  const ConfigPathScreen({super.key, this.fileService});

  @override
  State<ConfigPathScreen> createState() => _ConfigPathScreenState();
}

class _ConfigPathScreenState extends State<ConfigPathScreen> {
  final _nougatExeCtrl = TextEditingController();
  final _outputDirCtrl = TextEditingController();
  final _vaultPathCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPaths();
  }

  Future<void> _loadSavedPaths() async {
    final config = await loadPathConfig();
    setState(() {
      _nougatExeCtrl.text = config.nougatExe!;
      _outputDirCtrl.text = config.outputDir!;
      _vaultPathCtrl.text = config.vaultPath!;
    });
  }

  Future<void> _onPickNougatExe() async {
    final fileService = widget.fileService ?? FileServiceWrapper();
    final result = await fileService.getPdf(); 
    if (result != null) {
      setState(() {
        _nougatExeCtrl.text = result.files.single.path!;
      });
    }
  }

  Future<void> _onPickOutputDir() async {
    final fileService = widget.fileService ?? FileServiceWrapper();
    final path = await fileService.getDirectory();
    if (path != null) {
      setState(() {
        _outputDirCtrl.text = path;
      });
    }
  }

  Future<void> _onPickVaultPath() async {
    final fileService = widget.fileService ?? FileServiceWrapper();
    final path = await fileService.getDirectory();
    if (path != null) {
      setState(() {
        _vaultPathCtrl.text = path;
      });
    }
  }

  Future<void> _onSave() async {
    await savePathConfig(
      _nougatExeCtrl.text,
      _outputDirCtrl.text,
      _vaultPathCtrl.text,
    );
    if (mounted) {
      snack(context, 'Settings saved successfully!');
    }
  }

  @override
  void dispose() {
    _nougatExeCtrl.dispose();
    _outputDirCtrl.dispose();
    _vaultPathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configuration',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _BrowseField(
                label: 'Nougat EXE Path',
                icon: Icons.terminal,
                value: _nougatExeCtrl.text,
                onBrowse: _onPickNougatExe,
              ),
              const SizedBox(height: 20),
              _BrowseField(
                label: 'Output Directory',
                icon: Icons.output,
                value: _outputDirCtrl.text,
                onBrowse: _onPickOutputDir,
              ),
              const SizedBox(height: 20),
              _BrowseField(
                label: 'Obsidian Vault Folder',
                icon: Icons.book_outlined,
                value: _vaultPathCtrl.text,
                onBrowse: _onPickVaultPath,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _onSave,
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
      ),
    );
  }
}

class _BrowseField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onBrowse;

  const _BrowseField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onBrowse,
  });

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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                  style: TextStyle(color: value.isEmpty ? Colors.white38 : Colors.white, fontSize: 13),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
