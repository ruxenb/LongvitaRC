import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/vietnamese_ui.dart';
import '../models/ingredient_model.dart';
import '../models/meal_plan_model.dart';
import '../models/view_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/ingredient_viewmodel.dart';
import '../viewmodels/meal_plan_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/app_supporting.dart';
import '../widgets/app_top_bar.dart';
import 'flow_ui.dart';
import 'meal_flow_screens.dart';
import 'profile_screen.dart';

/// Flow 2 Final UI: Figma 106:189 / 106:235. Data and persistence stay in
/// IngredientViewModel; grouping only changes presentation, never stored data.
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
    if (plan != null) context.read<IngredientViewModel>().loadForPlan(plan);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _edit(IngredientModel ingredient) async {
    final result = await showDialog<Object>(
      context: context,
      barrierLabel: 'Đóng',
      builder: (_) => VietnameseUi(child: _EditAmountDialog(item: ingredient)),
    );
    if (!mounted || result == null) return;
    if (result == _IngredientAction.delete) {
      _delete(ingredient);
      return;
    }
    final vm = context.read<IngredientViewModel>();
    if (result is! double || !vm.updateAmount(ingredient.id, result)) {
      flowSnack(context, 'Số lượng phải lớn hơn 0.');
      return;
    }
    final saved = await vm.persistChanges();
    if (mounted) {
      flowSnack(
        context,
        saved ? 'Đã lưu số lượng nguyên liệu.' : 'Chưa có xác nhận đồng bộ. Thay đổi có thể được lưu khi có mạng; hãy tải lại để kiểm tra.',
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
    return _ShoppingFrame(
      title: 'Nguyên liệu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowHeading('Nguyên liệu trong tuần'),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Đã gộp nguyên liệu trùng tên và đơn vị.',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: AppSpacing.s8),
          if (plan == null)
            const Text('Chưa có thực đơn. Hãy tạo kế hoạch trước.')
          else ...[
            FlowStateView<List<IngredientModel>>(
              state: vm.state,
              emptyTitle: 'Danh sách trống',
              onRetry: _load,
              onBack: () => Navigator.of(context).maybePop(),
              onData: (items) => _GroupedIngredients(
                items: items,
                itemBuilder: (item) =>
                    _IngredientRow(item: item, onEdit: () => _edit(item)),
              ),
            ),
            _PersistenceFeedback(vm: vm),
            if (!vm.isSavedPlan)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: Text(
                  'Hãy lưu thực đơn trước khi tạo danh sách mua sắm.',
                  style: AppTypography.supporting,
                ),
              ),
            AppButton(
              key: const Key('create-shopping-list'),
              text: 'Tạo danh sách mua sắm',
              icon: AppIcons.arrowForward,
              onPressed:
                  vm.isSavedPlan &&
                      vm.state is ViewStateSuccess<List<IngredientModel>>
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ShoppingListScreen(),
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

enum _IngredientAction { delete }

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
    text: _amountText(widget.item.amount),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Semantics(
      header: true,
      headingLevel: 1,
      child: Text('Chỉnh số lượng'),
    ),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('edit-ingredient-amount'),
          autofocus: true,
          controller: _text,
          // The selection menu is built in the root Overlay, outside this
          // flow's localization subtree. Carry Vietnamese into that overlay.
          contextMenuBuilder: (context, editableTextState) => VietnameseUi(
            child: AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            labelText: 'Số lượng (${_unit(widget.item.unit)})',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final n = double.tryParse(
              (value ?? '').trim().replaceAll(',', '.'),
            );
            return n == null || !n.isFinite || n <= 0
                ? 'Số lượng phải lớn hơn 0'
                : null;
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(_IngredientAction.delete),
        style: TextButton.styleFrom(foregroundColor: AppColors.feedbackError),
        child: const Text('Xóa nguyên liệu'),
      ),
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

/// Checked state remains the same owner/plan-scoped Firestore checklist.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  Future<void> _toggle(BuildContext context, IngredientModel item) async {
    final vm = context.read<IngredientViewModel>();
    vm.togglePurchased(item.id);
    final success = await vm.persistChanges();
    if (!success && context.mounted) {
      flowSnack(
        context,
        'Chưa có xác nhận đồng bộ. Danh sách có thể được lưu khi có mạng; hãy tải lại để kiểm tra.',
        actionLabel: 'Thử lại',
        onAction: () => vm.persistChanges(),
      );
    }
  }

  void _navigate(BuildContext context, int index) {
    final navigator = Navigator.of(context);
    switch (index) {
      case 0:
        navigator.popUntil((route) => route.isFirst);
      case 1:
        navigator.push(
          MaterialPageRoute(builder: (_) => const SavedPlansScreen()),
        );
      case 3:
        navigator.pushNamed(ProfileScreen.routeName);
      // Nutrition is this destination; tapping it must not stack another list.
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IngredientViewModel>();
    return _ShoppingFrame(
      title: 'Danh sách mua sắm',
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 2,
        destinations: AppNavigationBar.vietnameseDestinations,
        onDestinationSelected: (index) => _navigate(context, index),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowHeading('Sẵn sàng đi chợ'),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Chạm vào từng nguyên liệu để đánh dấu đã mua.',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: AppSpacing.s8),
          FlowStateView<List<IngredientModel>>(
            state: vm.state,
            emptyTitle: 'Không có nguyên liệu',
            onRetry: () {
              final plan = context.read<MealPlanViewModel>().activePlan;
              if (plan != null) vm.loadForPlan(plan);
            },
            onBack: () => Navigator.of(context).maybePop(),
            onData: (items) => _GroupedIngredients(
              items: items,
              itemBuilder: (item) => AppCheckboxRow(
                key: Key('shopping-${item.id}'),
                label: '${item.name} · ${_quantity(item)}',
                checked: item.isPurchased,
                onChanged: (_) => _toggle(context, item),
              ),
            ),
          ),
          _PersistenceFeedback(vm: vm),
        ],
      ),
    );
  }
}

// Double's shortest round-trip representation preserves the source value.
// Fixed decimal limits would still round e.g. 2.345 or turn 0.004 into zero.
String _amountText(double amount) {
  final text = amount.toString();
  final compact = text.endsWith('.0')
      ? text.substring(0, text.length - 2)
      : text;
  return compact.replaceAll('.', ',');
}

// Format only the display text; the original amount/unit remains unchanged.
String _quantity(IngredientModel item) =>
    '${_amountText(item.amount)} ${_unit(item.unit)}';

String _unit(String raw) => switch (raw.trim().toLowerCase()) {
  'can' || 'cans' => 'lon',
  'medium' => 'cỡ vừa',
  'tbsp' || 'tablespoon' || 'tablespoons' => 'muỗng canh',
  'tsp' || 'teaspoon' || 'teaspoons' => 'muỗng cà phê',
  'cup' || 'cups' => 'cốc',
  'clove' || 'cloves' => 'tép',
  'slice' || 'slices' => 'lát',
  'piece' || 'pieces' => 'miếng',
  'portion' || 'portions' || 'serving' || 'servings' => 'phần',
  _ =>
    raw.trim(), // Preserve unrecognised source units, never guess a conversion.
};

/// Known category aliases reflect existing Vietnamese/English source data.
/// Unknown categories are preserved, not guessed from ingredient names.
String _category(String raw) => switch (raw.trim().toLowerCase()) {
  'vegetables' || 'rau' || 'rau củ' || 'rau_cu' => 'Rau củ',
  'legumes' || 'đậu' || 'các loại đậu' || 'dau' => 'Các loại đậu',
  'nuts and oils' ||
  'nuts' ||
  'oils' ||
  'hạt' ||
  'dầu' ||
  'dầu hạt' => 'Hạt và dầu',
  'wholegrains' || 'whole grains' || 'ngũ cốc' || 'ngu_coc' => 'Ngũ cốc',
  'fish' || 'cá' || 'ca' => 'Cá',
  'spices' || 'gia vị' => 'Gia vị',
  'dairy' || 'phô mai' || 'sữa' => 'Sữa và phô mai',
  '' || 'khác' || 'other' => 'Khác',
  _ => raw.trim(),
};

class _GroupedIngredients extends StatelessWidget {
  final List<IngredientModel> items;
  final Widget Function(IngredientModel) itemBuilder;
  const _GroupedIngredients({required this.items, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<IngredientModel>>{};
    for (final item in items) {
      groups.putIfAbsent(_category(item.category), () => []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          Semantics(
            header: true,
            headingLevel: 3,
            child: Text(entry.key, style: AppTypography.labelStrong),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final item in entry.value) ...[
            itemBuilder(item),
            const SizedBox(height: AppSpacing.s8),
          ],
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientModel item;
  final VoidCallback onEdit;
  const _IngredientRow({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 64),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            label: '${item.name}, ${_quantity(item)}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.labelStrong),
                  const SizedBox(height: 6),
                  Text(
                    _quantity(item),
                    style: AppTypography.supporting.copyWith(height: 20 / 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s16),
        Tooltip(
          excludeFromSemantics: true,
          message: 'Sửa số lượng ${item.name}',
          child: Semantics(
            button: true,
            label: 'Sửa số lượng ${item.name}',
            onTap: onEdit,
            child: ExcludeSemantics(
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  foregroundColor: AppColors.actionPrimary,
                  side: const BorderSide(color: AppColors.borderControl),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.rounded8,
                  ),
                  textStyle: AppTypography.labelStrong,
                ),
                child: const Text('Sửa'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FlowHeading extends StatelessWidget {
  final String text;
  const _FlowHeading(this.text);

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    headingLevel: 2,
    child: Text(
      text,
      style: AppTypography.headingL.copyWith(
        fontSize: 26,
        height: 34 / 26,
        fontVariations: const [
          FontVariation('wght', 700),
          FontVariation('opsz', 26),
        ],
      ),
    ),
  );
}

class _PersistenceFeedback extends StatelessWidget {
  final IngredientViewModel vm;
  const _PersistenceFeedback({required this.vm});

  @override
  Widget build(BuildContext context) {
    final state = vm.persistenceState;
    if (state is ViewStateLoading<bool>) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: LinearProgressIndicator(
          semanticsLabel: 'Đang đồng bộ danh sách mua sắm',
        ),
      );
    }
    if (state is ViewStateError<bool>) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                state.message,
                style: AppTypography.supporting.copyWith(
                  color: AppColors.feedbackError,
                ),
              ),
            ),
            TextButton(
              onPressed: () => vm.persistChanges(),
              child: const Text('Thử lại đồng bộ'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ShoppingFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottomNavigationBar;
  const _ShoppingFrame({
    required this.title,
    required this.child,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) => VietnameseUi(
    child: Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(
        title: title,
        onBack: () => Navigator.of(context).maybePop(),
        backSemanticLabel: 'Quay lại',
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s24,
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
