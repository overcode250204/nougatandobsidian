import 'package:flutter/material.dart';
import 'package:paper_to_obsidian/core/theme/global_theme.dart';
import 'package:paper_to_obsidian/features/pdf_converter/screens/pdf_converter.dart';
import 'package:paper_to_obsidian/features/settings/screens/config_path.dart';
import 'package:paper_to_obsidian/features/pdf_converter/controllers/pdf_converter_controller.dart';
import 'package:paper_to_obsidian/features/settings/controllers/config_path_controller.dart';

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
      theme: getThemeDefault(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showSettings = false;
  late PdfConverterController _pdfController;
  late ConfigPathController _configController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfConverterController();
    _configController = ConfigPathController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _configController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description, color: Colors.white70),
            SizedBox(width: 12),
            Text('Paper2Vault'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: child.key == const ValueKey('icon1')
                      ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                      : Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  _showSettings ? Icons.close : Icons.settings_outlined,
                  key: ValueKey(_showSettings ? 'icon1' : 'icon2'),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _showSettings
            ? ConfigPathScreen(key: const ValueKey('config'), controller: _configController)
            : PdfConverterScreen(key: const ValueKey('converter'), controller: _pdfController),
      ),
    );
  }
}
