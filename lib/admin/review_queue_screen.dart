import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan_model.dart';
import '../theme/app_colors.dart';
import 'admin_states.dart';
import 'admin_viewmodels.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReviewQueueViewModel>().start(),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<ReviewQueueViewModel>(
    builder: (context, vm, _) => Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Hàng đợi xét duyệt',
            subtitle: 'Thực đơn người dùng đã gửi cho chuyên gia',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: vm.state == AdminLoadState.ready
                ? ListView.separated(
                    itemCount: vm.plans.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _PlanCard(plan: vm.plans[index], vm: vm),
                  )
                : AdminStateView(
                    state: vm.state,
                    error: vm.error,
                    emptyTitle: 'Không còn thực đơn chờ duyệt',
                    emptyMessage:
                        'Các thực đơn mới sẽ tự động xuất hiện tại đây.',
                    retry: vm.start,
                  ),
          ),
        ],
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  final MealPlanModel plan;
  final ReviewQueueViewModel vm;
  const _PlanCard({required this.plan, required this.vm});

  Future<void> reject(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối thực đơn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do',
            hintText: 'Nêu rõ điểm cần điều chỉnh',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    if (reason != null) await vm.review(plan, 'rejected', reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final busy = vm.processingId == plan.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.bgPeach,
              child: Icon(Icons.calendar_month),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${plan.days.length} ngày • ${plan.targetCalories.toStringAsFixed(0)} kcal • ${plan.targetProteinGrams.toStringAsFixed(0)} g protein',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Người gửi: ${plan.uid}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: () => reject(context),
                icon: const Icon(Icons.close),
                label: const Text('Từ chối'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => vm.review(plan, 'approved'),
                icon: const Icon(Icons.check),
                label: const Text('Duyệt'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
