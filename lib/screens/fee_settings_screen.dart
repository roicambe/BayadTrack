import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/isar_service.dart';
import '../database/fee_model.dart';
import '../theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeeSettingsScreen extends StatefulWidget {
  const FeeSettingsScreen({super.key});

  @override
  State<FeeSettingsScreen> createState() => _FeeSettingsScreenState();
}

class _FeeSettingsScreenState extends State<FeeSettingsScreen> {
  final _db = IsarService();
  List<FeeRange> _ranges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRanges();
  }

  Future<void> _loadRanges() async {
    setState(() => _isLoading = true);
    final ranges = await _db.getAllFeeRanges();
    setState(() {
      _ranges = ranges;
      _isLoading = false;
    });
  }

  void _showAddEditDialog([FeeRange? range]) {
    final isEditing = range != null;
    final minController = TextEditingController(
      text: isEditing ? range.minAmount.toStringAsFixed(0) : '',
    );
    final maxController = TextEditingController(
      text: isEditing ? range.maxAmount.toStringAsFixed(0) : '',
    );
    final feeController = TextEditingController(
      text: isEditing ? range.fee.toStringAsFixed(0) : '',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isEditing ? 'Edit Fee Range' : 'Add Fee Range',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogEditField(
                    label: 'Min Amount',
                    controller: minController,
                    prefixText: '₱',
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  _DialogEditField(
                    label: 'Max Amount',
                    controller: maxController,
                    prefixText: '₱',
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Invalid amount';
                      final minNum = double.tryParse(minController.text) ?? 0;
                      if (num <= minNum) return 'Must be greater than Min';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  _DialogEditField(
                    label: 'Service Fee',
                    controller: feeController,
                    prefixText: '₱',
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Invalid fee';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            if (isEditing)
              TextButton(
                onPressed: () async {
                  await _db.deleteFeeRange(range.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  if (mounted) {
                    _loadRanges();
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final minAmt = double.parse(minController.text);
                  final maxAmt = double.parse(maxController.text);
                  final feeAmt = double.parse(feeController.text);

                  final newRange = range ?? FeeRange();
                  newRange.minAmount = minAmt;
                  newRange.maxAmount = maxAmt;
                  newRange.fee = feeAmt;

                  await _db.saveFeeRange(newRange);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  if (mounted) {
                    _loadRanges();
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GCash Service Fees',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.gcash,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Range', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ranges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_rows_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No fee ranges set up yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gcash.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gcash.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.gcash),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Service fees will be automatically applied to both Received and Sent transactions based on the amount.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _TransactionFeeSettingsSection(),
                      const SizedBox(height: 24),
                      // Table Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'CASH IN / CASH OUT',
                                textScaler: TextScaler.noScaling,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  letterSpacing: 1.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SERVICE FEE',
                              textScaler: TextScaler.noScaling,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Table Body Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ranges.length,
                          separatorBuilder: (context, index) => Divider(
                            color: theme.colorScheme.outline.withValues(alpha: 0.08),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final r = _ranges[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              onTap: () => _showAddEditDialog(r),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.gcash.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.payments_outlined,
                                  color: AppColors.gcash,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${currencyFormat.format(r.minAmount)} – ${currencyFormat.format(r.maxAmount)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currencyFormat.format(r.fee),
                                    textScaler: TextScaler.noScaling,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DialogEditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _DialogEditField({
    required this.label,
    required this.controller,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              prefixIcon: prefixText != null
                  ? Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        prefixText!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.gcash,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : null,
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
                borderSide: const BorderSide(color: AppColors.gcash, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionFeeSettingsSection extends StatefulWidget {
  const _TransactionFeeSettingsSection();

  @override
  State<_TransactionFeeSettingsSection> createState() => _TransactionFeeSettingsSectionState();
}

class _TransactionFeeSettingsSectionState extends State<_TransactionFeeSettingsSection> {
  late final TextEditingController _thresholdController;
  late final TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController();
    _rateController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getDouble('fee_max_threshold') ?? 15000.0;
    final rate = prefs.getDouble('fee_pro_rata_rate') ?? 10.0;
    
    _thresholdController.text = threshold.toStringAsFixed(0);
    _rateController.text = rate.toStringAsFixed(0);
  }

  Future<void> _saveSettings() async {
    final thresholdStr = _thresholdController.text.trim();
    final rateStr = _rateController.text.trim();
    
    final threshold = double.tryParse(thresholdStr) ?? 15000.0;
    final rate = double.tryParse(rateStr) ?? 10.0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fee_max_threshold', threshold);
    await prefs.setDouble('fee_pro_rata_rate', rate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gcash.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gcash,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Large Transaction Rules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'For transactions beyond the standard range, fees are automatically calculated pro-rata.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SettingsEditField(
                  label: 'Fee Starts At',
                  controller: _thresholdController,
                  prefixText: '₱',
                  onChanged: (_) => _saveSettings(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsEditField(
                  label: 'Fee Per ₱1,000',
                  controller: _rateController,
                  prefixText: '₱',
                  onChanged: (_) => _saveSettings(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsEditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String prefixText;
  final ValueChanged<String>? onChanged;

  const _SettingsEditField({
    required this.label,
    required this.controller,
    required this.prefixText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                prefixText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.gcash,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
              borderSide: const BorderSide(color: AppColors.gcash, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
