import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:file_picker/file_picker.dart';

// Import các file của bạn ở đây
import 'package:paper_to_obsidian/core/services/file_service_interface.dart';
import 'package:paper_to_obsidian/features/pdf_converter/controllers/pdf_converter_controller.dart';

// Tạo Mock class
class MockFileService extends Mock implements IFileService {
  Future<FilePickerResult?>? _getPdfResponse;

  @override
  Future<FilePickerResult?> getPdf() => _getPdfResponse ?? Future.value(null);

  void setGetPdfResponse(Future<FilePickerResult?>? response) {
    _getPdfResponse = response;
  }
}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late PdfConverterController controller;
  late MockFileService mockFileService;

  setUp(() {
    mockFileService = MockFileService();
    controller = PdfConverterController(fileService: mockFileService);
  });

  group('PdfConverterController - Unit Tests', () {
    // --- TEST TRẠNG THÁI KHỞI TẠO ---
    test('Khởi tạo controller với các giá trị mặc định chính xác', () {
      expect(controller.selectedPdf, isNull);
      expect(controller.markdown, '');
      expect(controller.loading, isFalse);
      expect(controller.progress, 0.0);
      expect(controller.pageInfo, '');
      expect(controller.status, '');
    });

    // --- TEST HÀM PICK PDF ---
    group('pickPdf', () {
      test(
        'Khi pick thành công, selectedPdf phải được cập nhật và reset markdown/status',
        () async {
          // Setup: Create mock file
          final mockFile = MockPlatformFile();
          when(mockFile.path).thenReturn('/path/to/sample.pdf');
          final mockResult = FilePickerResult([mockFile]);

          // Setup: Mock the service
          mockFileService.setGetPdfResponse(Future.value(mockResult));

          // Setup: Add listener
          bool isNotified = false;
          controller.addListener(() {
            isNotified = true;
          });

          // Act
          await controller.pickPdf();

          // Assert
          expect(controller.selectedPdf, '/path/to/sample.pdf');
          expect(controller.markdown, isEmpty);
          expect(controller.status, isEmpty);
          expect(isNotified, isTrue);
        },
      );

      test(
        'Khi user hủy pick (result == null), trạng thái cũ giữ nguyên',
        () async {
          // Setup: Mock service to return null
          mockFileService.setGetPdfResponse(Future.value(null));

          // Act
          await controller.pickPdf();

          // Assert
          expect(controller.selectedPdf, isNull);
        },
      );
    });

    // --- TEST HÀM CONVERT PDF (Luồng Guard Clause) ---
    group('convertPdf', () {
      test(
        'Nếu chưa chọn PDF (_selectedPdf == null), hàm phải return ngay lập tức',
        () async {
          // Không set selectedPdf
          await controller.convertPdf();

          // Trạng thái không thay đổi sang loading
          expect(controller.loading, isFalse);
          expect(controller.status, '');
        },
      );

      // Lưu ý của Senior: Để test các đoạn code phía dưới của convertPdf (NougatService.convertPdf),
      // bạn NÊN refactor NougatService từ static thành một Instance và inject vào Controller.
      // Nếu giữ static, việc test dính tới I/O thực tế của NougatExe sẽ biến Unit Test thành Integration Test.
    });

    // --- TEST HÀM COPY TO CLIPBOARD ---
    group('copyToClipboard', () {
      test('Hàm callback onCopy phải nhận đúng dữ liệu markdown hiện tại', () {
        // Thực tế hàm copyToClipboard chỉ pass data qua callback
        String copiedText = '';

        // Giả lập controller đang có markdown
        // Vì _markdown private, ta không set trực tiếp được nếu không refactor,
        // nhưng ta có thể test xem closure hoạt động đúng không.
        controller.copyToClipboard((text) {
          copiedText = text;
        });

        expect(copiedText, controller.markdown);
      });
    });
  });
}
