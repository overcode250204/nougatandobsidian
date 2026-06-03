import 'package:flutter/material.dart';
import 'package:paper_to_obsidian/features/settings/controllers/config_path_controller.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';

class ConfigPathScreen extends StatefulWidget {
  final ConfigPathController controller;
  
  const ConfigPathScreen({super.key, required this.controller});

  @override
  State<ConfigPathScreen> createState() => _ConfigPathScreenState();
}

class _ConfigPathScreenState extends State<ConfigPathScreen> {
  late TextEditingController _nougatExeCtrl;
  late TextEditingController _outputDirCtrl;
  late TextEditingController _vaultPathCtrl;

  @override
  void initState() {
    super.initState();
    _nougatExeCtrl = TextEditingController(text: widget.controller.nougatExe);
    _outputDirCtrl = TextEditingController(text: widget.controller.outputDir);
    _vaultPathCtrl = TextEditingController(text: widget.controller.vaultPath);
    
    widget.controller.addListener(_onControllerUpdate);
    widget.controller.load().then((_) {
      _nougatExeCtrl.text = widget.controller.nougatExe;
      _outputDirCtrl.text = widget.controller.outputDir;
      _vaultPathCtrl.text = widget.controller.vaultPath;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _nougatExeCtrl.dispose();
    _outputDirCtrl.dispose();
    _vaultPathCtrl.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      _nougatExeCtrl.text = widget.controller.nougatExe;
      _outputDirCtrl.text = widget.controller.outputDir;
      _vaultPathCtrl.text = widget.controller.vaultPath;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.controller;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Configuration',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPathField(
            title: 'Nougat EXE Path',
            subtitle: 'Points to nougat.exe (CLI)',
            controller: _nougatExeCtrl,
            onBrowse: c.pickNougatExe,
            icon: Icons.terminal,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPathField(
            title: 'Output Directory',
            subtitle: 'Where temporary .mmd files are saved',
            controller: _outputDirCtrl,
            onBrowse: c.pickOutputDir,
            icon: Icons.folder_zip,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPathField(
            title: 'Obsidian Vault Folder',
            subtitle: 'Target folder in your Obsidian vault',
            controller: _vaultPathCtrl,
            onBrowse: c.pickVaultPath,
            icon: Icons.auto_stories,
            theme: theme,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await c.save();
              if (context.mounted) snack(context, 'Settings Saved ✅');
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathField({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required VoidCallback onBrowse,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      hintText: 'Select path...',
                    ),
                    onChanged: (val) {
                      // Internal update of controller if user types
                    },
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Browse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
