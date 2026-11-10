import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import 'admin_states.dart';
import 'admin_viewmodels.dart';
import 'review_queue_item.dart';

class ReviewQueueScreen extends StatefulWidget {
  final bool showGuidance;
  final bool refreshingConfig;
  final VoidCallback? refreshConfig;

  const ReviewQueueScreen({
    super.key,
    this.showGuidance = true,
    this.refreshingConfig = false,
    this.refreshConfig,
  });

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
          if (widget.showGuidance) ...[
            const SizedBox(height: 16),
            Material(
              color: AppColors.bgPeach,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: const Text('Hướng dẫn xét duyệt đang bật'),
                subtitle: const Text(
                  'Kiểm tra đủ 7 ngày trước khi duyệt; khi từ chối phải nêu rõ lý do.',
                ),
                trailing: widget.refreshConfig == null
                    ? null
                    : IconButton(
                        tooltip: 'Cập nhật Remote Config',
                        onPressed: widget.refreshingConfig
                            ? null
                            : widget.refreshConfig,
                        icon: widget.refreshingConfig
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                      ),
              ),
            ),
          ],
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
  final ReviewQueueItem plan;
  final ReviewQueueViewModel vm;
  const _PlanCard({required this.plan, required this.vm});

  Future<void> reject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );
    if (reason != null && context.mounted) {
      await _review(context, 'rejected', reason: reason);
    }
  }

  Future<void> _review(
    BuildContext context,
    String status, {
    String? reason,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.review(plan, status, reason: reason);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể cập nhật xét duyệt: $error')),
      );
    }
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
                  if (plan.plan case final details?)
                    Text(
                      '${details.days.length} ngày • ${details.targetCalories.toStringAsFixed(0)} kcal • ${details.targetProteinGrams.toStringAsFixed(0)} g protein',
                    )
                  else
                    const Text(
                      'Dữ liệu thực đơn lỗi. Không thể duyệt; hãy từ chối kèm lý do.',
                      style: TextStyle(color: AppColors.feedbackError),
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
                onPressed: plan.canApprove
                    ? () => _review(context, 'approved')
                    : null,
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

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _validationError = 'Vui lòng nhập lý do từ chối.');
      return;
    }
    if (value.characters.length > 500) {
      setState(() => _validationError = 'Lý do không được vượt quá 500 ký tự.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Từ chối thực đơn'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLines: 3,
      onChanged: (_) {
        if (_validationError != null) {
          setState(() => _validationError = null);
        }
      },
      decoration: InputDecoration(
        labelText: 'Lý do',
        hintText: 'Nêu rõ điểm cần điều chỉnh',
        errorText: _validationError,
        counterText: '${_controller.text.characters.length}/500',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Xác nhận từ chối')),
    ],
  );
}
