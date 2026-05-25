// Services layer — all backend logic lives here.
//
// Current services:
//   - app_toast.dart          — global reusable toast/snackbar system
//   - ocr_service.dart        — on-device image text recognition (ML Kit)
//   - receipt_parser.dart     — regex extractor for GCash/Maya receipt text
//
// Planned services:
//   - bluetooth_print_service.dart  (connects to Bluetooth receipt printers)

export 'app_toast.dart';
export 'ocr_service.dart';
export 'receipt_parser.dart';
