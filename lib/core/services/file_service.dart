

import 'package:file_picker/file_picker.dart';

class FileService {

  static Future<FilePickerResult?> getPdf() async{
    final result = FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return result;
  }
}