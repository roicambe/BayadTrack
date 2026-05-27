import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../database/transaction_model.dart';
import '../database/isar_service.dart';
import '../widgets/sky_background.dart';

enum ChartPeriod { week, month, year }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = IsarService();
  ChartPeriod _selectedPeriod = ChartPeriod.week;
  ChartPeriod _insightsPeriod = ChartPeriod.week;
  Platform _selectedEarningsPlatform = Platform.gcash;
  int _activeInsightTab = 0;



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return SkyBackground(
      child: SafeArea(
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
          final hour = now.hour;
          final greeting = hour < 12
              ? 'Good Morning, Mommy!'
              : hour < 18
                  ? 'Good Afternoon, Mommy!'
                  : 'Good Evening, Mommy!';



          // Calculate insightsPeriodStart based on _insightsPeriod
          DateTime insightsPeriodStart;
          switch (_insightsPeriod) {
            case ChartPeriod.week:
              insightsPeriodStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
              break;
            case ChartPeriod.month:
              insightsPeriodStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
              break;
            case ChartPeriod.year:
              insightsPeriodStart = DateTime(now.year, now.month, 1).subtract(const Duration(days: 365));
              break;
          }

          final insightsTransactions = transactions
              .where((t) => t.timestamp.isAfter(insightsPeriodStart) || t.timestamp.isAtSameMomentAs(insightsPeriodStart))
              .toList();

          // Insights Calculations for Top Customers using insightsTransactions
          final activeCounts = <String, int>{};
          final highestValue = <String, double>{};
          final topServiceFees = <String, double>{};

          for (final t in insightsTransactions) {
            final name = t.senderName?.trim() ?? '';
            if (name.isNotEmpty && name.toLowerCase() != 'unknown') {
              activeCounts[name] = (activeCounts[name] ?? 0) + 1;
              highestValue[name] = (highestValue[name] ?? 0.0) + t.amount;
              topServiceFees[name] = (topServiceFees[name] ?? 0.0) + (t.fee ?? 0.0);
            }
          }

          List<MapEntry<String, int>> topActive = [];
          if (activeCounts.isNotEmpty) {
            topActive = activeCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (topActive.length > 10) topActive = topActive.sublist(0, 10);
          }

          List<MapEntry<String, double>> topValue = [];
          if (highestValue.isNotEmpty) {
            topValue = highestValue.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (topValue.length > 10) topValue = topValue.sublist(0, 10);
          }

          List<MapEntry<String, double>> topFees = [];
          if (topServiceFees.isNotEmpty) {
            topFees = topServiceFees.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (topFees.length > 10) topFees = topFees.sublist(0, 10);
          }

          // Insights Calculation: Platform Split
          int gcashCount = insightsTransactions.where((t) => t.platform == Platform.gcash).length;
          int mayaCount = insightsTransactions.where((t) => t.platform == Platform.maya).length;
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              letterSpacing: -0.5,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(now),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(color: Color(0x88000000), blurRadius: 6),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            _LiveClock(
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(color: Color(0x88000000), blurRadius: 6),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
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

                // ── 3. Pure Earnings (Kita) Bar Chart ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: const _SectionLabel('Pure Earnings (Kita)')),
                    const SizedBox(width: 8),
                    // Platform Segmented Toggle
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPlatformToggle(Platform.gcash, 'GCash', theme),
                          _buildPlatformToggle(Platform.maya, 'Maya', theme),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _EarningsBarChartCard(
                  period: _selectedPeriod,
                  transactions: transactions,
                  platform: _selectedEarningsPlatform,
                  now: now,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: 28),

                // ── 4. Business Insights ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: const _SectionLabel('Business Insights')),
                    const SizedBox(width: 8),
                    // Segmented Button Toggle Selector for Insights
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInsightsPeriodToggle(ChartPeriod.week, 'Week', theme),
                          _buildInsightsPeriodToggle(ChartPeriod.month, 'Month', theme),
                          _buildInsightsPeriodToggle(ChartPeriod.year, 'Year', theme),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _InsightItemCard(
                      title: 'Top Customers Analytics',
                      icon: Icons.analytics_rounded,
                      iconColor: Colors.purple.shade400,
                      isDark: isDark,
                      theme: theme,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildInsightTabButton(0, 'Most Active', Icons.people_alt_rounded),
                              _buildInsightTabButton(1, 'Top Earnings', Icons.price_check_rounded),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_activeInsightTab == 0) ...[
                            _buildRankedList(
                              topActive,
                              valueFormatter: (val) => '$val txns',
                              theme: theme,
                            ),
                          ] else ...[
                            _buildRankedList(
                              topFees,
                              valueFormatter: (val) => currencyFormat.format(val),
                              theme: theme,
                            ),
                          ],
                        ],
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
                              Text('GCash ${(gcashPercent * 100).toStringAsFixed(0)}%', textScaler: TextScaler.noScaling, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.gcash)),
                              const SizedBox(width: 16),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.maya, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('Maya ${(mayaPercent * 100).toStringAsFixed(0)}%', textScaler: TextScaler.noScaling, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.maya)),
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
      ), // end SafeArea
    ); // end SkyBackground
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
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformToggle(Platform platform, String text, ThemeData theme) {
    final isSelected = _selectedEarningsPlatform == platform;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEarningsPlatform = platform;
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
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightTabButton(int index, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _activeInsightTab == index;
    final activeColor = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeInsightTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankedList<T>(
    List<MapEntry<String, T>> data, {
    required String Function(T) valueFormatter,
    required ThemeData theme,
  }) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'No records logged for this period',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(data.length, (idx) {
        final entry = data[idx];
        final rank = idx + 1;

        // Custom ranking color badges for top 3
        Color rankColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);
        if (rank == 1) rankColor = Colors.amber.shade700;
        if (rank == 2) rankColor = Colors.grey.shade500;
        if (rank == 3) rankColor = Colors.brown.shade400;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0),
          child: Row(
            children: [
              // Rank indicator
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Customer Name
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Metric value
              Text(
                valueFormatter(entry.value),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInsightsPeriodToggle(ChartPeriod period, String text, ThemeData theme) {
    final isSelected = _insightsPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _insightsPeriod = period;
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
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
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
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        shadows: const [
          Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
        ],
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: warningColor,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currencyFormat.format(balance),
              style: theme.textTheme.titleLarge?.copyWith(
                color: isLowBalance ? warningColor : brandColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lastUpdated != null
                ? 'As of ${DateFormat('MMM d, h:mm a').format(lastUpdated!)}'
                : 'No transactions logged',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
        xLabels.add(DateFormat('M/d').format(targetDate)); // e.g. 4/27, 5/2

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
                              textScaler: TextScaler.noScaling,
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
                            textScaler: TextScaler.noScaling,
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
                          textScaler: TextScaler.noScaling,
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
          textScaler: TextScaler.noScaling,
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

/// Premium Service Fee Pure Earnings Bar Chart Card using fl_chart
class _EarningsBarChartCard extends StatelessWidget {
  final ChartPeriod period;
  final List<TransactionRecord> transactions;
  final Platform platform;
  final DateTime now;
  final bool isDark;
  final ThemeData theme;

  const _EarningsBarChartCard({
    required this.period,
    required this.transactions,
    required this.platform,
    required this.now,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = platform == Platform.maya ? AppColors.maya : AppColors.gcash;
    final List<String> xLabels = [];

    int dataCount = 7;
    if (period == ChartPeriod.week) {
      dataCount = 7;
    } else if (period == ChartPeriod.month) {
      dataCount = 30;
    } else {
      dataCount = 12;
    }

    final List<double> earningsYVals = List.filled(dataCount, 0.0);

    if (period == ChartPeriod.week) {
      for (int i = 0; i < 7; i++) {
        final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        xLabels.add(DateFormat('E').format(targetDate));

        final dayTxns = transactions.where((t) =>
            t.platform == platform &&
            t.timestamp.year == targetDate.year &&
            t.timestamp.month == targetDate.month &&
            t.timestamp.day == targetDate.day).toList();

        earningsYVals[i] = dayTxns.fold(0.0, (sum, t) => sum + (t.fee ?? 0.0));
      }
    } else if (period == ChartPeriod.month) {
      for (int i = 0; i < 30; i++) {
        final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i));
        xLabels.add(DateFormat('M/d').format(targetDate));

        final dayTxns = transactions.where((t) =>
            t.platform == platform &&
            t.timestamp.year == targetDate.year &&
            t.timestamp.month == targetDate.month &&
            t.timestamp.day == targetDate.day).toList();

        earningsYVals[i] = dayTxns.fold(0.0, (sum, t) => sum + (t.fee ?? 0.0));
      }
    } else {
      for (int i = 0; i < 12; i++) {
        final targetMonth = DateTime(now.year, now.month, 1).subtract(Duration(days: (11 - i) * 30));
        xLabels.add(DateFormat('MMM').format(targetMonth));

        final monthTxns = transactions.where((t) =>
            t.platform == platform &&
            t.timestamp.year == targetMonth.year &&
            t.timestamp.month == targetMonth.month).toList();

        earningsYVals[i] = monthTxns.fold(0.0, (sum, t) => sum + (t.fee ?? 0.0));
      }
    }

    double maxVal = 0.0;
    double totalEarnings = 0.0;
    for (final v in earningsYVals) {
      totalEarnings += v;
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 100.0;
    maxVal = (maxVal * 1.15);

    final barGroups = List.generate(dataCount, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: earningsYVals[i],
            color: color,
            width: period == ChartPeriod.month ? 4.5 : 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal,
              color: color.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total ${platform == Platform.gcash ? "GCash" : "Maya"} Kita',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(totalEarnings),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: period == ChartPeriod.month ? 5 : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (period == ChartPeriod.month && idx % 5 != 0 && idx != xLabels.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (idx >= 0 && idx < xLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              xLabels[idx],
                              textScaler: TextScaler.noScaling,
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
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Text(
                            '₱0',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return Text(
                          '₱${value.toStringAsFixed(0)}',
                          textScaler: TextScaler.noScaling,
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
                barGroups: barGroups,
                minY: 0,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₱${rod.toY.toStringAsFixed(2)}',
                        theme.textTheme.bodySmall!.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  final TextStyle? textStyle;
  const _LiveClock({this.textStyle});

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('hh:mm:ss a').format(_now),
      style: widget.textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
