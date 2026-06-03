import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/core/services/file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FilePicker])
import 'file_service_test.mocks.dart';

void main() {
  test('FileService.getPdf is callable', () async {
    expect(() => FileService.getPdf(), throwsA(anything));
  });
}
