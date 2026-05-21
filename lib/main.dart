import 'package:flutter/material.dart';
import 'package:paper_to_obsidian/core/theme/global_theme.dart';
import 'package:paper_to_obsidian/features/pdf_converter/screens/pdf_converter.dart';
import 'package:paper_to_obsidian/features/settings/screens/config_path.dart';


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
      theme:getThemeDefault(),
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


  @override
  void initState() {
    super.initState();

 
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
      body: _showSettings ? ConfigPathScreen() : PdfConverterScreen(),
    );
  }

  
}
