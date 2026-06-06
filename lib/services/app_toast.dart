import 'package:flutter/material.dart';

/// Global reusable toast / snackbar system for consistent feedback across
/// every screen in BayadTrack.
///
/// Usage:
/// ```dart
/// AppToast.success(context, 'Transaction saved!');
/// AppToast.error(context, 'Could not read image.');
/// AppToast.warning(context, 'Amount not detected — check manually.');
/// AppToast.info(context, 'Tip: You can also paste text.');
/// ```
///
/// Always call this while [BuildContext] is still mounted:
/// ```dart
/// if (!mounted) return;
/// AppToast.success(context, '...');
/// ```
abstract final class AppToast {
  // ── Public convenience constructors ────────────────────────────────────────

  static void success(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.check_circle_rounded,
    color: const Color(0xFF2E7D32),
  );

  static void error(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.error_rounded,
    color: const Color(0xFFC62828),
  );

  static void warning(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.warning_rounded,
    color: const Color(0xFFFFA000),
  );

  static void info(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.info_rounded,
    color: const Color(0xFF1565C0),
  );

  /// Shows a 5-second undo snackbar after a transaction deletion.
  /// Pass [messenger] captured **before** the details sheet is popped so
  /// the reference stays valid after navigation.
  /// [onUndo] is called when the user taps UNDO — caller must re-save the record.
  static void undoDelete(
    ScaffoldMessengerState messenger, {
    required VoidCallback onUndo,
  }) {
    const bgColor = Color(0xFF323232); // neutral dark, same feel as system snackbars

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 105),
          padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: bgColor,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Transaction deleted',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onUndo();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'UNDO',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              IconButton(
                onPressed: () => messenger.hideCurrentSnackBar(),
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
              ),
            ],
          ),
        ),
      );
  }

  // ── Internal renderer ──────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 105),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: color,
          duration: duration,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
