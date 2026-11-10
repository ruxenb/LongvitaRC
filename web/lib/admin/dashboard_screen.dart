import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_core/theme/app_colors.dart';
import 'package:longvita_core/services/admin_service.dart';
import 'package:longvita_admin/admin/admin_states.dart';
import 'package:longvita_admin/admin/admin_viewmodels.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<DashboardViewModel>(
    builder: (context, vm, _) => Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Tổng quan',
            subtitle: 'Số liệu vận hành Longvita từ Cloud Firestore',
            action: IconButton(
              tooltip: 'Làm mới',
              onPressed: vm.load,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 28),
          if (vm.state != AdminLoadState.ready)
            Expanded(
              child: AdminStateView(
                state: vm.state,
                error: vm.error,
                emptyTitle: 'Chưa có số liệu',
                emptyMessage: 'Firestore chưa có dữ liệu để thống kê.',
                retry: vm.load,
              ),
            )
          else
            Expanded(child: _DashboardContent(metrics: vm.metrics!)),
        ],
      ),
    ),
  );
}

class _DashboardContent extends StatelessWidget {
  final AdminDashboardMetrics metrics;
  const _DashboardContent({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final values = <(String, int, IconData)>[
      ('Công thức hoạt động', metrics.activeRecipes, Icons.restaurant),
      ('Thực đơn chờ duyệt', metrics.submittedPlans, Icons.pending_actions),
      ('Thực đơn đã duyệt', metrics.approvedPlans, Icons.verified),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 32) / 3;
        final maxValue = values.fold<int>(
          1,
          (max, row) => row.$2 > max ? row.$2 : max,
        );
        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final row in values)
                    SizedBox(
                      width: width.clamp(230, 420),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.bgSelected,
                                child: Icon(
                                  row.$3,
                                  color: AppColors.actionPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${row.$2}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    Text(row.$1),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân bổ dữ liệu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      for (final row in values) ...[
                        Row(
                          children: [
                            SizedBox(width: 180, child: Text(row.$1)),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: row.$2 / maxValue,
                                minHeight: 18,
                                borderRadius: BorderRadius.circular(9),
                                backgroundColor: AppColors.bgSelected,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(width: 40, child: Text('${row.$2}')),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
