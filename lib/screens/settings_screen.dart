import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';

/// Settings screen — three sections:
///   1. Appearance   — Light / Dark / System theme toggle with visual previews
///   2. App Text Size — A / A+ / A++ font scale selector
///   3. Data & Reports — Export and backup action buttons
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds this widget whenever ThemeProvider notifies
    final provider = context.watch<ThemeProvider>();
    final theme    = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headers removed for a cleaner interface
            const SizedBox(height: 16),

            // ── Section 1: Appearance ──────────────────────────────────────
            _SectionHeader('Appearance'),
            const SizedBox(height: 12),
            _AppearanceSection(provider: provider),
            const SizedBox(height: 24),

            // ── Section 1.5: Font Family ───────────────────────────────────
            _SectionHeader('Font Family'),
            const SizedBox(height: 12),
            _FontFamilySection(provider: provider),
            const SizedBox(height: 24),

            // ── Section 2: App Text Size ───────────────────────────────────
            _SectionHeader('App Text Size'),
            const SizedBox(height: 4),
            Text(
              'Affects all text across the app instantly.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _FontSizeSection(provider: provider),
            const SizedBox(height: 24),

            // ── Section 3: Data & Reports ──────────────────────────────────
            _SectionHeader('Data & Reports'),
            const SizedBox(height: 12),
            _DataActionButton(
              icon:  Icons.table_chart_outlined,
              label: 'Export to Excel',
              color: AppColors.excelGreen,
              onTap: () {
                // TODO: implement Excel export
              },
            ),
            const SizedBox(height: 10),
            _DataActionButton(
              icon:  Icons.picture_as_pdf_outlined,
              label: 'Export to PDF',
              color: AppColors.pdfRed,
              onTap: () {
                // TODO: implement PDF export
              },
            ),
            const SizedBox(height: 10),
            _DataActionButton(
              icon:  Icons.backup_outlined,
              label: 'Backup Database',
              color: AppColors.backupBlue,
              onTap: () {
                // TODO: implement database backup
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1 — Appearance (Theme Toggle)
// ─────────────────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final ThemeProvider provider;
  const _AppearanceSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeOption(
            label: 'Light',
            icon: Icons.wb_sunny_rounded,
            previewBg: const Color(0xFFF4F6FA),
            previewText: const Color(0xFF1A1D2E),
            isSelected: provider.isLight,
            onTap: () => provider.setThemeMode(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ThemeOption(
            label: 'Dark',
            icon: Icons.nightlight_round,
            previewBg: const Color(0xFF2C2C2E),
            previewText: const Color(0xFFF0F2F8),
            isSelected: provider.isDark,
            onTap: () => provider.setThemeMode(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ThemeOption(
            label: 'System',
            icon: Icons.settings_suggest_rounded,
            // Preview mirrors the device's actual current mode
            previewBg: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF4F6FA),
            previewText: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF0F2F8)
                : const Color(0xFF1A1D2E),
            isSelected: provider.isSystem,
            onTap: () => provider.setThemeMode(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

/// Single theme option card with a small preview box.
class _ThemeOption extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        previewBg;
  final Color        previewText;
  final bool         isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.previewBg,
    required this.previewText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary
                : theme.colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Preview box — shows what the theme looks like
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: Icon(icon, color: primary, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            // Label — use TextScaler.noScaling so it doesn't scale with font size
            Text(
              label,
              textScaler: TextScaler.noScaling,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? primary : null,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1.5 — Font Family Toggle
// ─────────────────────────────────────────────────────────────────────────────

class _FontFamilySection extends StatelessWidget {
  final ThemeProvider provider;
  const _FontFamilySection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FontOption(
            label: 'Poppins',
            isPoppins: true,
            isSelected: provider.usePoppins,
            onTap: () => provider.setUsePoppins(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FontOption(
            label: 'System',
            isPoppins: false,
            isSelected: !provider.usePoppins,
            onTap: () => provider.setUsePoppins(false),
          ),
        ),
      ],
    );
  }
}

class _FontOption extends StatelessWidget {
  final String       label;
  final bool         isPoppins;
  final bool         isSelected;
  final VoidCallback onTap;

  const _FontOption({
    required this.label,
    required this.isPoppins,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary
                : theme.colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textScaler: TextScaler.noScaling,
            style: isPoppins 
              ? GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : null,
                )
              : TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : null,
                ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2 — Font Size Selector
// ─────────────────────────────────────────────────────────────────────────────

class _FontSizeSection extends StatelessWidget {
  final ThemeProvider provider;
  const _FontSizeSection({required this.provider});

  // Each entry: (scale factor, button label, preview size, subtitle)
  static const _options = [
    (scale: 1.0, label: 'A',   size: 18.0, name: 'Normal'),
    (scale: 1.2, label: 'A+',  size: 22.0, name: 'Large'),
    (scale: 1.4, label: 'A++', size: 26.0, name: 'Extra\nLarge'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: _options.asMap().entries.map((entry) {
        final opt        = entry.value;
        final isLast     = entry.key == _options.length - 1;
        final isSelected = (provider.fontScale - opt.scale).abs() < 0.01;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: GestureDetector(
              onTap: () => provider.setFontScale(opt.scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.10)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Preview letter — always rendered at opt.size regardless
                    // of the current font scale so the button shows its own size
                    Text(
                      opt.label,
                      textScaler: TextScaler.noScaling,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: opt.size,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? primary
                            : theme.textTheme.bodyLarge?.color,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt.name,
                      textScaler: TextScaler.noScaling,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? primary : null,
                        fontWeight: isSelected ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Data Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _DataActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _DataActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? color.withValues(alpha: 0.12)
          : color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Button label
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Trailing arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.50),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
