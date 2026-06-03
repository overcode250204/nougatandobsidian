import 'package:flutter/material.dart';
import 'package:paper_to_obsidian/features/pdf_converter/controllers/pdf_converter_controller.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';
import 'package:flutter/services.dart';

class PdfConverterScreen extends StatefulWidget {
  final PdfConverterController controller;
  
  const PdfConverterScreen({super.key, required this.controller});

  @override
  State<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends State<PdfConverterScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.controller;

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
                                  c.selectedPdf?.split(RegExp(r'[/\\]')).last ?? 'No PDF selected...',
                                  style: TextStyle(
                                    color: c.selectedPdf == null ? Colors.white54 : Colors.white,
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
                        onPressed: c.loading ? null : c.pickPdf,
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
                          onPressed: (c.selectedPdf == null || c.loading) ? null : c.convertPdf,
                          icon: c.loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(c.loading ? 'Converting...' : 'Convert to Markdown'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: c.markdown.isEmpty ? null : c.saveToObsidian,
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
                  if (c.loading) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: c.progress > 0 ? c.progress : null,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                    if (c.pageInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          c.pageInfo,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                  if (c.status.isNotEmpty) ...[
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
                        c.status,
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
              child: c.markdown.isEmpty
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
                              c.markdown,
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
                              Clipboard.setData(ClipboardData(text: c.markdown));
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
