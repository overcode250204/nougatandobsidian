import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/nougat_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/obsidian_service.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';

class PdfConverterScreen extends StatefulWidget {
  final Future<Process> Function(String, List<String>, {bool runInShell})? processStarter;
  final IFileService? fileService;
  
  const PdfConverterScreen({super.key, this.processStarter, this.fileService});

  @override
  State<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends State<PdfConverterScreen> {
  String? _selectedPdf;
  String _markdown = '';
  bool _loading = false;
  double _progress = 0.0;
  String _pageInfo = '';
  String _status = '';

  Future<void> _onPickPdf() async {
    final fileService = widget.fileService ?? FileServiceWrapper();
    final result = await fileService.getPdf();
    if (result != null) {
      setState(() {
        _selectedPdf = result.files.single.path!;
        _markdown = '';
        _status = '';
      });
    }
  }

  Future<void> _onConvertPdf() async {
    if (_selectedPdf == null) return;

    setState(() {
      _loading = true;
      _progress = 0.0;
      _pageInfo = '';
      _status = '⏳ Starting Nougat...';
      _markdown = '';
    });

    try {
      final pathConfig = await loadPathConfig();
      final convertResult = await NougatService.convertPdf(
        pathConfig.nougatExe!,
        pathConfig.outputDir!,
        _selectedPdf,
        (data) {
          final newPct = data.percent / 100;
          if (!mounted) return;
          setState(() {
            if (_progress > 0.5 && newPct < 0.1) {
              _progress = newPct;
            } else if (newPct >= _progress) {
              _progress = newPct;
            }
            _pageInfo = 'Page ${data.current} / ${data.total}';
            _status = '⏳ Converting... ${data.current}/${data.total} (${data.percent}%)';
          });
        },
        processStarter: widget.processStarter,
      );

      if (convertResult.exitCode == -1) {
        setState(() {
          _loading = false;
          _status = '❌ Timeout — PDF may be too large.';
        });
        return;
      }

      if (convertResult.resultCode == -1) {
        setState(() {
          _loading = false;
          _progress = 0;
          _status = '❌ No .mmd output found.\n\nExit: ${convertResult.exitCode}\n${convertResult.stdoutBuf}';
        });
        return;
      }

      if (convertResult.resultCode == 0) {
        setState(() {
          _loading = false;
          _status = '❌ Output file is empty.';
        });
        return;
      }

      setState(() {
        _markdown = convertResult.content!;
        _loading = false;
        _progress = 1.0;
        _pageInfo = '';
        _status = '✅ Conversion complete! (${convertResult.fileName})';
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

  Future<void> _onSaveToObsidian() async {
    final pathConfig = await loadPathConfig();
    try {
      final result = await ObsidianService.saveToObsidian(
        _markdown,
        _selectedPdf,
        pathConfig.vaultPath!,
      );
      if (result == null) return;
      setState(() {
        _status = 'Saved to:\n$result';
      });
    } catch (e) {
      setState(() {
        _status = 'Save failed:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.white54, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedPdf?.split(RegExp(r'[/\\]')).last ?? 'No PDF selected...',
                                  style: TextStyle(
                                    color: _selectedPdf == null ? Colors.white54 : Colors.white,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _onPickPdf,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Browse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_selectedPdf == null || _loading) ? null : _onConvertPdf,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(_loading ? 'Converting...' : 'Convert to Markdown'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markdown.isEmpty ? null : _onSaveToObsidian,
                          icon: const Icon(Icons.save_alt, size: 18),
                          label: const Text('Save to Vault'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                    if (_pageInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _pageInfo,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SelectableText(
                        _status,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.surface,
              child: _markdown.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notes_rounded, size: 64, color: Colors.white.withAlpha(25)),
                          const SizedBox(height: 16),
                          Text(
                            'Your markdown will appear here',
                            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: SelectableText(
                              _markdown,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                height: 1.6,
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton.filled(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _markdown));
                              snack(context, 'Copied to clipboard');
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary.withAlpha(50),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
