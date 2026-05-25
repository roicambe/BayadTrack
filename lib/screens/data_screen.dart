import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../database/isar_service.dart';
import '../database/transaction_model.dart';
import '../services/app_toast.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../theme/app_colors.dart';
import '../services/app_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab → Platform helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kGCashTab = 0;
const _kMayaTab = 1;

int _tabForPlatform(Platform platform) =>
    platform == Platform.maya ? _kMayaTab : _kGCashTab;

// ─────────────────────────────────────────────────────────────────────────────
// DataScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Data tab — minimal two-platform archive with a floating + button.
class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => DataScreenState();
}

class DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  final _db = IsarService();
  final _picker = ImagePicker();
  bool _isScanning = false;

  late final TabController _tabController;

  static const _tabColors = [AppColors.gcash, AppColors.maya];
  static const _tabPlatforms = [Platform.gcash, Platform.maya];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── External API (called by MainShell share-intent handler) ───────────────

  Future<void> processSharedText(String rawText) async {
    final receipt = ReceiptParser.parse(rawText);
    _autoSwitchTab(receipt.platform);
    if (!mounted) return;
    await _showConfirmDialog(receipt);
  }

  Future<void> processSharedImagePath(String filePath) async {
    setState(() => _isScanning = true);
    try {
      final text = await OcrService.extractText(XFile(filePath));
      final receipt = ReceiptParser.parse(text);
      _autoSwitchTab(receipt.platform);
      if (!mounted) return;
      await _showConfirmDialog(receipt);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not read image. Please try again.');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _autoSwitchTab(Platform platform) {
    final target = _tabForPlatform(platform);
    if (_tabController.index != target) _tabController.animateTo(target);
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
    );
    if (image == null) return;

    setState(() => _isScanning = true);
    try {
      final text = await OcrService.extractText(image);
      final receipt = ReceiptParser.parse(text);
      _autoSwitchTab(receipt.platform);
      if (!mounted) return;
      await _showConfirmDialog(receipt);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'Could not read image. Please try another photo.',
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _openPasteDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PasteTextSheet(
        onSubmit: (text) async {
          Navigator.pop(ctx);
          final receipt = ReceiptParser.parse(text);
          _autoSwitchTab(receipt.platform);
          await _showConfirmDialog(receipt);
        },
      ),
    );
  }

  /// Shows the confirm sheet. Returns true if user confirmed + saved.
  Future<void> _showConfirmDialog(ParsedReceipt receipt) async {
    final editedReceipt = await showModalBottomSheet<ParsedReceipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _ConfirmEntrySheet(receipt: receipt),
    );

    if (editedReceipt == null || !mounted) return;

    try {
      await _db.saveFromParsedReceipt(editedReceipt);
      if (!mounted) return;
      AppToast.success(context, 'Transaction saved!');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to save — please try again.');
    }
  }

  /// Opens the FAB action sheet, awaits the selection, then runs the action.
  Future<void> _openAddActionSheet() async {
    final color = _tabColors[_tabController.index];
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddActionSheet(
        activeColor: color,
        onUpload: () => Navigator.pop(ctx, 'upload'),
        onPaste: () => Navigator.pop(ctx, 'paste'),
      ),
    );

    if (action == null || !mounted) return;

    // Small delay so the first sheet fully dismisses before the next one opens
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    if (action == 'upload') {
      await _pickImageFromGallery();
    } else {
      await _openPasteDialog();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Minimal tab navigation ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Center(
                  child: _MinimalTabBar(controller: _tabController),
                ),
              ),

              // Spacer instead of divider for clean floating look
              const SizedBox(height: 12),

              // ── Swipeable tab content ──────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    2,
                    (i) => _PlatformTabContent(
                      platform: _tabPlatforms[i],
                      brandColor: _tabColors[i],
                      db: _db,
                      isScanning: _isScanning,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Floating add button — lower right, above the nav bar ───────────
        Positioned(
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 105,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final color = _tabColors[_tabController.index];
              return FloatingActionButton(
                heroTag: 'data_add_fab',
                backgroundColor: _isScanning
                    ? color.withValues(alpha: 0.5)
                    : color,
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: _isScanning ? null : _openAddActionSheet,
                child: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.add_rounded, size: 28),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MinimalTabBar — text labels with animated underline, website-style
// ─────────────────────────────────────────────────────────────────────────────

class _MinimalTabBar extends StatelessWidget {
  final TabController controller;
  const _MinimalTabBar({required this.controller});

  static const _labels = ['GCash', 'Maya Business'];
  static const _colors = [AppColors.gcash, AppColors.maya];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_labels.length, (i) {
            final isActive = controller.index == i;
            final color = _colors[i];

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(right: i < _labels.length - 1 ? 20 : 0),
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      // Transparent → color animates smoothly
                      color: isActive ? color : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                  ),
                  child: Text(_labels[i]),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlatformTabContent — filtered list + thin scanning indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PlatformTabContent extends StatelessWidget {
  final Platform platform;
  final Color brandColor;
  final IsarService db;
  final bool isScanning;

  const _PlatformTabContent({
    required this.platform,
    required this.brandColor,
    required this.db,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 2px scanning progress bar at the very top of the content area
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isScanning
              ? LinearProgressIndicator(
                  key: const ValueKey('scanning'),
                  color: brandColor,
                  backgroundColor: brandColor.withValues(alpha: 0.1),
                  minHeight: 2,
                )
              : const SizedBox(height: 2, key: ValueKey('idle')),
        ),

        Expanded(
          child: StreamBuilder<List<TransactionRecord>>(
            stream: db.listenToTransactions().map(
              (all) => all.where((r) => r.platform == platform).toList(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: brandColor),
                );
              }
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return _EmptyState(brandColor: brandColor);
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 180),
                itemCount: records.length,
                separatorBuilder: (ctx2, idx) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TransactionCard(record: records[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddActionSheet — compact bottom sheet shown when the FAB is tapped
// ─────────────────────────────────────────────────────────────────────────────

class _AddActionSheet extends StatelessWidget {
  final Color activeColor;
  final VoidCallback onUpload;
  final VoidCallback onPaste;

  const _AddActionSheet({
    required this.activeColor,
    required this.onUpload,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Title row with brand accent bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add Transaction',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            _SheetOption(
              icon: Icons.photo_library_rounded,
              title: 'Upload Receipt Image',
              subtitle: 'Pick from gallery — we read the text automatically',
              color: activeColor,
              onTap: onUpload,
            ),
            _SheetOption(
              icon: Icons.content_paste_rounded,
              title: 'Paste Manual Text',
              subtitle: 'Paste a GCash or Maya notification message',
              color: activeColor,
              onTap: onPaste,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color brandColor;
  const _EmptyState({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: brandColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 14),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap  +  to upload a receipt.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TransactionCard
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionCard extends StatefulWidget {
  final TransactionRecord record;
  const _TransactionCard({required this.record});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _isDeleteMode = false;
  final _db = IsarService();

  static const _platformColors = {
    Platform.gcash: AppColors.gcash,
    Platform.maya: AppColors.maya,
    Platform.grabpay: Color(0xFF00B14F),
    Platform.shopeepay: Color(0xFFEE4D2D),
    Platform.other: Color(0xFF888888),
  };

  static const _typeLabels = {
    TransactionType.sent: 'Sent',
    TransactionType.received: 'Received',
    TransactionType.cashIn: 'Cash In',
    TransactionType.cashOut: 'Cash Out',
    TransactionType.payment: 'Payment',
  };

  static const _typeIcons = {
    TransactionType.sent: Icons.arrow_upward_rounded,
    TransactionType.received: Icons.arrow_downward_rounded,
    TransactionType.cashIn: Icons.add_card_rounded,
    TransactionType.cashOut: Icons.money_off_rounded,
    TransactionType.payment: Icons.receipt_rounded,
  };

  Future<void> _confirmDelete() async {
    final confirmed = await AppDialog.showDeleteConfirmation(
      context,
      title: 'Delete Transaction?',
      content: 'Are you sure you want to permanently delete this transaction record? This cannot be undone.',
    );

    if (confirmed == true && mounted) {
      try {
        await _db.deleteTransaction(widget.record.id);
        if (!mounted) return;
        AppToast.success(context, 'Transaction deleted!');
      } catch (_) {
        if (!mounted) return;
        AppToast.error(context, 'Failed to delete transaction.');
      }
    }
    
    if (mounted) {
      setState(() {
        _isDeleteMode = false;
      });
    }
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TransactionDetailsSheet(record: widget.record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _platformColors[widget.record.platform] ?? const Color(0xFF888888);
    final currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    final cardBgColor = _isDeleteMode
        ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);

    final cardBorder = _isDeleteMode
        ? Border.all(color: Colors.red.shade400, width: 1.5)
        : (isDark ? Border.all(color: color.withValues(alpha: 0.18), width: 1) : null);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isDeleteMode = true;
        });
      },
      onTap: () {
        if (_isDeleteMode) {
          setState(() {
            _isDeleteMode = false;
          });
        } else {
          _showDetailsSheet(context);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          alignment:    Alignment.centerRight,
          children: [
            // Standard Card Container (Constant width/height, does not shift)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve:    Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        cardBgColor,
                borderRadius: BorderRadius.circular(18),
                border:       cardBorder,
                boxShadow: isDark || _isDeleteMode
                    ? null
                    : [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset:     const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:        color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _typeIcons[widget.record.transactionType] ?? Icons.swap_horiz_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.record.senderName ?? 'Unknown Recipient',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:        color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _typeLabels[widget.record.transactionType] ?? 'Sent',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.record.senderNumber ?? 'No Contact Number',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(widget.record.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.record.transactionType == TransactionType.received
                              ? const Color(0xFF2E7D32)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('MMM d, yyyy • hh:mm a').format(widget.record.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Animated Delete Button Overlay (Slides from right to left on top of the card)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve:    Curves.easeOutCubic,
              right:    _isDeleteMode ? 14 : -70, // slides outside the clipped card area
              child: GestureDetector(
                onTap: _confirmDelete,
                child: Container(
                  width:    44,
                  height:   44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size:  24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TransactionDetailsSheet — interactive display modal for full record info
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionDetailsSheet extends StatefulWidget {
  final TransactionRecord record;
  const _TransactionDetailsSheet({required this.record});

  @override
  State<_TransactionDetailsSheet> createState() => _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<_TransactionDetailsSheet> {
  final _db = IsarService();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _refController;
  late final TextEditingController _balanceController;
  late TransactionType _transactionType;

  static const _platformNames = {
    Platform.gcash: 'GCash',
    Platform.maya: 'Maya Business',
    Platform.grabpay: 'GrabPay',
    Platform.shopeepay: 'ShopeePay',
    Platform.other: 'Other',
  };

  static const _platformColors = {
    Platform.gcash: AppColors.gcash,
    Platform.maya: AppColors.maya,
    Platform.grabpay: Color(0xFF00B14F),
    Platform.shopeepay: Color(0xFFEE4D2D),
    Platform.other: Color(0xFF888888),
  };

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _nameController = TextEditingController(text: r.senderName ?? '');
    _phoneController = TextEditingController(text: r.senderNumber ?? '');
    _amountController = TextEditingController(text: r.amount.toStringAsFixed(2));
    _dateController = TextEditingController(
      text: DateFormat('MMM d, yyyy').format(r.timestamp),
    );
    _timeController = TextEditingController(
      text: DateFormat('hh:mm a').format(r.timestamp),
    );
    _refController = TextEditingController(text: r.referenceNumber);
    _balanceController = TextEditingController(
      text: r.remainingBalance != null ? r.remainingBalance!.toStringAsFixed(2) : '',
    );
    _transactionType = r.transactionType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _refController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initial = widget.record.timestamp;
    try {
      initial = DateFormat('MMM d, yyyy').parse(_dateController.text.trim());
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _platformColors[widget.record.platform] ?? Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay initial = TimeOfDay.fromDateTime(widget.record.timestamp);
    try {
      final parsedDate = DateFormat('hh:mm a').parse(_timeController.text.trim());
      initial = TimeOfDay.fromDateTime(parsedDate);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _platformColors[widget.record.platform] ?? Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _timeController.text = DateFormat('hh:mm a').format(dt);
      });
    }
  }

  Future<void> _onSave() async {
    final amtVal = double.tryParse(_amountController.text.trim()) ?? widget.record.amount;
    final balVal = double.tryParse(_balanceController.text.trim());
    DateTime dtVal;
    try {
      final dateStr = _dateController.text.trim();
      final timeStr = _timeController.text.trim();
      dtVal = DateFormat('MMM d, yyyy hh:mm a').parse('$dateStr $timeStr');
    } catch (_) {
      dtVal = widget.record.timestamp;
    }

    final newName = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    final newPhone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final newRef = _refController.text.trim().isEmpty ? 'UNKNOWN' : _refController.text.trim();

    final isNameChanged = newName != widget.record.senderName;
    final isPhoneChanged = newPhone != widget.record.senderNumber;
    final isAmountChanged = amtVal != widget.record.amount;
    final isDateChanged = dtVal != widget.record.timestamp;
    final isRefChanged = newRef != widget.record.referenceNumber;
    final isBalanceChanged = balVal != widget.record.remainingBalance;
    final isTypeChanged = _transactionType != widget.record.transactionType;

    final hasChanges = isNameChanged ||
        isPhoneChanged ||
        isAmountChanged ||
        isDateChanged ||
        isRefChanged ||
        isBalanceChanged ||
        isTypeChanged;

    if (!hasChanges) {
      if (!mounted) return;
      AppToast.warning(context, 'No changes have been made');
      Navigator.of(context).pop();
      return;
    }

    final updated = widget.record
      ..senderName = newName
      ..senderNumber = newPhone
      ..amount = amtVal
      ..timestamp = dtVal
      ..referenceNumber = newRef
      ..remainingBalance = balVal
      ..transactionType = _transactionType;

    try {
      await _db.saveTransaction(updated);
      if (!mounted) return;
      AppToast.success(context, 'Transaction updated!');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update transaction.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _platformColors[widget.record.platform] ?? const Color(0xFF888888);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.70,
        maxChildSize: 0.96,
        builder: (ctx, sc) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Platform badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _platformNames[widget.record.platform] ?? 'Unknown',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Edit Transaction Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),

              // Sent vs Received Segmented Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.sent,
                        label: Text('Sent'),
                        icon: Icon(Icons.arrow_upward_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: TransactionType.received,
                        label: Text('Received'),
                        icon: Icon(Icons.arrow_downward_rounded, size: 18),
                      ),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (set) {
                      setState(() {
                        _transactionType = set.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: color.withValues(alpha: 0.15),
                      selectedForegroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _EditField(
                      label: 'Name (Recipient)',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Contact Number',
                      controller: _phoneController,
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Amount',
                      controller: _amountController,
                      prefixText: '₱',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      activeColor: color,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _EditField(
                            label: 'Date',
                            controller: _dateController,
                            icon: Icons.calendar_month_rounded,
                            activeColor: color,
                            readOnly: true,
                            onTap: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EditField(
                            label: 'Time',
                            controller: _timeController,
                            icon: Icons.access_time_rounded,
                            activeColor: color,
                            readOnly: true,
                            onTap: _selectTime,
                          ),
                        ),
                      ],
                    ),
                    _EditField(
                      label: 'Reference Number',
                      controller: _refController,
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Remaining Balance (E-Wallet)',
                      controller: _balanceController,
                      prefixText: '₱',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      activeColor: color,
                    ),
                    const SizedBox(height: 12),
                    // Read-only Timestamp Field
                    Builder(
                      builder: (context) {
                        final recordedAtToShow = widget.record.recordedAt ?? widget.record.timestamp;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recorded In App At',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      color: color.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat('MMMM d, yyyy • hh:mm a').format(recordedAtToShow),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  28 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text('CANCEL'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _onSave,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text('SAVE'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PasteTextSheet
// ─────────────────────────────────────────────────────────────────────────────

class _PasteTextSheet extends StatefulWidget {
  final Future<void> Function(String text) onSubmit;
  const _PasteTextSheet({required this.onSubmit});

  @override
  State<_PasteTextSheet> createState() => _PasteTextSheetState();
}

class _PasteTextSheetState extends State<_PasteTextSheet> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx2, sc) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Paste GCash / Maya Text',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Paste the notification or receipt text below.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste your receipt message here…',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: isDark
                            ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
                            : BorderSide(color: Colors.grey.shade300, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: isDark
                            ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
                            : BorderSide(color: Colors.grey.shade300, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    key: const ValueKey('btn_submit_paste'),
                    onPressed: _hasText
                        ? () => widget.onSubmit(_controller.text.trim())
                        : null,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Scan for Receipt Data'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmEntrySheet extends StatefulWidget {
  final ParsedReceipt receipt;

  const _ConfirmEntrySheet({required this.receipt});

  @override
  State<_ConfirmEntrySheet> createState() => _ConfirmEntrySheetState();
}

class _ConfirmEntrySheetState extends State<_ConfirmEntrySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _refController;
  late final TextEditingController _balanceController;

  static const _platformNames = {
    Platform.gcash: 'GCash',
    Platform.maya: 'Maya Business',
    Platform.grabpay: 'GrabPay',
    Platform.shopeepay: 'ShopeePay',
    Platform.other: 'Other',
  };

  static const _platformColors = {
    Platform.gcash: AppColors.gcash,
    Platform.maya: AppColors.maya,
    Platform.grabpay: Color(0xFF00B14F),
    Platform.shopeepay: Color(0xFFEE4D2D),
    Platform.other: Color(0xFF888888),
  };

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;
    _nameController = TextEditingController(text: r.personName ?? '');
    _phoneController = TextEditingController(text: r.phoneNumber ?? '');
    _amountController = TextEditingController(
      text: r.amount?.toStringAsFixed(2) ?? '',
    );
    _dateController = TextEditingController(
      text: r.transactionDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(r.transactionDate!)
          : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );
    _refController = TextEditingController(text: r.referenceNumber ?? '');
    _balanceController = TextEditingController(
      text: r.remainingBalance != null
          ? r.remainingBalance!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _refController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onSave() {
    final amtVal = double.tryParse(_amountController.text.trim());
    final balVal = double.tryParse(_balanceController.text.trim());
    DateTime? dtVal;
    try {
      dtVal = DateFormat('yyyy-MM-dd HH:mm').parse(_dateController.text.trim());
    } catch (_) {
      dtVal = widget.receipt.transactionDate;
    }

    final edited = ParsedReceipt(
      rawText: widget.receipt.rawText,
      platform: widget.receipt.platform,
      transactionType: widget.receipt.transactionType,
      amount: amtVal,
      referenceNumber: _refController.text.trim().isEmpty
          ? null
          : _refController.text.trim(),
      personName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      transactionDate: dtVal,
      remainingBalance: balVal,
    );

    Navigator.of(context).pop(edited);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        _platformColors[widget.receipt.platform] ?? const Color(0xFF888888);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.70,
        maxChildSize: 0.96,
        builder: (ctx2, sc) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Platform badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _platformNames[widget.receipt.platform] ?? 'Unknown',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Verify & Correct Transaction',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'OCR extracted fields. Correct any errors below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _EditField(
                      label: 'Name (Recipient)',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Contact Number',
                      controller: _phoneController,
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Amount',
                      controller: _amountController,
                      prefixText: '₱',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Date & Time (YYYY-MM-DD HH:MM)',
                      controller: _dateController,
                      icon: Icons.calendar_month_rounded,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Reference Number',
                      controller: _refController,
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      activeColor: color,
                    ),
                    _EditField(
                      label: 'Remaining Balance (E-Wallet)',
                      controller: _balanceController,
                      prefixText: '₱',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      activeColor: color,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  28 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          key: const ValueKey('btn_cancel_entry'),
                          onPressed: () => Navigator.of(context).pop(null),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text('CANCEL'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          key: const ValueKey('btn_confirm_entry'),
                          onPressed: _onSave,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text('CONFIRM'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? prefixText;
  final TextInputType keyboardType;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool readOnly;

  const _EditField({
    required this.label,
    required this.controller,
    required this.activeColor,
    this.icon,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: activeColor, size: 20)
                  : (prefixText != null
                        ? Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              prefixText!,
                              style: TextStyle(
                                color: activeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : null),
              filled: true,
              fillColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
                    : BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
                    : BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: activeColor, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
