import 'package:file_picker/file_picker.dart';

abstract class IFileService {
  Future<FilePickerResult?> getPdf();
  Future<String?> getDirectory();
}

class FileServiceWrapper implements IFileService {
  @override
  Future<FilePickerResult?> getPdf() async {
    return FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  @override
  Future<String?> getDirectory() async {
    return FilePicker.platform.getDirectoryPath();
  }
}
