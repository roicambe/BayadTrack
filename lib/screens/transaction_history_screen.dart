import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/history_model.dart';
import '../database/history_service.dart';
import '../database/transaction_model.dart';
import '../services/app_dialog.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Debug/audit history screen showing all Add, Edit, and Delete actions
/// performed on transactions. Accessible only from the Settings screen.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _historyService = HistoryService();
  List<TransactionHistoryEntry> _entries = [];
  bool _isLoading = true;
  int _currentPage = 1;
  static const int _itemsPerPage = 30;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _historyService.getAllEntries();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await AppDialog.showDeleteConfirmation(
      context,
      title: 'Clear Transaction History?',
      content:
          'All history records will be permanently deleted. This action cannot be undone.',
    );
    if (confirmed == true && mounted) {
      await _historyService.clearAll();
      setState(() {
        _entries = [];
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Debug & Audit Log',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded,
                  color: Colors.red.shade400),
              tooltip: 'Clear All History',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _EmptyHistoryState(isDark: isDark, theme: theme)
              : _HistoryList(
                  entries: _entries,
                  currentPage: _currentPage,
                  itemsPerPage: _itemsPerPage,
                  isDark: isDark,
                  theme: theme,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryList
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<TransactionHistoryEntry> entries;
  final int currentPage;
  final int itemsPerPage;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<int> onPageChanged;

  const _HistoryList({
    required this.entries,
    required this.currentPage,
    required this.itemsPerPage,
    required this.isDark,
    required this.theme,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (entries.length / itemsPerPage).ceil();
    final displayPage = currentPage.clamp(1, totalPages == 0 ? 1 : totalPages);
    final start = (displayPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage < entries.length)
        ? start + itemsPerPage
        : entries.length;
    final pageEntries = entries.sublist(start, end);

    final children = <Widget>[];

    for (int i = 0; i < pageEntries.length; i++) {
      final entry = pageEntries[i];
      final bool isFirst = i == 0;
      bool showDateSep = isFirst;

      if (!isFirst) {
        final prev = pageEntries[i - 1];
        final curDay = DateTime(
            entry.recordedAt.year, entry.recordedAt.month, entry.recordedAt.day);
        final prevDay = DateTime(prev.recordedAt.year, prev.recordedAt.month,
            prev.recordedAt.day);
        if (curDay != prevDay) showDateSep = true;
      }

      if (showDateSep) {
        children.add(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFirst) const SizedBox(height: 12),
            _HistoryDateSeparator(date: entry.recordedAt, isDark: isDark, theme: theme),
            const SizedBox(height: 16),
          ],
        ));
      } else if (i > 0) {
        children.add(const SizedBox(height: 10));
      }

      children.add(_HistoryCard(entry: entry, isDark: isDark, theme: theme));
    }

    if (totalPages > 1) {
      children.add(const SizedBox(height: 28));
      children.add(_HistoryPagination(
        currentPage: displayPage,
        totalPages: totalPages,
        isDark: isDark,
        theme: theme,
        onPageChanged: onPageChanged,
      ));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 32),
      children: children,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryDateSeparator
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryDateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isDark;
  final ThemeData theme;

  const _HistoryDateSeparator({
    required this.date,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMMd().format(date);
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white30 : Colors.black26,
            thickness: 1.2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Text(
            dateStr,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white30 : Colors.black26,
            thickness: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryCard
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final TransactionHistoryEntry entry;
  final bool isDark;
  final ThemeData theme;

  const _HistoryCard({
    required this.entry,
    required this.isDark,
    required this.theme,
  });

  // Action → color
  static const _actionColors = {
    HistoryActionType.add:    Color(0xFF22C55E), // green
    HistoryActionType.edit:   Color(0xFFF59E0B), // orange
    HistoryActionType.delete: Color(0xFFEF4444), // red
  };

  static const _actionLabels = {
    HistoryActionType.add:    'ADD',
    HistoryActionType.edit:   'EDIT',
    HistoryActionType.delete: 'DELETE',
  };

  static const _actionIcons = {
    HistoryActionType.add:    Icons.add_circle_outline_rounded,
    HistoryActionType.edit:   Icons.edit_outlined,
    HistoryActionType.delete: Icons.delete_outline_rounded,
  };

  static const _platformColors = {
    Platform.gcash:     AppColors.gcash,
    Platform.maya:      AppColors.maya,
    Platform.grabpay:   Color(0xFF00B14F),
    Platform.shopeepay: Color(0xFFEE4D2D),
    Platform.other:     Color(0xFF888888),
  };

  static const _platformLabels = {
    Platform.gcash:     'GCash',
    Platform.maya:      'Maya',
    Platform.grabpay:   'GrabPay',
    Platform.shopeepay: 'ShopeePay',
    Platform.other:     'Other',
  };

  String get _sourceLabel {
    switch (entry.sourceType) {
      case HistorySourceType.sharedText:  return 'Shared Text';
      case HistorySourceType.pasteText:   return 'Pasted Text';
      case HistorySourceType.manualInput: return 'Manual Input';
      case HistorySourceType.imageUpload: return 'Image Upload';
      case HistorySourceType.edit:        return 'Edited';
      case HistorySourceType.delete:      return 'Deleted';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _actionColors[entry.action] ?? Colors.grey;
    final platformColor = _platformColors[entry.platform] ?? Colors.grey;
    final actionLabel = _actionLabels[entry.action] ?? 'ACTION';
    final actionIcon = _actionIcons[entry.action] ?? Icons.history_rounded;
    final platformLabel = _platformLabels[entry.platform] ?? 'Unknown';
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return GestureDetector(
      onTap: () => _showSnapshotModal(context, actionColor),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: actionColor, width: 4),
            top: isDark
                ? BorderSide(color: actionColor.withValues(alpha: 0.15), width: 1)
                : BorderSide.none,
            right: isDark
                ? BorderSide(color: actionColor.withValues(alpha: 0.15), width: 1)
                : BorderSide.none,
            bottom: isDark
                ? BorderSide(color: actionColor.withValues(alpha: 0.15), width: 1)
                : BorderSide.none,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action badge + platform badge row
                    Row(
                      children: [
                        _Badge(
                          label: actionLabel,
                          color: actionColor,
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          label: platformLabel,
                          color: platformColor,
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          label: _sourceLabel,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                          textColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Summary text
                    Text(
                      entry.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),

                    // Timestamp
                    Text(
                      DateFormat('hh:mm a').format(entry.recordedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing chevron
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnapshotModal(BuildContext context, Color actionColor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SnapshotModal(entry: entry, actionColor: actionColor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Badge — small rounded chip used on history cards
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const _Badge({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textScaler: TextScaler.noScaling,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor ?? color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SnapshotModal — bottom sheet showing the full preserved snapshot
// ─────────────────────────────────────────────────────────────────────────────

class _SnapshotModal extends StatelessWidget {
  final TransactionHistoryEntry entry;
  final Color actionColor;

  const _SnapshotModal({
    required this.entry,
    required this.actionColor,
  });

  static const _actionLabels = {
    HistoryActionType.add:    'Add',
    HistoryActionType.edit:   'Edit',
    HistoryActionType.delete: 'Delete',
  };

  static const _platformLabels = {
    Platform.gcash:     'GCash',
    Platform.maya:      'Maya Business',
    Platform.grabpay:   'GrabPay',
    Platform.shopeepay: 'ShopeePay',
    Platform.other:     'Other',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = _actionLabels[entry.action] ?? 'Action';
    final platformLabel = _platformLabels[entry.platform] ?? 'Unknown';

    // Parse snapshot JSON
    Map<String, dynamic>? parsedJson;
    try {
      if (entry.snapshot.startsWith('{')) {
        parsedJson = jsonDecode(entry.snapshot) as Map<String, dynamic>;
      }
    } catch (_) {
      // not a json or failed to parse, fallback to plain text (parsedJson = null)
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$actionLabel — $platformLabel',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateFormat('MMMM d, yyyy • hh:mm a')
                      .format(entry.recordedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),

            // Snapshot content
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'Preserved Snapshot',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (parsedJson == null)
                    // Legacy plain text snapshot fallback
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: SelectableText(
                        entry.snapshot,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.7,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    )
                  else if (parsedJson['type'] == 'edit_diff') ...[
                    if (parsedJson.containsKey('diff')) ...[
                      // Show side-by-side edits first
                      _buildEditDiffTable(context, parsedJson, theme),
                      const SizedBox(height: 24),
                      Text(
                        'Complete Details',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldsTable(context, parsedJson, theme),
                    ] else ...[
                      // Legacy edit entry fallback: show comparison table
                      _buildEditDiffTable(context, parsedJson, theme),
                    ],
                  ]
                  else
                    // Normal details table (fields)
                    _buildFieldsTable(context, parsedJson, theme),

                  if (parsedJson != null && parsedJson.containsKey('rawText')) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Original Raw Text',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: SelectableText(
                        parsedJson['rawText'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  // Entry metadata row
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Entry ID: ${entry.id}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsTable(BuildContext context, Map<String, dynamic> parsed, ThemeData theme) {
    final fields = parsed['fields'] as List<dynamic>;
    if (fields.isEmpty) {
      return const Center(child: Text('No details preserved.'));
    }

    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text('Field', style: headerStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text('Value', style: headerStyle),
              ),
            ],
          ),
          ...fields.map((f) {
            final field = f as Map<String, dynamic>;
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: Text(field['label'] as String, style: labelStyle),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: SelectableText(field['value'] as String, style: valueStyle),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEditDiffTable(BuildContext context, Map<String, dynamic> parsed, ThemeData theme) {
    final diffs = parsed.containsKey('diff')
        ? (parsed['diff'] as List<dynamic>)
        : (parsed['fields'] as List<dynamic>);
    if (diffs.isEmpty) {
      return const Center(child: Text('No changes detected in this edit transaction.'));
    }

    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final beforeStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: Colors.red.shade400,
      decoration: TextDecoration.lineThrough,
    );
    final afterStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.green.shade500,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text('Field', style: headerStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text('Before', style: headerStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text('After', style: headerStyle),
              ),
            ],
          ),
          ...diffs.map((f) {
            final field = f as Map<String, dynamic>;
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: Text(field['label'] as String, style: labelStyle),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: SelectableText(field['before'] as String, style: beforeStyle),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: SelectableText(field['after'] as String, style: afterStyle),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyHistoryState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHistoryState extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _EmptyHistoryState({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 60,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'History entries will appear here\nafter transactions are added, edited, or deleted.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryPagination — mirrors the style used in data_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<int> onPageChanged;

  const _HistoryPagination({
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
    required this.theme,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> pageItems = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pageItems.add(i);
      }
    } else {
      pageItems.add(1);
      int start = currentPage - 1;
      int end = currentPage + 1;
      if (currentPage <= 3) {
        start = 2;
        end = 4;
      } else if (currentPage >= totalPages - 2) {
        start = totalPages - 3;
        end = totalPages - 1;
      }
      if (start > 2) pageItems.add('...');
      for (int i = start; i <= end; i++) {
        pageItems.add(i);
      }
      if (end < totalPages - 1) pageItems.add('...');
      pageItems.add(totalPages);
    }

    final accentColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: currentPage > 1
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white30 : Colors.black26),
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          ...pageItems.map((item) {
            if (item == '...') {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  '...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final pageNum = item as int;
            final isSelected = pageNum == currentPage;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: 36,
              height: 36,
              child: Material(
                color: isSelected ? accentColor : Colors.transparent,
                shape: CircleBorder(
                  side: BorderSide(
                    color: isSelected
                        ? accentColor
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (!isSelected) onPageChanged(pageNum);
                  },
                  child: Center(
                    child: Text(
                      pageNum.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: currentPage < totalPages
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white30 : Colors.black26),
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
