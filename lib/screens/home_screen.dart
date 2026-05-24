import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// The main dashboard shown on the Home tab.
///
/// Layout (top to bottom):
///   1. Header  — greeting + date
///   2. Today's Summary — GCash card + Maya card
///   3. Quick Log — two large action buttons
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Today's Summary ─────────────────────────────────────────
            _SectionLabel("Today's Summary"),
            const SizedBox(height: 14),
            _StatCard(
              label: 'GCash Total',
              txnCount: 0,
              total: 0.0,
              brandColor: AppColors.gcash,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Maya Total',
              txnCount: 0,
              total: 0.0,
              brandColor: AppColors.maya,
              icon: Icons.account_balance_wallet_rounded,
            ),
            const SizedBox(height: 32),

            // ── 3. Quick Log ───────────────────────────────────────────────
            _SectionLabel('Quick Log'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _LogButton(
                    label: 'Log GCash',
                    color: AppColors.gcash,
                    onTap: () {
                      // TODO: navigate to Add Transaction screen (GCash)
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LogButton(
                    label: 'Log Maya',
                    color: AppColors.maya,
                    onTap: () {
                      // TODO: navigate to Add Transaction screen (Maya)
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets (used only by HomeScreen — hence the underscore prefix)
// ─────────────────────────────────────────────────────────────────────────────


/// Bold uppercase section labels
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// Large stat card showing a platform's daily total.
class _StatCard extends StatelessWidget {
  final String   label;
  final int      txnCount;
  final double   total;
  final Color    brandColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.txnCount,
    required this.total,
    required this.brandColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Philippine Peso format: ₱1,250.00
    final currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: brandColor.withValues(alpha: 0.25), width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Brand icon circle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: brandColor, size: 28),
          ),
          const SizedBox(width: 16),

          // Label + amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(total),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Transaction count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$txnCount txns',
              style: TextStyle(
                color: brandColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large tappable button for logging a new transaction.
class _LogButton extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _LogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
