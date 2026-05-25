import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../database/transaction_model.dart';
import '../database/isar_service.dart';

enum ChartPeriod { week, month, year }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = IsarService();
  ChartPeriod _selectedPeriod = ChartPeriod.week;

  // Masking helper matching global patterns
  String _maskName(String name) {
    if (name.trim().isEmpty) return 'Unknown';
    final trimmed = name.trim();
    if (trimmed.length <= 2) return trimmed;
    final parts = trimmed.split(' ');
    return parts.map((part) {
      if (part.length <= 2) return part;
      return '${part[0]}${part[1]}••${part[part.length - 1]}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return SafeArea(
      child: StreamBuilder<List<TransactionRecord>>(
        stream: _db.listenToTransactions(),
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? [];

          // 1. Calculate Real-Time Platform Balances & Updated Dates
          double gcashBalance = 0.0;
          double mayaBalance = 0.0;
          DateTime? gcashLastUpdated;
          DateTime? mayaLastUpdated;

          // Find latest transaction with non-null remainingBalance for each platform
          final gcashBalTxn = transactions
              .where((t) => t.platform == Platform.gcash && t.remainingBalance != null)
              .toList();
          if (gcashBalTxn.isNotEmpty) {
            // sorted by timestamp desc by default in query, double check anyway
            gcashBalTxn.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            gcashBalance = gcashBalTxn.first.remainingBalance!;
          }

          final mayaBalTxn = transactions
              .where((t) => t.platform == Platform.maya && t.remainingBalance != null)
              .toList();
          if (mayaBalTxn.isNotEmpty) {
            mayaBalTxn.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            mayaBalance = mayaBalTxn.first.remainingBalance!;
          }

          // Find latest transaction time overall for each platform to display "Last Updated"
          final gcashAllTxn = transactions.where((t) => t.platform == Platform.gcash).toList();
          if (gcashAllTxn.isNotEmpty) {
            gcashAllTxn.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            gcashLastUpdated = gcashAllTxn.first.timestamp;
          }

          final mayaAllTxn = transactions.where((t) => t.platform == Platform.maya).toList();
          if (mayaAllTxn.isNotEmpty) {
            mayaAllTxn.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            mayaLastUpdated = mayaAllTxn.first.timestamp;
          }

          // 2. Generate Chart & Insights Data based on Selected Period
          final now = DateTime.now();
          DateTime periodStart;
          switch (_selectedPeriod) {
            case ChartPeriod.week:
              periodStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
              break;
            case ChartPeriod.month:
              periodStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
              break;
            case ChartPeriod.year:
              periodStart = DateTime(now.year, now.month, 1).subtract(const Duration(days: 365));
              break;
          }

          // Filter transactions for insights
          final periodTransactions = transactions
              .where((t) => t.timestamp.isAfter(periodStart) || t.timestamp.isAtSameMomentAs(periodStart))
              .toList();

          // Insights Calculation: Most Active Customer
          final customerCounts = <String, int>{};
          for (final t in periodTransactions) {
            final name = t.senderName?.trim() ?? '';
            if (name.isNotEmpty && name.toLowerCase() != 'unknown') {
              customerCounts[name] = (customerCounts[name] ?? 0) + 1;
            }
          }
          List<MapEntry<String, int>> topCustomers = [];
          if (customerCounts.isNotEmpty) {
            topCustomers = customerCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (topCustomers.length > 10) {
              topCustomers = topCustomers.sublist(0, 10);
            }
          }

          // Insights Calculation: Platform Split
          int gcashCount = periodTransactions.where((t) => t.platform == Platform.gcash).length;
          int mayaCount = periodTransactions.where((t) => t.platform == Platform.maya).length;
          int totalCount = gcashCount + mayaCount;
          double gcashPercent = totalCount > 0 ? (gcashCount / totalCount) : 0.5;
          double mayaPercent = totalCount > 0 ? (mayaCount / totalCount) : 0.5;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).padding.bottom + 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Summary',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(now),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── 1. Real-Time Balance Cards ─────────────────────────────────
                _SectionLabel("Real-Time Balances"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        platformName: 'GCash',
                        balance: gcashBalance,
                        lastUpdated: gcashLastUpdated,
                        brandColor: AppColors.gcash,
                        icon: Icons.account_balance_wallet_rounded,
                        currencyFormat: currencyFormat,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        platformName: 'Maya',
                        balance: mayaBalance,
                        lastUpdated: mayaLastUpdated,
                        brandColor: AppColors.maya,
                        icon: Icons.bolt_rounded,
                        currencyFormat: currencyFormat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── 2. Business Trends Line Chart ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: const _SectionLabel('Business Trends')),
                    const SizedBox(width: 8),
                    // Segmented Button Toggle Selector
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPeriodToggle(ChartPeriod.week, 'Week', theme),
                          _buildPeriodToggle(ChartPeriod.month, 'Month', theme),
                          _buildPeriodToggle(ChartPeriod.year, 'Year', theme),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TrendChartCard(
                  period: _selectedPeriod,
                  transactions: transactions,
                  now: now,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: 28),

                // ── 3. Business Insights ───────────────────────────────────────
                const _SectionLabel('Business Insights'),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _InsightItemCard(
                      title: 'Most Active Customers (Top 10)',
                      icon: Icons.people_alt_rounded,
                      iconColor: Colors.purple.shade400,
                      isDark: isDark,
                      theme: theme,
                      child: topCustomers.isEmpty
                          ? Text(
                              'No records yet',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Column(
                              children: topCustomers.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _maskName(e.key),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '${e.value} txns',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _InsightItemCard(
                      title: 'Platform Split',
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: Colors.orange.shade400,
                      isDark: isDark,
                      theme: theme,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.gcash, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('GCash ${(gcashPercent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gcash)),
                              const SizedBox(width: 16),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.maya, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('Maya ${(mayaPercent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.maya)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 140,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    color: AppColors.gcash,
                                    value: gcashPercent * 100,
                                    title: '',
                                    radius: 20,
                                  ),
                                  PieChartSectionData(
                                    color: AppColors.maya,
                                    value: mayaPercent * 100,
                                    title: '',
                                    radius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodToggle(ChartPeriod period, String text, ThemeData theme) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Sub-Widgets & Components
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: theme.colorScheme.primary.withValues(alpha: 0.8),
      ),
    );
  }
}

/// Large modern wallet balance card featuring automatic Low Balance Amber highlighting
class _BalanceCard extends StatelessWidget {
  final String platformName;
  final double balance;
  final DateTime? lastUpdated;
  final Color brandColor;
  final IconData icon;
  final NumberFormat currencyFormat;

  const _BalanceCard({
    required this.platformName,
    required this.balance,
    required this.lastUpdated,
    required this.brandColor,
    required this.icon,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check low balance threshold
    final isLowBalance = balance < 1000.0;
    final warningColor = Colors.amber.shade700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: isLowBalance
            ? Border.all(color: warningColor, width: 2.0)
            : (isDark
                ? Border.all(color: brandColor.withValues(alpha: 0.25), width: 1)
                : Border.all(color: Colors.grey.shade200, width: 1.2)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: isLowBalance
                      ? warningColor.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLowBalance
                      ? warningColor.withValues(alpha: 0.12)
                      : brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLowBalance ? Icons.warning_amber_rounded : icon,
                  color: isLowBalance ? warningColor : brandColor,
                  size: 20,
                ),
              ),
              if (isLowBalance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LOW',
                    style: TextStyle(
                      color: warningColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$platformName Balance',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(balance),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isLowBalance ? warningColor : brandColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            lastUpdated != null
                ? 'As of ${DateFormat('MMM d, h:mm a').format(lastUpdated!)}'
                : 'No transactions logged',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Trend Line Graph using fl_chart showing custom bezier curves for both platforms
class _TrendChartCard extends StatelessWidget {
  final ChartPeriod period;
  final List<TransactionRecord> transactions;
  final DateTime now;
  final bool isDark;
  final ThemeData theme;

  const _TrendChartCard({
    required this.period,
    required this.transactions,
    required this.now,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Group transaction volumes by coordinate indexes
    final List<FlSpot> gcashSpots = [];
    final List<FlSpot> mayaSpots = [];
    final List<String> xLabels = [];

    int dataCount = 7;
    if (period == ChartPeriod.week) {
      dataCount = 7;
    } else if (period == ChartPeriod.month) {
      dataCount = 30;
    } else {
      dataCount = 12;
    }

    final List<double> gcashYVals = List.filled(dataCount, 0.0);
    final List<double> mayaYVals = List.filled(dataCount, 0.0);

    if (period == ChartPeriod.week) {
      // 7-day trend
      for (int i = 0; i < 7; i++) {
        final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        xLabels.add(DateFormat('E').format(targetDate)); // e.g. Mon, Tue

        final dayTxns = transactions.where((t) =>
            t.timestamp.year == targetDate.year &&
            t.timestamp.month == targetDate.month &&
            t.timestamp.day == targetDate.day).toList();

        gcashYVals[i] = dayTxns
            .where((t) => t.platform == Platform.gcash)
            .fold(0.0, (sum, t) => sum + t.amount);

        mayaYVals[i] = dayTxns
            .where((t) => t.platform == Platform.maya)
            .fold(0.0, (sum, t) => sum + t.amount);
      }
    } else if (period == ChartPeriod.month) {
      // 30-day daily transactions
      for (int i = 0; i < 30; i++) {
        final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i));
        xLabels.add(targetDate.day.toString()); // e.g. 15, 16

        final dayTxns = transactions.where((t) =>
            t.timestamp.year == targetDate.year &&
            t.timestamp.month == targetDate.month &&
            t.timestamp.day == targetDate.day).toList();

        gcashYVals[i] = dayTxns
            .where((t) => t.platform == Platform.gcash)
            .fold(0.0, (sum, t) => sum + t.amount);

        mayaYVals[i] = dayTxns
            .where((t) => t.platform == Platform.maya)
            .fold(0.0, (sum, t) => sum + t.amount);
      }
    } else {
      // 12-month summary
      for (int i = 0; i < 12; i++) {
        final targetMonth = DateTime(now.year, now.month, 1).subtract(Duration(days: (11 - i) * 30));
        xLabels.add(DateFormat('MMM').format(targetMonth)); // e.g. Jan, Feb

        final monthTxns = transactions.where((t) =>
            t.timestamp.year == targetMonth.year &&
            t.timestamp.month == targetMonth.month).toList();

        gcashYVals[i] = monthTxns
            .where((t) => t.platform == Platform.gcash)
            .fold(0.0, (sum, t) => sum + t.amount);

        mayaYVals[i] = monthTxns
            .where((t) => t.platform == Platform.maya)
            .fold(0.0, (sum, t) => sum + t.amount);
      }
    }

    // Populate FlSpots
    for (int i = 0; i < dataCount; i++) {
      gcashSpots.add(FlSpot(i.toDouble(), gcashYVals[i]));
      mayaSpots.add(FlSpot(i.toDouble(), mayaYVals[i]));
    }

    // Calculate Y axis boundaries
    double maxVolume = 0.0;
    for (final v in gcashYVals) {
      if (v > maxVolume) maxVolume = v;
    }
    for (final v in mayaYVals) {
      if (v > maxVolume) maxVolume = v;
    }
    if (maxVolume == 0) maxVolume = 1000.0; // fallback default
    maxVolume = (maxVolume * 1.15); // pad a bit at top

    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(10, 24, 22, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: period == ChartPeriod.month ? 5 : 1, // thin out for month days
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < xLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              xLabels[idx],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                fontSize: period == ChartPeriod.month ? 9 : 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Text(
                            '₱0',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        String formatted = value >= 1000 ? '₱${(value / 1000).toStringAsFixed(0)}k' : '₱${value.toStringAsFixed(0)}';
                        return Text(
                          formatted,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (dataCount - 1).toDouble(),
                minY: 0,
                maxY: maxVolume,
                lineBarsData: [
                  // GCash bold blue line
                  LineChartBarData(
                    spots: gcashSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.gcash,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.gcash.withValues(alpha: 0.12),
                    ),
                  ),
                  // Maya bold green line
                  LineChartBarData(
                    spots: mayaSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.maya,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.maya.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => theme.colorScheme.surfaceContainerHighest,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isGcash = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isGcash ? "GCash" : "Maya"}: ₱${spot.y.toStringAsFixed(0)}',
                          theme.textTheme.bodySmall!.copyWith(
                            color: isGcash ? AppColors.gcash : AppColors.maya,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend indicator Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.gcash, 'GCash'),
              const SizedBox(width: 24),
              _buildLegendDot(AppColors.maya, 'Maya Business'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Generic container for dynamic dashboard business insights
class _InsightItemCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final ThemeData theme;

  const _InsightItemCard({
    required this.title,
    required this.child,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
