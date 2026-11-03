import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient_model.dart';
import '../models/meal_plan_model.dart';
import '../models/view_state.dart';
import '../viewmodels/ingredient_viewmodel.dart';
import '../viewmodels/meal_plan_viewmodel.dart';
import '../widgets/app_button.dart';
import 'flow_ui.dart';

/// S07: aggregate from current plan, edit quantity, delete and Undo.
class IngredientSummaryScreen extends StatefulWidget {
  const IngredientSummaryScreen({super.key});

  @override
  State<IngredientSummaryScreen> createState() =>
      _IngredientSummaryScreenState();
}

class _IngredientSummaryScreenState extends State<IngredientSummaryScreen> {
  MealPlanModel? get _plan => context.read<MealPlanViewModel>().activePlan;

  void _load() {
    final plan = _plan;
    if (plan != null) {
      context.read<IngredientViewModel>().loadForPlan(plan);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _edit(IngredientModel ingredient) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _EditAmountDialog(item: ingredient),
    );
    if (!mounted || amount == null) return;
    final vm = context.read<IngredientViewModel>();
    if (!vm.updateAmount(ingredient.id, amount)) {
      flowSnack(context, 'Số lượng phải lớn hơn 0.');
      return;
    }
    final saved = await vm.persistChanges();
    if (mounted) {
      flowSnack(
        context,
        saved ? 'Đã lưu số lượng nguyên liệu.' : 'Chưa đồng bộ. Hãy thử lại.',
        actionLabel: saved ? null : 'Thử lại',
        onAction: saved ? null : () => vm.persistChanges(),
      );
    }
  }

  void _delete(IngredientModel item) {
    final vm = context.read<IngredientViewModel>();
    vm.deleteIngredient(item.id);
    vm.persistChanges();
    flowSnack(
      context,
      'Đã xóa ${item.name}',
      actionLabel: 'Hoàn tác',
      onAction: () {
        if (vm.undoDelete()) vm.persistChanges();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IngredientViewModel>();
    final plan = context.watch<MealPlanViewModel>().activePlan;
    return FlowFrame(
      title: 'S07 • Tổng hợp nguyên liệu',
      actions: [
        IconButton(
          tooltip: 'Tải lại nguyên liệu',
          onPressed: plan == null ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: plan == null
          ? const Text('Chưa có thực đơn. Hãy tạo kế hoạch trước.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FlowSection(
                  title: 'Nguyên liệu cho 7 ngày',
                  child: Text(
                    'Gộp nguyên liệu trùng tên và đơn vị. '
                    'Có thể sửa số lượng, xóa và hoàn tác nếu xóa nhầm.',
                  ),
                ),
                FlowStateView<List<IngredientModel>>(
                  state: vm.state,
                  emptyTitle: 'Danh sách trống',
                  onRetry: _load,
                  onBack: () => Navigator.of(context).pop(),
                  onData: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        Card(
                          child: ListTile(
                            minTileHeight: 56,
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                            ),
                            leading: const Icon(Icons.eco_outlined),
                            trailing: SizedBox(
                              width: 104,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Sửa số lượng ${item.name}',
                                    onPressed: () => _edit(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Xóa ${item.name}',
                                    onPressed: () => _delete(item),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!vm.isSavedPlan) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Để lưu checklist bền vững trên Firestore, '
                      'hãy quay lại S04 và lưu thực đơn trước khi đi chợ.',
                    ),
                  ),
                ],
                if (vm.persistenceState is ViewStateError<bool>)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      (vm.persistenceState as ViewStateError<bool>).message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Tạo danh sách mua sắm',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: vm.isSavedPlan
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ShoppingListScreen(),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Quay lại thực đơn',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
    );
  }
}

/// Edit dialog with true Form validation, independent of parent build().
class _EditAmountDialog extends StatefulWidget {
  final IngredientModel item;
  const _EditAmountDialog({required this.item});

  @override
  State<_EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<_EditAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text = TextEditingController(
    text: widget.item.amount.toStringAsFixed(
      widget.item.amount % 1 == 0 ? 0 : 1,
    ),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chỉnh số lượng'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        key: const Key('edit-ingredient-amount'),
        autofocus: true,
        controller: _text,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: 'Số lượng (${widget.item.unit})',
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
          return n == null || !n.isFinite || n <= 0
              ? 'Số lượng phải lớn hơn 0'
              : null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.of(context)
              .pop(double.parse(_text.text.trim().replaceAll(',', '.')));
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}

/// S08: checked state is persisted in Firestore for this user and plan.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  Future<void> _toggle(BuildContext context, IngredientModel item) async {
    final vm = context.read<IngredientViewModel>();
    vm.togglePurchased(item.id);
    final success = await vm.persistChanges();
    if (!success && context.mounted) {
      flowSnack(
        context,
        'Checklist chưa lưu được. Kiểm tra mạng rồi thử lại.',
        actionLabel: 'Thử lại',
        onAction: () => vm.persistChanges(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IngredientViewModel>();
    return FlowFrame(
      title: 'S08 • Danh sách mua sắm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowSection(
            title: 'Đồ cần mua',
            child: Text(
              'Đánh dấu nguyên liệu đã mua. Các thay đổi được '
              'đồng bộ theo tài khoản và thực đơn lên Firestore.',
            ),
          ),
          FlowStateView<List<IngredientModel>>(
            state: vm.state,
            emptyTitle: 'Không có nguyên liệu',
            onRetry: () {
              final plan = context.read<MealPlanViewModel>().activePlan;
              if (plan != null) vm.loadForPlan(plan);
            },
            onBack: () => Navigator.of(context).pop(),
            onData: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đã mua: ${items.where((item) => item.isPurchased).length}/${items.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final item in items)
                  Card(
                    child: CheckboxListTile(
                      key: Key('shopping-${item.id}'),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                      ),
                      value: item.isPurchased,
                      onChanged: (_) => _toggle(context, item),
                    ),
                  ),
              ],
            ),
          ),
          if (vm.persistenceState is ViewStateLoading<bool>)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(
                semanticsLabel: 'Đang đồng bộ checklist',
              ),
            ),
          if (vm.persistenceState is ViewStateError<bool>)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                (vm.persistenceState as ViewStateError<bool>).message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
