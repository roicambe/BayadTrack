import 'package:flutter/material.dart';

/// Global reusable dialog / popup system for consistent, emotionally resonant
/// feedback and alerts across BayadTrack.
///
/// Usage:
/// ```dart
/// final confirmed = await AppDialog.showDeleteConfirmation(
///   context,
///   title: 'Delete Transaction?',
///   content: 'This action cannot be undone.',
/// );
/// ```
abstract final class AppDialog {
  /// Base builder to render a highly polished, custom-striped dialog layout.
  static Future<bool?> showThemedDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required String cancelLabel,
    required Color accentColor,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top color accent strip
              Container(
                height: 8,
                color: accentColor,
              ),
              const SizedBox(height: 24),

              // Themed circular icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Symmetrical action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            cancelLabel,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Specific deep orange App Close / Exit confirmation dialog.
  static Future<bool> showExitConfirmation(BuildContext context) async {
    final result = await showThemedDialog(
      context,
      title: 'Exit BayadTrack?',
      content: 'Are you sure you want to close the application?',
      confirmLabel: 'Exit',
      cancelLabel: 'Stay',
      accentColor: const Color(0xFFE65100), // Distinct Exit Orange
      icon: Icons.exit_to_app_rounded,
    );
    return result ?? false;
  }

  /// Specific red destructive Delete confirmation dialog.
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final result = await showThemedDialog(
      context,
      title: title,
      content: content,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      accentColor: const Color(0xFFC62828), // Destructive Red
      icon: Icons.delete_forever_rounded,
    );
    return result ?? false;
  }

  /// Single-button informational dialog — same polished design as [showThemedDialog]
  /// but with only a confirm/OK button. Use when there is nothing to cancel,
  /// e.g. validation errors or duplicate warnings where the save is already blocked.
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required Widget content,
    required String confirmLabel,
    required Color accentColor,
    required IconData icon,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top color accent strip
              Container(
                height: 8,
                color: accentColor,
              ),
              const SizedBox(height: 24),

              // Themed circular icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  child: content,
                ),
              ),
              const SizedBox(height: 24),

              // Single action button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Duplicate reference number alert — informational, save is already blocked.
  /// [refNumber] is shown highlighted in [accentColor].
  static Future<void> showDuplicateReferenceAlert(
    BuildContext context, {
    required String refNumber,
    required Color accentColor,
  }) {
    return showInfoDialog(
      context,
      title: 'Duplicate Reference',
      confirmLabel: 'OK',
      accentColor: Colors.amber.shade700,
      icon: Icons.warning_amber_rounded,
      content: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A transaction with reference number:',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  refNumber,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ALREADY EXISTS IN THE DATABASE.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please double-check the reference number before saving.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
