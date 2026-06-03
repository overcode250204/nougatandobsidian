import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paper_to_obsidian/features/settings/controllers/config_path_controller.dart';
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([IFileService])
import 'config_path_controller_test.mocks.dart';

void main() {
  group('ConfigPathController Test', () {
    late ConfigPathController controller;
    late MockIFileService mockFileService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockFileService = MockIFileService();
      controller = ConfigPathController(fileService: mockFileService);
    });

    test('load and save settings', () async {
      await controller.load();
      expect(controller.nougatExe, isNotEmpty); // It has a default value

      when(mockFileService.getPdf()).thenAnswer((_) async => FilePickerResult(<PlatformFile>[
        PlatformFile(name: 'nougat.exe', path: 'C:\\nougat.exe', size: 100)
      ]));

      await controller.pickNougatExe();
      expect(controller.nougatExe, 'C:\\nougat.exe');

      await controller.save();
      
      // Load again to verify
      final newController = ConfigPathController();
      await newController.load();
      expect(newController.nougatExe, 'C:\\nougat.exe');
    });
  });
}
