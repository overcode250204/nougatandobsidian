import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_to_obsidian/core/services/file_service.dart';
import 'package:paper_to_obsidian/core/services/pref_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/nougat_service.dart';
import 'package:paper_to_obsidian/features/pdf_converter/services/obsidian_service.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';

class PdfConverterScreen extends StatefulWidget {
  const PdfConverterScreen({super.key});

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
    final result = await FileService.getPdf();
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
      // LOAD FILE PATH CONFIG IN LOCAL (PREF) TO CONVER. NOTE: GET DEFAUT IF NULL
      final pathConfig = await loadPathConfig();
      // HANDLE CONVERT
      final convertResult = await NougatService.convertPdf(
        pathConfig.nougatExe!,
        pathConfig.outputDir!,
        // HANLD REAl TIME PROGRESS TRACKING (CALLBACK FUNCTION)
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

            _status =
                '⏳ Converting... '
                '${data.current}/${data.total} '
                '(${data.percent}%)';
          });
        },
      );
      // CHECK TIMEOUT
      if (convertResult.exitCode == -1) {
        setState(() {
          _loading = false;
          _status = '❌ Timeout — PDF may be too large.';
        });
        return;
      }

      // CHECK FILE ALREADY CREATE
      if (convertResult.resultCode == -1) {
        setState(() {
          _loading = false;
          _progress = 0;
          _status =
              '❌ No .mmd output found.\n\nExit: $convertResult.exitCode\n${convertResult.stdoutBuf}';
        });
        return;
      }
      // CHECK FILE IS EMTY??
      if (convertResult.resultCode == 0) {
        setState(() {
          _loading = false;
          _status = '❌ Output file is empty.';
        });
        return;
      }
      // CONVERT SUCCESS => SET DATA TO MARK_DOWN
      setState(() {
        _markdown = convertResult.content!;
        _loading = false;
        _progress = 1.0;
        _pageInfo = '';
        _status = '✅ Conversion complete! ($convertResult.fileName)';
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

  // TO SAVE OBSIBDIAN IF CONVERT SUCCSESS
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
                    onPressed: _loading ? null : _onPickPdf,
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
                          : _onConvertPdf,
                      child: Text(_loading ? 'Converting...' : 'Convert'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _markdown.isEmpty ? null : _onSaveToObsidian,
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C3AED),
                    ),
                  ),
                ),
                if (_pageInfo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _pageInfo,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
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
                    // Error UI
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: SelectableText(
                          _markdown,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton.filled(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _markdown));

                          snack(context, 'Copied');
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
}
