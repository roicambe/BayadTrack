// Services layer — all backend logic lives here.
//
// Current services:
//   - app_toast.dart          — global reusable toast/snackbar system
//   - format_utils.dart       — display-only number formatting helpers (phone, groups-of-4)
//   - ocr_service.dart        — on-device image text recognition (ML Kit)
//   - receipt_parser.dart     — regex extractor for GCash/Maya receipt text
//
// Planned services:
//   - bluetooth_print_service.dart  (connects to Bluetooth receipt printers)

export 'app_toast.dart';
export 'format_utils.dart';
export 'ocr_service.dart';
export 'receipt_parser.dart';

