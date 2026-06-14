import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';

import '../database/isar_service.dart';
import '../database/transaction_model.dart';
import '../services/app_toast.dart';
import '../services/format_utils.dart';
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
extension TransactionRecordClassification on TransactionRecord {
  bool get isLoad {
    if (transactionType != TransactionType.payment) return false;
    
    final sp = serviceProvider?.toLowerCase() ?? '';
    
    // Explicit load keywords
    if (sp.contains('load') || sp.contains('allnet') || sp.contains('promo') || sp.contains('data') || sp.contains('surf')) {
      return true;
    }
    
    // Known billers
    final knownBills = [
      'meralco', 'water', 'pldt', 'home credit', 'tala', 'converge', 
      'easytrip', 'rfid', 'maynilad', 'cignal', 'sky', 'sss', 'pag-ibig', 
      'philhealth', 'electric', 'telecom'
    ];
    for (final bill in knownBills) {
      if (sp.contains(bill)) return false;
    }
    
    // If it has an account number, it's a bill
    if (accountNumber != null && accountNumber!.trim().isNotEmpty) {
      return false;
    }
    
    // If it has a sender number but no account number and wasn't caught by known bills, assume Load
    if (senderNumber != null && senderNumber!.trim().isNotEmpty) {
      return true;
    }
    
    return false;
  }

  bool get isBill => transactionType == TransactionType.payment && !isLoad;
}

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

  // Filter states
  String _searchQuery = '';
  DateTimeRange? _dateFilter;
  bool _showSent = true;
  bool _showReceived = true;
  bool _showBills = true;
  bool _showLoad = true;
  Set<String> _selectedProviders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cleanupMockData();
  }

  Future<void> _cleanupMockData() async {
    final all = await _db.getAllTransactions();
    final mocks = all.where((t) => t.referenceNumber.startsWith('MOCK')).toList();
    for (var mock in mocks) {
      await _db.deleteTransaction(mock.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── External API (called by MainShell share-intent handler) ───────────────

  Future<void> processSharedText(String rawText) async {
    final receipts = ReceiptParser.parseBatch(rawText);
    if (receipts.isEmpty) {
      AppToast.error(context, 'No valid transaction found in shared text.');
      return;
    }
    if (receipts.length > 1) {
      AppToast.error(context, 'Please share only 1 transaction at a time.');
      return;
    }
    
    final receipt = receipts.first;
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

  Future<void> _openPasteDialog(Platform platform) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _PasteTextSheet(
        platform: platform,
        onSubmit: (text) async {
          Navigator.pop(ctx);
          final receipts = ReceiptParser.parseBatch(text, platformHint: platform);
          if (receipts.isEmpty) {
            AppToast.error(context, 'No valid transaction found in text.');
            return;
          }

          if (receipts.length > 1) {
            AppToast.error(context, 'Please paste only 1 transaction at a time.');
            return;
          }

          // Single transaction workflow
          final receipt = receipts.first;
          _autoSwitchTab(receipt.platform);
          await _showConfirmDialog(receipt);
        },
      ),
    );
  }

  /// Shows the confirm sheet. Returns true if user confirmed + saved.
  Future<void> _showConfirmDialog(ParsedReceipt receipt, {bool isManual = false}) async {
    final editedReceipt = await showModalBottomSheet<ParsedReceipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _ConfirmEntrySheet(receipt: receipt, isManual: isManual),
    );

    if (editedReceipt == null || !mounted) return;

    try {
      await _db.saveFromParsedReceipt(editedReceipt, manualFee: editedReceipt.fee);
      if (!mounted) return;
      AppToast.success(context, 'Transaction saved!');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to save — please try again.');
    }
  }

  /// Opens the FAB action sheet, awaits the selection, then runs the action.
  Future<void> _openAddActionSheet() async {
    final platform = _tabPlatforms[_tabController.index];
    final color = _tabColors[_tabController.index];
    final allowUpload = platform == Platform.gcash;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddActionSheet(
        platform: platform,
        activeColor: color,
        allowUpload: allowUpload,
        onUpload: () => Navigator.pop(ctx, 'upload'),
        onPaste: () => Navigator.pop(ctx, 'paste'),
        onManual: () => Navigator.pop(ctx, 'manual'),
      ),
    );

    if (action == null || !mounted) return;

    // Small delay so the first sheet fully dismisses before the next one opens
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    if (action == 'upload') {
      await _pickImageFromGallery();
    } else if (action == 'paste') {
      await _openPasteDialog(platform);
    } else if (action == 'manual') {
      final emptyReceipt = ParsedReceipt(
        rawText: '',
        platform: platform,
        transactionType: TransactionType.sent,
        transactionDate: DateTime.now(),
      );
      await _showConfirmDialog(emptyReceipt, isManual: true);
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
              // ── Tab navigation & Icons ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final color = _tabColors[_tabController.index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print_rounded),
                          color: color,
                          onPressed: () {
                            AppToast.info(context, 'Printing feature is not yet available.');
                          },
                        ),
                        _MinimalTabBar(controller: _tabController),
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          color: color,
                          onPressed: () => _showSearchModal(context),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Spacer instead of divider for clean floating look
              const SizedBox(height: 12),

              // ── Swipeable tab content ──────────────────────────────────────
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: List.generate(
                    2,
                    (i) => _PlatformTabContent(
                      platform: _tabPlatforms[i],
                      brandColor: _tabColors[i],
                      db: _db,
                      isScanning: _isScanning,
                      searchQuery: _searchQuery,
                      dateFilter: _dateFilter,
                      showSent: _showSent,
                      showReceived: _showReceived,
                      showBills: _showBills,
                      showLoad: _showLoad,
                      selectedProviders: _selectedProviders,
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

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchFilterModal(
        platform: _tabPlatforms[_tabController.index],
        initialQuery: _searchQuery,
        initialDate: _dateFilter,
        initialSent: _showSent,
        initialReceived: _showReceived,
        initialBills: _showBills,
        initialLoad: _showLoad,
        initialProviders: _selectedProviders,
        onApply: (query, date, sent, received, bills, load, providers) {
          setState(() {
            _searchQuery = query;
            _dateFilter = date;
            _showSent = sent;
            _showReceived = received;
            _showBills = bills;
            _showLoad = load;
            _selectedProviders = providers;
          });
        },
      ),
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
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  child: Text(
                    _labels[i],
                  ),
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

class _PlatformTabContent extends StatefulWidget {
  final Platform platform;
  final Color brandColor;
  final IsarService db;
  final bool isScanning;
  final String searchQuery;
  final DateTimeRange? dateFilter;
  final bool showSent;
  final bool showReceived;
  final bool showBills;
  final bool showLoad;
  final Set<String> selectedProviders;

  const _PlatformTabContent({
    required this.platform,
    required this.brandColor,
    required this.db,
    required this.isScanning,
    required this.searchQuery,
    this.dateFilter,
    required this.showSent,
    required this.showReceived,
    required this.showBills,
    required this.showLoad,
    required this.selectedProviders,
  });

  @override
  State<_PlatformTabContent> createState() => _PlatformTabContentState();
}

class _PlatformTabContentState extends State<_PlatformTabContent> {
  int _currentPage = 1;
  static const int _itemsPerPage = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 2px scanning progress bar at the very top of the content area
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.isScanning
              ? LinearProgressIndicator(
                  key: const ValueKey('scanning'),
                  color: widget.brandColor,
                  backgroundColor: widget.brandColor.withValues(alpha: 0.1),
                  minHeight: 2,
                )
              : const SizedBox(height: 2, key: ValueKey('idle')),
        ),

        Expanded(
          child: StreamBuilder<List<TransactionRecord>>(
            stream: widget.db.listenToTransactions().map(
              (all) => all.where((r) {
                if (r.platform != widget.platform) return false;

                // 1. Date Filter
                if (widget.dateFilter != null) {
                  final start = widget.dateFilter!.start;
                  final end = widget.dateFilter!.end;
                  final tDate = DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
                  // Ensure start and end cover the full days (end should include 23:59:59 if needed, but we check Date only)
                  if (tDate.isBefore(start) || tDate.isAfter(end)) return false;
                }

                // 2. Search Query Filter
                if (widget.searchQuery.isNotEmpty) {
                  final q = widget.searchQuery.toLowerCase();
                  // Strip spaces from query so "0921 528" and "09215288" both match
                  final qStripped = q.replaceAll(RegExp(r'\s+'), '');
                  bool matchQuery = false;
                  if ((r.senderName ?? '').toLowerCase().contains(q)) matchQuery = true;
                  // Strip spaces from stored phone/ref before comparing
                  final phoneStripped = FormatUtils.stripPhone(r.senderNumber ?? '').toLowerCase();
                  final refStripped   = FormatUtils.stripSpaces(r.referenceNumber).toLowerCase();
                  if (phoneStripped.contains(qStripped)) matchQuery = true;
                  if ((r.senderNumber ?? '').toLowerCase().contains(q)) matchQuery = true;
                  if ((r.serviceProvider ?? '').toLowerCase().contains(q)) matchQuery = true;
                  if (refStripped.contains(qStripped)) matchQuery = true;
                  if (r.referenceNumber.toLowerCase().contains(q)) matchQuery = true;
                  if (r.amount.toString().contains(q)) matchQuery = true;
                  if (!matchQuery) return false;
                }

                // 3. Type / Provider Filter
                bool isLoadRecord = r.isLoad;
                bool isBillRecord = r.isBill;

                bool typeMatch = false;
                if (widget.showSent && (r.transactionType == TransactionType.sent || r.transactionType == TransactionType.cashOut)) typeMatch = true;
                if (widget.showReceived && (r.transactionType == TransactionType.received || r.transactionType == TransactionType.cashIn)) typeMatch = true;
                
                if (widget.platform == Platform.maya) {
                  if (widget.showLoad && isLoadRecord) typeMatch = true;
                  if (widget.showBills && isBillRecord) typeMatch = true;
                }

                if (!typeMatch) return false;

                // 4. Maya Provider Filter
                if (widget.platform == Platform.maya && widget.selectedProviders.isNotEmpty && isBillRecord) {
                  final sp = (r.serviceProvider ?? '').toLowerCase();
                  bool providerMatch = false;
                  for (final selected in widget.selectedProviders) {
                    if (selected == 'Other detected providers') {
                      final knownProviders = ['meralco', 'manila water', 'pldt home', 'home credit', 'tala', 'converge', 'easytrip rfid'];
                      bool matchesKnown = false;
                      for (final known in knownProviders) {
                        if (sp.contains(known)) {
                          matchesKnown = true;
                          break;
                        }
                      }
                      if (!matchesKnown) {
                        providerMatch = true;
                        break;
                      }
                    } else if (sp.contains(selected.toLowerCase())) {
                      providerMatch = true;
                      break;
                    }
                  }
                  if (!providerMatch) return false;
                }

                return true;
              }).toList(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: widget.brandColor),
                );
              }
              final allRecords = snapshot.data ?? [];
              if (allRecords.isEmpty) {
                return _EmptyState(brandColor: widget.brandColor);
              }

              final totalPages = (allRecords.length / _itemsPerPage).ceil();
              final displayPage = _currentPage.clamp(1, totalPages == 0 ? 1 : totalPages);

              final startIndex = (displayPage - 1) * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage < allRecords.length) 
                                ? startIndex + _itemsPerPage 
                                : allRecords.length;
              final records = allRecords.sublist(startIndex, endIndex);

              final listChildren = <Widget>[];
              
              for (int i = 0; i < records.length; i++) {
                final record = records[i];
                final bool isFirst = i == 0;
                bool showDateSeparator = isFirst;

                if (!isFirst) {
                  final prevRecord = records[i - 1];
                  final currentDay = DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day);
                  final prevDay = DateTime(prevRecord.timestamp.year, prevRecord.timestamp.month, prevRecord.timestamp.day);
                  if (currentDay != prevDay) {
                    showDateSeparator = true;
                  }
                }

                if (showDateSeparator) {
                  listChildren.add(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isFirst) const SizedBox(height: 12),
                        _DateSeparator(date: record.timestamp),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                } else if (i > 0) {
                  listChildren.add(const SizedBox(height: 10)); // Card separator
                }

                listChildren.add(_TransactionCard(record: record));
              }
              
              if (totalPages > 1) {
                listChildren.add(const SizedBox(height: 28));
                listChildren.add(
                  _PaginationControls(
                    currentPage: displayPage,
                    totalPages: totalPages,
                    brandColor: widget.brandColor,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                  )
                );
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 180),
                children: listChildren,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PaginationControls
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color brandColor;
  final ValueChanged<int> onPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.brandColor,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

      if (start > 2) {
        pageItems.add('...');
      }

      for (int i = start; i <= end; i++) {
        pageItems.add(i);
      }

      if (end < totalPages - 1) {
        pageItems.add('...');
      }

      pageItems.add(totalPages);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: currentPage > 1 ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white30 : Colors.black26),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          
          // Page numbers
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
                color: isSelected ? brandColor : Colors.transparent,
                shape: CircleBorder(
                  side: BorderSide(
                    color: isSelected 
                        ? brandColor 
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (!isSelected) onPageChanged(pageNum);
                  },
                  splashColor: isSelected ? Colors.black26 : (isDark ? Colors.white30 : Colors.black12),
                  highlightColor: isSelected ? Colors.black12 : (isDark ? Colors.white12 : Colors.black12),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: isSelected 
                            ? Colors.white 
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      child: Text(pageNum.toString()),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: currentPage < totalPages ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white30 : Colors.black26),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddActionSheet — compact bottom sheet shown when the FAB is tapped
// ─────────────────────────────────────────────────────────────────────────────

class _AddActionSheet extends StatelessWidget {
  final Platform platform;
  final Color activeColor;
  final bool allowUpload;
  final VoidCallback onUpload;
  final VoidCallback onPaste;
  final VoidCallback onManual;

  const _AddActionSheet({
    required this.platform,
    required this.activeColor,
    required this.allowUpload,
    required this.onUpload,
    required this.onPaste,
    required this.onManual,
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

            if (allowUpload)
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
              subtitle: 'Paste a ${platform == Platform.gcash ? 'GCash' : 'Maya Business'} notification message',
              color: activeColor,
              onTap: onPaste,
            ),
            _SheetOption(
              icon: Icons.keyboard_rounded,
              title: 'Manual Input',
              subtitle: 'Manually type in the transaction details',
              color: activeColor,
              onTap: onManual,
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
// _DateSeparator
// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Format date like "May 27, 2026"
    final dateStr = DateFormat.yMMMMd().format(date);

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white30 : Colors.black87,
            thickness: 1.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Text(
            dateStr,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white30 : Colors.black87,
            thickness: 1.5,
          ),
        ),
      ],
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
  final _db = IsarService();

  static const _platformColors = {
    Platform.gcash: AppColors.gcash,
    Platform.maya: AppColors.maya,
    Platform.grabpay: Color(0xFF00B14F),
    Platform.shopeepay: Color(0xFFEE4D2D),
    Platform.other: Color(0xFF888888),
  };


  static const _typeIcons = {
    TransactionType.sent: Icons.arrow_upward_rounded,
    TransactionType.received: Icons.arrow_downward_rounded,
    TransactionType.cashIn: Icons.add_card_rounded,
    TransactionType.cashOut: Icons.money_off_rounded,
    TransactionType.payment: Icons.receipt_rounded,
  };

  // Icon foreground colors per transaction type
  static const _typeIconColors = {
    TransactionType.sent:     Color(0xFF1976D2), // blue — money going out
    TransactionType.received: Color(0xFFD32F2F), // red — money coming in
    TransactionType.cashIn:   Color(0xFF0288D1), // light blue
    TransactionType.cashOut:  Color(0xFFF57C00), // orange
    TransactionType.payment:  Color(0xFF6A1B9A), // purple
  };

  Future<void> _toggleSettled() async {
    try {
      await _db.toggleSettled(widget.record.id);
      // The StreamBuilder will automatically rebuild the list, so we don't need manual setState
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update transaction state.');
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

    final cardBgColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    // "Pending" amber border only applies to unsettled RECEIVED transactions
    final isReceived = widget.record.transactionType == TransactionType.received;
    final isPendingReceived = isReceived && !widget.record.isSettled;

    final cardBorder = isPendingReceived
        ? Border.all(color: Colors.amber.shade500.withValues(alpha: 0.6), width: 1.5)
        : (isDark ? Border.all(color: color.withValues(alpha: 0.18), width: 1) : null);

    // Per-type icon color (overrides platform color for the icon)
    final iconColor = _typeIconColors[widget.record.transactionType] ?? color;

    return Dismissible(
      key: ValueKey(widget.record.id),
      direction: isReceived ? DismissDirection.horizontal : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left → Delete
          final messenger = ScaffoldMessenger.of(context);
          final confirmed = await AppDialog.showDeleteConfirmation(
            context,
            title: 'Delete Transaction?',
            content: 'Are you sure you want to permanently delete this transaction record? This cannot be undone.',
          );
          if (confirmed == true) {
            // Capture a deep copy before deletion to allow exact restoration
            final recordCopy = TransactionRecord()
              ..id = widget.record.id
              ..platform = widget.record.platform
              ..transactionType = widget.record.transactionType
              ..amount = widget.record.amount
              ..referenceNumber = widget.record.referenceNumber
              ..timestamp = widget.record.timestamp
              ..senderName = widget.record.senderName
              ..senderNumber = widget.record.senderNumber
              ..accountNumber = widget.record.accountNumber
              ..remainingBalance = widget.record.remainingBalance
              ..recordedAt = widget.record.recordedAt
              ..notes = widget.record.notes
              ..serviceProvider = widget.record.serviceProvider
              ..fee = widget.record.fee
              ..isSettled = widget.record.isSettled;

            await _db.deleteTransaction(widget.record.id);

            AppToast.undoDelete(
              messenger,
              onUndo: () async {
                await _db.saveTransaction(recordCopy);
              },
            );
            return true;
          }
          return false;
        } else if (direction == DismissDirection.startToEnd && isReceived) {
          // Swipe Right → Settle (only for received)
          await _toggleSettled();
          return false; // Bounce back
        }
        return false;
      },
      background: isReceived ? Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: widget.record.isSettled ? Colors.amber.shade600 : const Color(0xFF00B14F),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            Icon(
              widget.record.isSettled ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              widget.record.isSettled ? 'Mark Pending' : 'Settle',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ) : const SizedBox.shrink(),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.delete_forever_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _showDetailsSheet(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(18),
              border: cardBorder,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _typeIcons[widget.record.transactionType] ?? Icons.swap_horiz_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.record.senderName ?? 'Unknown Recipient',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.record.serviceProvider != null && widget.record.serviceProvider!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.record.serviceProvider!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: widget.record.isLoad
                                  ? const Color(0xFFD32F2F) // Red for Load
                                  : const Color(0xFF1976D2), // Blue for Pay Bills
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          FormatUtils.formatPhone(widget.record.senderNumber).isEmpty
                              ? (widget.record.senderNumber ?? 'No Contact Number')
                              : FormatUtils.formatPhone(widget.record.senderNumber),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currency.format(widget.record.amount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: widget.record.transactionType == TransactionType.received
                                  ? const Color(0xFF2E7D32)
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (widget.record.fee != null && widget.record.fee! > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade400.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+₱${widget.record.fee!.toStringAsFixed(widget.record.fee! % 1 == 0 ? 0 : 2)}',
                                textScaler: TextScaler.noScaling,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.purple.shade400,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('MMM d, yyyy • hh:mm a').format(widget.record.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

                // Sleek Top-Right Corner Badge
                if (isReceived && widget.record.isSettled)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B14F),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(18), // Match card border radius
                          bottomLeft: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(color: Color(0x3300B14F), blurRadius: 4, offset: Offset(-1, 1)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SETTLED',
                            textScaler: TextScaler.noScaling,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            ),

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
  late final TextEditingController _accountNumberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _serviceProviderController;
  late final TextEditingController _amountController;
  late final TextEditingController _feeController;
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
    // Format for display: account numbers and reference numbers use groups-of-4
    // for Maya; phone numbers use XXXX XXX XXXX for both platforms.
    _accountNumberController = TextEditingController(
      text: r.platform == Platform.maya
          ? FormatUtils.formatGroups4(r.accountNumber)
          : (r.accountNumber ?? ''),
    );
    _phoneController = TextEditingController(
      text: FormatUtils.formatPhone(r.senderNumber),
    );
    _serviceProviderController = TextEditingController(text: r.serviceProvider ?? '');
    _amountController = TextEditingController(text: r.amount.toStringAsFixed(2));
    _feeController = TextEditingController(
      text: r.fee?.toStringAsFixed(2) ?? '',
    );
    
    _dateController = TextEditingController(
      text: DateFormat('MMM d, yyyy').format(r.timestamp),
    );
    _timeController = TextEditingController(
      text: DateFormat('hh:mm a', 'en_US').format(r.timestamp),
    );
    _refController = TextEditingController(
      text: r.platform == Platform.maya
          ? FormatUtils.formatGroups4(r.referenceNumber)
          : r.referenceNumber,
    );
    _balanceController = TextEditingController(
      text: r.remainingBalance != null ? r.remainingBalance!.toStringAsFixed(2) : '',
    );
    _transactionType = r.transactionType;

    _amountController.addListener(_onAmountChanged);
    _feeController.addListener(_onFeeChanged);
    _serviceProviderController.addListener(_onServiceProviderChanged);
  }

  void _onFeeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _feeController.removeListener(_onFeeChanged);
    _serviceProviderController.removeListener(_onServiceProviderChanged);
    _nameController.dispose();
    _accountNumberController.dispose();
    _phoneController.dispose();
    _serviceProviderController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _refController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (widget.record.platform == Platform.maya) return; // Maya fees don't depend on amount

    final amt = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
    _db.calculateFeeForAmount(amt).then((fee) {
      if (mounted) {
        setState(() {
          _feeController.text = fee?.toStringAsFixed(2) ?? '0.00';
        });
      }
    });
  }

  void _onServiceProviderChanged() {
    if (widget.record.platform != Platform.maya) return;
    
    _db.calculateMayaFee(
      serviceProvider: _serviceProviderController.text.trim(),
    ).then((fee) {
      if (mounted && fee != null && fee > 0) {
        setState(() {
          _feeController.text = fee.toStringAsFixed(2);
        });
      }
    });
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
      final parsedDate = DateFormat('hh:mm a', 'en_US').parse(_timeController.text.trim());
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
        _timeController.text = DateFormat('hh:mm a', 'en_US').format(dt);
      });
    }
  }

  Future<void> _onSave() async {
    final amtVal = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
    final balVal = double.tryParse(_balanceController.text.replaceAll(',', '').trim());
    DateTime dtVal;
    try {
      final dateStr = _dateController.text.trim();
      final timeStr = _timeController.text.trim();
      dtVal = DateFormat('MMM d, yyyy hh:mm a', 'en_US').parse('$dateStr $timeStr');
    } catch (_) {
      dtVal = widget.record.timestamp;
    }

    final newName    = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    // Strip display-formatting spaces before persisting
    final newAccount = _accountNumberController.text.trim().isEmpty
        ? null
        : FormatUtils.stripSpaces(_accountNumberController.text.trim());
    final newPhone   = _phoneController.text.trim().isEmpty
        ? null
        : FormatUtils.stripPhone(_phoneController.text.trim());
    final newProvider = _serviceProviderController.text.trim().isEmpty ? null : _serviceProviderController.text.trim();
    final newRef     = _refController.text.trim().isEmpty
        ? 'UNKNOWN-${DateTime.now().millisecondsSinceEpoch}'
        : FormatUtils.stripSpaces(_refController.text.trim());

    final feeVal = double.tryParse(_feeController.text.replaceAll(',', '').trim());

    final isNameChanged = newName != widget.record.senderName;
    final isAccountChanged = newAccount != widget.record.accountNumber;
    final isPhoneChanged = newPhone != widget.record.senderNumber;
    final isProviderChanged = newProvider != widget.record.serviceProvider;
    final isAmountChanged = amtVal != widget.record.amount;
    final isDateChanged = dtVal != widget.record.timestamp;
    final isRefChanged = newRef != widget.record.referenceNumber;
    final isBalanceChanged = balVal != widget.record.remainingBalance;
    final isTypeChanged = _transactionType != widget.record.transactionType;
    final isFeeChanged = feeVal != widget.record.fee;

    final hasChanges = isNameChanged ||
        isAccountChanged ||
        isPhoneChanged ||
        isProviderChanged ||
        isAmountChanged ||
        isDateChanged ||
        isRefChanged ||
        isBalanceChanged ||
        isTypeChanged ||
        isFeeChanged;

    if (!hasChanges) {
      if (!mounted) return;
      AppToast.warning(context, 'No changes have been made');
      Navigator.of(context).pop();
      return;
    }

    final updated = widget.record
      ..senderName = newName
      ..accountNumber = newAccount
      ..senderNumber = newPhone
      ..serviceProvider = newProvider
      ..amount = amtVal
      ..timestamp = dtVal
      ..referenceNumber = newRef
      ..remainingBalance = balVal
      ..transactionType = _transactionType
      ..fee = feeVal;

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
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Edit Transaction Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              // Sent vs Received Segmented Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TransactionTypeSelector(
                  platform: widget.record.platform,
                  selectedType: _transactionType,
                  onChanged: (type) {
                    setState(() => _transactionType = type);
                  },
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _EditField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      activeColor: color,
                    ),
                    if (widget.record.platform == Platform.maya && _transactionType != TransactionType.sent && _transactionType != TransactionType.received) ...[
                      _EditField(
                        label: 'Account Number',
                        controller: _accountNumberController,
                        icon: Icons.account_balance_wallet_rounded,
                        keyboardType: TextInputType.text,
                        inputFormatters: [GroupOf4Formatter()],
                        activeColor: color,
                      ),
                    ],
                    _EditField(
                      label: 'Contact Number',
                      controller: _phoneController,
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneNumberFormatter()],
                      activeColor: color,
                    ),
                    if (widget.record.platform == Platform.maya && _transactionType != TransactionType.sent && _transactionType != TransactionType.received) ...[
                      _EditField(
                        label: 'Service Provider',
                        controller: _serviceProviderController,
                        icon: Icons.business_rounded,
                        activeColor: color,
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _EditField(
                            label: 'Amount',
                            controller: _amountController,
                            prefixText: '₱',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            activeColor: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _EditField(
                            label: 'Service Fee',
                            controller: _feeController,
                            prefixText: '₱',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            activeColor: color,
                            suffixIcon: _feeController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _feeController.clear();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ],
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
                      keyboardType: TextInputType.text,
                      inputFormatters: widget.record.platform == Platform.maya
                          ? [GroupOf4Formatter()]
                          : null,
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
  final Platform platform;
  final Future<void> Function(String text) onSubmit;
  const _PasteTextSheet({required this.platform, required this.onSubmit});

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

  String _getPlatformName(Platform platform) {
    switch (platform) {
      case Platform.gcash: return 'GCash';
      case Platform.maya: return 'Maya Business';
      case Platform.grabpay: return 'GrabPay';
      case Platform.shopeepay: return 'ShopeePay';
      default: return 'Wallet';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDirty => _controller.text.trim().isNotEmpty;

  Future<void> _onCancel() async {
    if (_isDirty) {
      final confirm = await AppDialog.showThemedDialog(
        context,
        title: 'Discard Changes?',
        content: 'Are you sure you want to cancel? All entered data will be lost.',
        confirmLabel: 'Discard',
        cancelLabel: 'Cancel',
        accentColor: const Color(0xFFC62828),
        icon: Icons.warning_amber_rounded,
      );
      if (confirm == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onCancel();
      },
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _onCancel,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Paste ${_getPlatformName(widget.platform)} Text',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance spacing
                  ],
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
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.of(context).padding.bottom,
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
    ),
  );
}
}

class _ConfirmEntrySheet extends StatefulWidget {
  final ParsedReceipt receipt;
  final bool isManual;

  const _ConfirmEntrySheet({
    required this.receipt,
    this.isManual = false,
  });

  @override
  State<_ConfirmEntrySheet> createState() => _ConfirmEntrySheetState();
}

class _ConfirmEntrySheetState extends State<_ConfirmEntrySheet> {
  final _db = IsarService();
  late final TextEditingController _nameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _serviceProviderController;
  late final TextEditingController _amountController;
  late final TextEditingController _feeController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _refController;
  late final TextEditingController _balanceController;
  late TransactionType _selectedType;

  // Snapshots for dirty state detection
  late String _initialName;
  late String _initialAccount;
  late String _initialPhone;
  late String _initialProvider;
  late String _initialAmount;
  late String _initialFee;
  late String _initialDate;
  late String _initialTime;
  late String _initialRef;
  late String _initialBalance;
  late TransactionType _initialType;

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
    _selectedType = r.transactionType;
    _nameController = TextEditingController(text: r.personName ?? '');
    // Format for display: groups-of-4 for Maya account/reference numbers;
    // XXXX XXX XXXX for phone numbers on both platforms.
    _accountNumberController = TextEditingController(
      text: r.platform == Platform.maya
          ? FormatUtils.formatGroups4(r.accountNumber)
          : (r.accountNumber ?? ''),
    );
    _phoneController = TextEditingController(
      text: FormatUtils.formatPhone(r.phoneNumber),
    );
    _serviceProviderController = TextEditingController(text: r.serviceProvider ?? '');
    _amountController = TextEditingController(
      text: r.amount?.toStringAsFixed(2) ?? '',
    );
    _feeController = TextEditingController(
      text: r.fee?.toStringAsFixed(2) ?? '',
    );
    
    final initialDate = r.transactionDate ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormat('MMM d, yyyy').format(initialDate),
    );
    _timeController = TextEditingController(
      text: DateFormat('hh:mm a', 'en_US').format(initialDate),
    );
    
    _refController = TextEditingController(
      text: r.platform == Platform.maya
          ? FormatUtils.formatGroups4(r.referenceNumber)
          : (r.referenceNumber ?? ''),
    );
    _balanceController = TextEditingController(
      text: r.remainingBalance != null
          ? r.remainingBalance!.toStringAsFixed(2)
          : '',
    );

    _amountController.addListener(_onAmountChanged);
    _feeController.addListener(_onFeeChanged);
    _serviceProviderController.addListener(_onServiceProviderChanged);
    
    // Trigger initial calculation if fee is not populated
    if (r.fee == null) {
      if (r.platform == Platform.maya) {
        _onServiceProviderChanged();
      } else if (r.amount != null) {
        _onAmountChanged();
      }
    }

    _initialType = _selectedType;
    _initialName = _nameController.text;
    _initialAccount = _accountNumberController.text;
    _initialPhone = _phoneController.text;
    _initialProvider = _serviceProviderController.text;
    _initialAmount = _amountController.text;
    _initialFee = _feeController.text;
    _initialDate = _dateController.text;
    _initialTime = _timeController.text;
    _initialRef = _refController.text;
    _initialBalance = _balanceController.text;
  }

  bool get _isDirty {
    return _selectedType != _initialType ||
           _nameController.text != _initialName ||
           _accountNumberController.text != _initialAccount ||
           _phoneController.text != _initialPhone ||
           _serviceProviderController.text != _initialProvider ||
           _amountController.text != _initialAmount ||
           _feeController.text != _initialFee ||
           _dateController.text != _initialDate ||
           _timeController.text != _initialTime ||
           _refController.text != _initialRef ||
           _balanceController.text != _initialBalance;
  }

  Future<void> _onCancel() async {
    if (_isDirty) {
      final confirm = await AppDialog.showThemedDialog(
        context,
        title: 'Discard Changes?',
        content: 'Are you sure you want to cancel? All entered data will be lost.',
        confirmLabel: 'Discard',
        cancelLabel: 'Cancel',
        accentColor: const Color(0xFFC62828),
        icon: Icons.warning_amber_rounded,
      );
      if (confirm == true && mounted) {
        Navigator.of(context).pop(null);
      }
    } else {
      Navigator.of(context).pop(null);
    }
  }

  void _onFeeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _feeController.removeListener(_onFeeChanged);
    _serviceProviderController.removeListener(_onServiceProviderChanged);
    _nameController.dispose();
    _accountNumberController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _refController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (widget.receipt.platform == Platform.maya) return; // Maya fees don't depend on amount

    final amt = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
    _db.calculateFeeForAmount(amt).then((fee) {
      if (mounted) {
        setState(() {
          _feeController.text = fee?.toStringAsFixed(2) ?? '0.00';
        });
      }
    });
  }

  void _onServiceProviderChanged() {
    if (widget.receipt.platform != Platform.maya) return;
    
    _db.calculateMayaFee(
      serviceProvider: _serviceProviderController.text.trim(),
      rawText: widget.receipt.rawText,
    ).then((fee) {
      if (mounted && fee != null && fee > 0) {
        setState(() {
          _feeController.text = fee.toStringAsFixed(2);
        });
      }
    });
  }

  Future<void> _selectDate() async {
    DateTime initial = widget.receipt.transactionDate ?? DateTime.now();
    try {
      initial = DateFormat('MMM d, yyyy').parse(_dateController.text.trim());
    } catch (_) {}

    final color = _platformColors[widget.receipt.platform] ?? const Color(0xFF888888);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: color,
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
    final initialDate = widget.receipt.transactionDate ?? DateTime.now();
    TimeOfDay initial = TimeOfDay.fromDateTime(initialDate);
    try {
      final parsedDate = DateFormat('hh:mm a', 'en_US').parse(_timeController.text.trim());
      initial = TimeOfDay.fromDateTime(parsedDate);
    } catch (_) {}

    final color = _platformColors[widget.receipt.platform] ?? const Color(0xFF888888);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: color,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final parsedDate = DateTime(2020, 1, 1, picked.hour, picked.minute);
        _timeController.text = DateFormat('hh:mm a', 'en_US').format(parsedDate);
      });
    }
  }

  Future<void> _onSave() async {
    final amtVal = double.tryParse(_amountController.text.replaceAll(',', '').trim());
    final balVal = double.tryParse(_balanceController.text.replaceAll(',', '').trim());
    DateTime? dtVal;
    try {
      final datePart = DateFormat('MMM d, yyyy').parse(_dateController.text.trim());
      final parsedTime = DateFormat('hh:mm a', 'en_US').parse(_timeController.text.trim());
      dtVal = DateTime(datePart.year, datePart.month, datePart.day, parsedTime.hour, parsedTime.minute);
    } catch (_) {
      dtVal = widget.receipt.transactionDate ?? DateTime.now();
    }

    final feeVal = double.tryParse(_feeController.text.replaceAll(',', '').trim());
    final edited = ParsedReceipt(
      rawText: widget.receipt.rawText,
      platform: widget.receipt.platform,
      transactionType: _selectedType,
      amount: amtVal,
      referenceNumber: _refController.text.trim().isEmpty
          ? null
          : FormatUtils.stripSpaces(_refController.text.trim()),
      personName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      accountNumber: _accountNumberController.text.trim().isEmpty
          ? null
          : FormatUtils.stripSpaces(_accountNumberController.text.trim()),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : FormatUtils.stripPhone(_phoneController.text.trim()),
      serviceProvider: _serviceProviderController.text.trim().isEmpty
          ? null
          : _serviceProviderController.text.trim(),
      transactionDate: dtVal,
      remainingBalance: balVal,
      fee: feeVal,
    );

    // ── Duplicate reference number guard ─────────────────────────────────
    final refNum = _refController.text.trim();
    final normalizedRef = refNum.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (!normalizedRef.startsWith('UNKNOWN') && normalizedRef.isNotEmpty) {
      final duplicate = await _db.findDuplicateReference(refNum);
      if (duplicate != null && mounted) {
        final color = _platformColors[widget.receipt.platform] ?? const Color(0xFF888888);
        await AppDialog.showDuplicateReferenceAlert(
          context,
          refNumber: refNum,
          accentColor: color,
        );
        // Always block the save — user must correct the reference number.
        return;
      }
    }

    if (!mounted) return;
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
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                widget.isManual ? 'Manual Input' : 'Verify & Correct Transaction',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isManual ? 'Enter transaction details manually below.' : 'OCR extracted fields. Correct any errors below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Type',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _TransactionTypeSelector(
                            platform: widget.receipt.platform,
                            selectedType: _selectedType,
                            onChanged: (type) {
                              setState(() => _selectedType = type);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EditField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      activeColor: color,
                    ),
                    if (widget.receipt.platform == Platform.maya && _selectedType != TransactionType.sent && _selectedType != TransactionType.received) ...[
                      _EditField(
                        label: 'Account Number',
                        controller: _accountNumberController,
                        icon: Icons.account_balance_wallet_rounded,
                        keyboardType: TextInputType.text,
                        inputFormatters: [GroupOf4Formatter()],
                        activeColor: color,
                      ),
                    ],
                    _EditField(
                      label: 'Contact Number',
                      controller: _phoneController,
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneNumberFormatter()],
                      activeColor: color,
                    ),
                    if (widget.receipt.platform == Platform.maya && _selectedType != TransactionType.sent && _selectedType != TransactionType.received) ...[
                      _EditField(
                        label: 'Service Provider',
                        controller: _serviceProviderController,
                        icon: Icons.business_rounded,
                        activeColor: color,
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _EditField(
                            label: 'Amount',
                            controller: _amountController,
                            prefixText: '₱',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            activeColor: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _EditField(
                            label: 'Service Fee',
                            controller: _feeController,
                            prefixText: '₱',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            activeColor: color,
                            suffixIcon: _feeController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _feeController.clear();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ],
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
                            icon: Icons.access_time_filled_rounded,
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
                      keyboardType: TextInputType.text,
                      inputFormatters: widget.receipt.platform == Platform.maya
                          ? [GroupOf4Formatter()]
                          : null,
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
                          onPressed: _onCancel,
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
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool readOnly;

  const _EditField({
    required this.label,
    required this.controller,
    required this.activeColor,
    this.icon,
    this.prefixText,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
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
            inputFormatters: inputFormatters,
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
              suffixIcon: suffixIcon,
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

class _TransactionTypeSelector extends StatelessWidget {
  final Platform platform;
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const _TransactionTypeSelector({
    required this.platform,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // If it's GCash, restrict to Sent/Received.
    final bool isGcash = platform == Platform.gcash;
    
    // Ensure selected type is within allowed types to prevent crash
    TransactionType validSelectedType = selectedType;
    if (isGcash && selectedType != TransactionType.sent && selectedType != TransactionType.received) {
      validSelectedType = TransactionType.sent;
    } else if (!isGcash && selectedType != TransactionType.sent && selectedType != TransactionType.received && selectedType != TransactionType.payment) {
      validSelectedType = TransactionType.payment;
    }

    final List<ButtonSegment<TransactionType>> segments = isGcash
        ? const [
            ButtonSegment<TransactionType>(
              value: TransactionType.sent,
              label: Text('Sent'),
              icon: Icon(Icons.arrow_upward_rounded, size: 16),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.received,
              label: Text('Received'),
              icon: Icon(Icons.arrow_downward_rounded, size: 16),
            ),
          ]
        : const [
            ButtonSegment<TransactionType>(
              value: TransactionType.sent,
              label: Text('Sent'),
              icon: Icon(Icons.arrow_upward_rounded, size: 16),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.received,
              label: Text('Received'),
              icon: Icon(Icons.arrow_downward_rounded, size: 16),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.payment,
              label: Text('Bills / Load'),
              icon: Icon(Icons.payment_rounded, size: 16),
            ),
          ];

    Color getSelectedColor(TransactionType type) {
      if (type == TransactionType.received || type == TransactionType.cashIn) {
        return const Color(0xFFD32F2F);
      } else if (type == TransactionType.payment) {
        return const Color(0xFF6A1B9A);
      }
      return const Color(0xFF1976D2);
    }

    final activeColor = getSelectedColor(validSelectedType);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TransactionType>(
        segments: segments,
        selected: {validSelectedType},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: activeColor.withValues(alpha: 0.14),
          selectedForegroundColor: activeColor,
          side: BorderSide(
            color: activeColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchFilterModal
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterModal extends StatefulWidget {
  final Platform platform;
  final String initialQuery;
  final DateTimeRange? initialDate;
  final bool initialSent;
  final bool initialReceived;
  final bool initialBills;
  final bool initialLoad;
  final Set<String> initialProviders;
  final Function(String, DateTimeRange?, bool, bool, bool, bool, Set<String>) onApply;

  const _SearchFilterModal({
    required this.platform,
    required this.initialQuery,
    required this.initialDate,
    required this.initialSent,
    required this.initialReceived,
    required this.initialBills,
    required this.initialLoad,
    required this.initialProviders,
    required this.onApply,
  });

  @override
  State<_SearchFilterModal> createState() => _SearchFilterModalState();
}

class _SearchFilterModalState extends State<_SearchFilterModal> {
  late TextEditingController _searchController;
  DateTimeRange? _dateFilter;
  late bool _showSent;
  late bool _showReceived;
  late bool _showBills;
  late bool _showLoad;
  late Set<String> _selectedProviders;

  static const _mayaProviders = [
    'Meralco',
    'Manila Water',
    'PLDT Home',
    'Home Credit',
    'Tala',
    'Converge',
    'Easytrip RFID',
    'Other detected providers',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _dateFilter = widget.initialDate;
    _showSent = widget.initialSent;
    _showReceived = widget.initialReceived;
    _showBills = widget.initialBills;
    _showLoad = widget.initialLoad;
    _selectedProviders = Set.from(widget.initialProviders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      _searchController.text.trim(),
      _dateFilter,
      _showSent,
      _showReceived,
      _showBills,
      _showLoad,
      _selectedProviders,
    );
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _searchController.clear();
      _dateFilter = null;
      _showSent = true;
      _showReceived = true;
      _showBills = true;
      _showLoad = true;
      _selectedProviders.clear();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateFilter,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: widget.platform == Platform.maya ? AppColors.maya : AppColors.gcash,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateFilter = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brandColor = widget.platform == Platform.maya ? AppColors.maya : AppColors.gcash;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 
        16, 
        24, 
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search & Filter',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search names, ref numbers, contact numbers...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: brandColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Date Range
            Text('Date Range', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20, color: brandColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dateFilter == null
                            ? 'Any Date'
                            : '${DateFormat('MMM d, yyyy').format(_dateFilter!.start)} - ${DateFormat('MMM d, yyyy').format(_dateFilter!.end)}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (_dateFilter != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _dateFilter = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Types
            Text('Transaction Types', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('Sent', _showSent, (v) => setState(() => _showSent = v), brandColor),
                _buildFilterChip('Received', _showReceived, (v) => setState(() => _showReceived = v), brandColor),
                if (widget.platform == Platform.maya) ...[
                  _buildFilterChip('Bills', _showBills, (v) => setState(() => _showBills = v), brandColor),
                  _buildFilterChip('Load', _showLoad, (v) => setState(() => _showLoad = v), brandColor),
                ]
              ],
            ),
            
            if (widget.platform == Platform.maya) ...[
              const SizedBox(height: 24),
              Text('Service Providers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _mayaProviders.map((p) {
                  final isSelected = _selectedProviders.contains(p);
                  return _buildFilterChip(p, isSelected, (v) {
                    setState(() {
                      if (v) {
                        _selectedProviders.add(p);
                      } else {
                        _selectedProviders.remove(p);
                      }
                    });
                  }, brandColor);
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, ValueChanged<bool> onSelected, Color activeColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      checkmarkColor: Colors.white,
      selectedColor: activeColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? activeColor : (isDark ? Colors.white24 : Colors.black12),
        ),
      ),
    );
  }
}
