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
