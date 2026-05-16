import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Paper2VaultApp());
}

class Paper2VaultApp extends StatelessWidget {
  const Paper2VaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper2Vault',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomePage(),
    );
  }

  ThemeData _buildTheme() {
    const bg = Color(0xFF13111E);
    const surface = Color(0xFF1E1B2E);
    const card = Color(0xFF2A2640);
    const primary = Color(0xFF7C3AED);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        surfaceContainerHighest: card,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: surface, elevation: 0),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _nougatExe = r'D:\FPT\PRM393\paper2vault\venv\Scripts\nougat.exe';

  String _outputDir = r'D:\FPT\PRM393\paper2vault\output';

  String _vaultPath = r'D:\ResearchVault\Papers';

  String? _selectedPdf;

  String _markdown = '';

  bool _loading = false;

  double _progress = 0.0;

  String _pageInfo = '';

  String _status = '';

  bool _showSettings = false;

  late TextEditingController _nougatExeCtrl;
  late TextEditingController _outputDirCtrl;
  late TextEditingController _vaultPathCtrl;

  @override
  void initState() {
    super.initState();

    _nougatExeCtrl = TextEditingController(text: _nougatExe);

    _outputDirCtrl = TextEditingController(text: _outputDir);

    _vaultPathCtrl = TextEditingController(text: _vaultPath);

    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();

    setState(() {
      _nougatExe = p.getString('nougat_exe') ?? _nougatExe;

      _outputDir = p.getString('output_dir') ?? _outputDir;

      _vaultPath = p.getString('vault_path') ?? _vaultPath;

      _nougatExeCtrl.text = _nougatExe;
      _outputDirCtrl.text = _outputDir;
      _vaultPathCtrl.text = _vaultPath;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();

    await p.setString('nougat_exe', _nougatExeCtrl.text.trim());

    await p.setString('output_dir', _outputDirCtrl.text.trim());

    await p.setString('vault_path', _vaultPathCtrl.text.trim());

    setState(() {
      _nougatExe = _nougatExeCtrl.text.trim();

      _outputDir = _outputDirCtrl.text.trim();

      _vaultPath = _vaultPathCtrl.text.trim();

      _showSettings = false;
    });

    _snack('Settings saved');
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedPdf = result.files.single.path!;

        _markdown = '';
        _status = '';
      });
    }
  }

  Future<void> _convertPdf() async {
    if (_selectedPdf == null) return;

    setState(() {
      _loading = true;
      _progress = 0.0;
      _pageInfo = '';
      _status = '⏳ Starting Nougat...';
      _markdown = '';
    });

    try {
      await Directory(_outputDir).create(recursive: true);

      // Clear old outputs
      final oldFiles = Directory(_outputDir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.mmd') || f.path.endsWith('.md'));
      for (final f in oldFiles) {
        try { await f.delete(); } catch (_) {}
      }

      // Start nougat process (streaming)
      final process = await Process.start(
        _nougatExe,
        [_selectedPdf!, '-o', _outputDir],
        runInShell: true,
      );

      final stdoutBuf = StringBuffer();

      // Nougat writes tqdm progress to stderr.
      // It has 2 tqdm bars: (1) fast page-scan that hits 100% in seconds,
      // (2) slow model inference — the real progress.
      // We detect bar reset (progress drops significantly) to ignore the scan.
      process.stderr.transform(SystemEncoding().decoder).listen((chunk) {
        debugPrint('[STDERR] $chunk');
        final match = RegExp(r'(\d+)%.*?\|\s*(\d+)/(\d+)').firstMatch(chunk);
        if (match != null) {
          final percent = int.tryParse(match.group(1) ?? '0') ?? 0;
          final current = match.group(2) ?? '?';
          final total = match.group(3) ?? '?';
          final newPct = percent / 100.0;
          setState(() {
            // When a new tqdm bar starts, progress drops back to near 0
            // (e.g., quick page-scan finishes at 100%, then inference starts at 0%)
            if (_progress > 0.5 && newPct < 0.1) {
              // New bar detected — reset and track this one
              _progress = newPct;
            } else if (newPct >= _progress) {
              _progress = newPct;
            }
            _pageInfo = 'Page $current / $total';
            _status = '⏳ Converting... $current/$total ($percent%)';
          });
        }
      });

      process.stdout.transform(SystemEncoding().decoder).listen((chunk) {
        debugPrint('[STDOUT] $chunk');
        stdoutBuf.write(chunk);
      });

      final exitCode = await process.exitCode.timeout(
        const Duration(minutes: 30),
        onTimeout: () { process.kill(); return -1; },
      );

      if (exitCode == -1) {
        setState(() {
          _loading = false;
          _status = '❌ Timeout — PDF may be too large.';
        });
        return;
      }

      // Scan for output mmd
      final files = Directory(_outputDir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.mmd') || f.path.endsWith('.md'))
          .toList();

      if (files.isEmpty) {
        setState(() {
          _loading = false;
          _progress = 0;
          _status = '❌ No .mmd output found.\n\nExit: $exitCode\n${stdoutBuf}';
        });
        return;
      }

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final content = await files.first.readAsString();

      if (content.trim().isEmpty) {
        setState(() {
          _loading = false;
          _status = '❌ Output file is empty.';
        });
        return;
      }

      setState(() {
        _markdown = content;
        _loading = false;
        _progress = 1.0;
        _pageInfo = '';
        _status = '✅ Conversion complete! (${files.first.path.split(r"\\" ).last})';
      });
    } on TimeoutException {
      setState(() {
        _loading = false;
        _status = '❌ Timeout.';
      });
    } catch (e, stack) {
      debugPrint(stack.toString());
      setState(() {
        _loading = false;
        _status = '❌ Exception:\n$e';
      });
    }
  }

  Future<void> _saveToObsidian() async {
    if (_markdown.isEmpty) return;

    try {
      await Directory(_vaultPath).create(recursive: true);

      final pdfName =
          _selectedPdf?.split('\\').last.replaceAll('.pdf', '') ?? 'paper';

      final output = File('$_vaultPath\\$pdfName.md');

      await output.writeAsString(_markdown, flush: true);

      setState(() {
        _status = 'Saved to:\n${output.path}';
      });

      _snack('Saved to Obsidian');
    } catch (e) {
      setState(() {
        _status = 'Save failed:\n$e';
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper2Vault'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
            icon: Icon(_showSettings ? Icons.close : Icons.settings),
          ),
        ],
      ),
      body: _showSettings ? _buildSettings() : _buildMain(),
    );
  }

  Widget _buildMain() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2640),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedPdf?.split('\\').last ?? 'No PDF selected',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loading ? null : _pickPdf,
                    child: const Text('Browse'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedPdf == null || _loading)
                          ? null
                          : _convertPdf,
                      child: Text(_loading ? 'Converting...' : 'Convert'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _markdown.isEmpty ? null : _saveToObsidian,
                      child: const Text('Save to Vault'),
                    ),
                  ),
                ],
              ),
              // Progress bar (shown while loading)
              if (_loading) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
                if (_pageInfo.isNotEmpty) ...[  
                  const SizedBox(height: 4),
                  Text(_pageInfo,
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ],
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _status,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _markdown.isEmpty
              ? const Center(child: Text('Select a PDF to begin'))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: SelectableText(
                        _markdown,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton.filled(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _markdown));

                          _snack('Copied');
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _savePrefs,
          icon: const Icon(Icons.save, size: 16),
          label: const Text('Save Settings'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(controller: ctrl),
      ],
    );
  }
}

// ── Browse Field widget ───────────────────────────────────────────────────────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2640),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Text(
                  value.isEmpty ? 'Not set' : value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.white30 : Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Browse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2640),
                foregroundColor: Colors.white70,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withAlpha(30)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
