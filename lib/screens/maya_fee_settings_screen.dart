import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class MayaFeeSettingsScreen extends StatefulWidget {
  const MayaFeeSettingsScreen({super.key});

  @override
  State<MayaFeeSettingsScreen> createState() => _MayaFeeSettingsScreenState();
}

class _MayaFeeSettingsScreenState extends State<MayaFeeSettingsScreen> {
  Map<String, double> _feesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? mayaFeesJson = prefs.getString('maya_service_fees');
    
    if (mayaFeesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(mayaFeesJson);
      _feesMap = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } else {
      _feesMap = {
        'Manila Water': 15.0,
        'Meralco': 15.0,
        'PLDT Home': 15.0,
        'Home Credit': 25.0,
        'Converge': 25.0,
        'TALA': 25.0,
        'RFID': 25.0,
        'Load': 5.0,
      };
      await prefs.setString('maya_service_fees', jsonEncode(_feesMap));
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveFeesMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maya_service_fees', jsonEncode(_feesMap));
    setState(() {}); // refresh UI
  }

  void _showAddEditDialog([String? existingKey]) {
    final isEditing = existingKey != null;
    final isLoadFee = existingKey == 'Load';
    
    final providerController = TextEditingController(text: isEditing ? existingKey : '');
    final feeController = TextEditingController(
      text: isEditing ? _feesMap[existingKey!]?.toStringAsFixed(0) : '',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isEditing ? 'Edit Maya Fee' : 'Add Maya Fee',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogEditField(
                    label: 'Service Provider / Category',
                    controller: providerController,
                    keyboardType: TextInputType.text,
                    readOnly: isLoadFee,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (!isEditing && _feesMap.containsKey(val.trim())) {
                        return 'Already exists';
                      }
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
            if (isEditing && !isLoadFee)
              TextButton(
                onPressed: () async {
                  _feesMap.remove(existingKey);
                  await _saveFeesMap();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maya,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final provider = providerController.text.trim();
                  final feeAmt = double.parse(feeController.text);

                  if (isEditing && existingKey != provider) {
                    _feesMap.remove(existingKey);
                  }
                  _feesMap[provider] = feeAmt;

                  await _saveFeesMap();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Maya Service Fees',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.maya,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fee', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.maya))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.maya.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.maya.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.maya),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These fees will automatically apply when parsing Maya Business transactions based on the Service Provider (e.g. Meralco) or Transaction Type (e.g. Load).',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
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
                      itemCount: _feesMap.length,
                      separatorBuilder: (context, index) => Divider(
                        color: theme.colorScheme.outline.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final key = _feesMap.keys.elementAt(index);
                        final fee = _feesMap[key]!;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          onTap: () => _showAddEditDialog(key),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.maya.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              key == 'Load' ? Icons.phone_android_rounded : Icons.receipt_long_rounded,
                              color: AppColors.maya,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₱${fee.toStringAsFixed(0)}',
                                textScaler: TextScaler.noScaling,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.maya,
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
  final bool readOnly;

  const _DialogEditField({
    required this.label,
    required this.controller,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
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
            readOnly: readOnly,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: readOnly ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              prefixIcon: prefixText != null
                  ? Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        prefixText!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.maya,
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
                borderSide: const BorderSide(color: AppColors.maya, width: 1.8),
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
