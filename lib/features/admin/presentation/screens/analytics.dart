import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../widgets/shared/app_bar.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/analytics_time_frame.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsTimeFrame _currentTimeFrame = AnalyticsTimeFrame.last7Days;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme;
    final loc = LocalizationService.of(context);
    final controller = context.watch<AdminController>();

    return Scaffold(
      appBar: AdminAppBar(
        title: loc.translate('analytics_title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshAnalytics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeFrameSelector(controller, loc),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetricRow(controller, theme, loc),
                  const SizedBox(height: 24),
                  _buildSalesChart(controller, theme, loc),
                  const SizedBox(height: 24),
                  _buildUserGrowthChart(controller, theme, loc),
                  const SizedBox(height: 24),
                  _buildTopProducts(controller, theme, loc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector(
    AdminController controller,
    LocalizationService loc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: AnalyticsTimeFrame.values.map((frame) {
          return ChoiceChip(
            label: Text(loc.translate(frame.name)),
            selected: _currentTimeFrame == frame,
            onSelected: (selected) {
              if (selected) {
                setState(() => _currentTimeFrame = frame);
                controller.changeAnalyticsTimeFrame(frame);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricRow(
    AdminController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    if (controller.isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMetricCard(
          theme,
          loc.translate('conversion_rate'),
          '${controller.analytics?.conversionRate?.toStringAsFixed(1) ?? '0.0'}%',
          Icons.trending_up_outlined,
          Colors.green,
        ),
        _buildMetricCard(
          theme,
          loc.translate('avg_order_value'),
          '\$${controller.analytics?.avgOrderValue?.toStringAsFixed(2) ?? '0.00'}',
          Icons.attach_money_outlined,
          Colors.blue,
        ),
        _buildMetricCard(
          theme,
          loc.translate('repeat_customers'),
          '${controller.analytics?.repeatCustomerRate?.toStringAsFixed(1) ?? '0.0'}%',
          Icons.repeat_outlined,
          Colors.purple,
        ),
        _buildMetricCard(
          theme,
          loc.translate('referee_signups'),
          '${controller.analytics?.refereeSignups ?? 0}',
          Icons.people_alt_outlined,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 150,
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart(
    AdminController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('sales_analytics'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: controller.analytics?.salesSeries != null
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (controller.analytics!.salesSeries.map((e) => e.sales).reduce((a, b) => a > b ? a : b) * 1.2),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < controller.analytics!.salesSeries.length) {
                                  return SideTitleWidget(
                                    axisSide: AxisSide.bottom,
                                    space: 8,
                                    child: Text(
                                      controller.analytics!.salesSeries[index].period,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    meta: meta,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        barGroups: controller.analytics!.salesSeries
                            .asMap()
                            .entries
                            .map(
                              (e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.sales,
                                    color: theme.primaryColor,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart(
    AdminController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('user_growth'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: controller.analytics?.userGrowthSeries != null
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < controller.analytics!.userGrowthSeries.length) {
                                  return SideTitleWidget(
                                    axisSide: AxisSide.bottom,
                                    space: 8,
                                    child: Text(
                                      controller.analytics!.userGrowthSeries[index].period,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    meta: meta,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: controller.analytics!.userGrowthSeries
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.count.toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withAlpha(25),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(
    AdminController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    if (controller.analytics?.topProducts.isEmpty ?? true) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('top_products'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...controller.analytics!.topProducts.map((product) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: theme.dividerColor,
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${product.sales} ${loc.translate('sales')} • \$${product.revenue.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}