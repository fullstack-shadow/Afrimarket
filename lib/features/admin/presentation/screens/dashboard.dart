import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import '../../../../core/localization/localization_service.dart';
import '../../../../core/themming/theme_manager.dart';
import '../../../../widgets/shared/app_bar.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme;
    final loc = LocalizationService.of(context);
    final controller = context.watch<AdminController>();

    return Scaffold(
      appBar: AdminAppBar(
        title: loc.translate('admin_dashboard_title'),
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(controller, theme, loc),
              const SizedBox(height: 24),
              _buildSalesChart(controller, theme, loc),
              const SizedBox(height: 24),
              _buildRecentActivity(controller, theme, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    AdminController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSummaryCard(
          theme,
          loc.translate('total_users'),
          '${controller.stats?.totalUsers ?? 0}',
          Icons.people_outline,
          theme.primaryColor,
        ),
        _buildSummaryCard(
          theme,
          loc.translate('active_sellers'),
          '${controller.stats?.activeSellers ?? 0}',
          Icons.store_outlined,
          Colors.green,
        ),
        _buildSummaryCard(
          theme,
          loc.translate('today_orders'),
          '${controller.stats?.todayOrders ?? 0}',
          Icons.shopping_bag_outlined,
          Colors.orange,
        ),
        _buildSummaryCard(
          theme,
          loc.translate('total_revenue'),
          '\$${controller.stats?.totalRevenue?.toStringAsFixed(2) ?? '0.00'}',
          Icons.attach_money_outlined,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              loc.translate('sales_trend'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: controller.stats?.salesChartData != null
                  ? charts.TimeSeriesChart(
                      [
                        charts.Series<TimeSeriesSales, DateTime>(
                          id: 'Sales',
                          colorFn: (_, __) =>
                              charts.ColorUtil.fromDartColor(theme.primaryColor),
                          domainFn: (TimeSeriesSales sales, _) => sales.time,
                          measureFn: (TimeSeriesSales sales, _) => sales.sales,
                          data: controller.stats!.salesChartData,
                        )
                      ],
                      animate: true,
                      dateTimeFactory: const charts.LocalDateTimeFactory(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
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
              loc.translate('recent_activity'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.stats?.recentActivities.isEmpty ?? true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  loc.translate('no_recent_activity'),
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ...controller.stats!.recentActivities.map((activity) =>
                  _buildActivityItem(activity, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(AdminActivity activity, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _getActivityIcon(activity.type),
            size: 20,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(AdminActivityType type) {
    switch (type) {
      case AdminActivityType.order:
        return Icons.shopping_bag_outlined;
      case AdminActivityType.user:
        return Icons.person_outline;
      case AdminActivityType.payment:
        return Icons.payment_outlined;
      case AdminActivityType.system:
        return Icons.settings_outlined;
    }
  }
}