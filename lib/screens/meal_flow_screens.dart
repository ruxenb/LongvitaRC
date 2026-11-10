import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../models/view_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/meal_plan_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_navigation_bar.dart';
import 'flow_ui.dart';
import 'recipe_flow_screens.dart';
import 'shopping_flow_screens.dart';

/// S02: user-supplied preferences; no hard-coded age/weight sample.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController(text: '55');
  var _isOlderAdult = false;
  var _mealsPerDay = 3;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowFrame(
    title: 'Tùy chọn',
    bottomNavigationBar: const _FlowOneNavigation(selectedIndex: 0),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Điều chỉnh thực đơn cho bạn', style: AppTypography.headingM),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Chỉ cần một vài thông tin. Các giá trị tính toán chỉ để tham khảo.',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: AppSpacing.s24),
          const _FieldLabel('Nhóm tuổi'),
          _ChoiceCard(
            title: 'Dưới 65 tuổi',
            subtitle: 'Khuyến nghị protein tiêu chuẩn',
            selected: !_isOlderAdult,
            onTap: () => setState(() => _isOlderAdult = false),
          ),
          const SizedBox(height: AppSpacing.s8),
          _ChoiceCard(
            title: 'Từ 65 tuổi trở lên',
            subtitle: 'Khuyến nghị được điều chỉnh theo nguồn',
            selected: _isOlderAdult,
            onTap: () => setState(() => _isOlderAdult = true),
          ),
          const SizedBox(height: AppSpacing.s24),
          const _FieldLabel('Cân nặng và protein'),
          TextFormField(
            controller: _weight,
            key: const Key('preferences-weight'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cân nặng của bạn',
              suffixText: 'kg',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = double.tryParse(
                (v ?? '').trim().replaceAll(',', '.'),
              );
              return value == null ||
                      !value.isFinite ||
                      value < 25 ||
                      value > 300
                  ? 'Nhập cân nặng hợp lệ từ 25–300 kg'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.s8),
          ListenableBuilder(
            listenable: _weight,
            builder: (context, _) {
              final kg = double.tryParse(
                _weight.text.trim().replaceAll(',', '.'),
              );
              final factor = _isOlderAdult ? 1.0 : 0.8;
              return _ReadOnlyResult(
                title: 'Mục tiêu được tính toán',
                value: kg == null || !kg.isFinite || kg < 25 || kg > 300
                    ? 'Nhập cân nặng hợp lệ để xem mục tiêu'
                    : '${calculateProteinTargetForAgeGroup(kg, isOlderAdult: _isOlderAdult).round()} g protein/ngày • ${factor.toStringAsFixed(1).replaceAll('.', ',')} g/kg',
              );
            },
          ),
          const SizedBox(height: AppSpacing.s24),
          const _FieldLabel('Số bữa mỗi ngày'),
          _ChoiceCard(
            key: const Key('preferences-meals-3'),
            title: '3 bữa/ngày',
            subtitle: 'Lựa chọn cân bằng mặc định',
            selected: _mealsPerDay == 3,
            onTap: () => setState(() => _mealsPerDay = 3),
          ),
          const SizedBox(height: AppSpacing.s8),
          _ChoiceCard(
            key: const Key('preferences-meals-2'),
            title: '2 bữa/ngày',
            subtitle: 'Khoảng nhịn ăn dài hơn',
            selected: _mealsPerDay == 2,
            onTap: () => setState(() => _mealsPerDay = 2),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Tiếp tục',
            icon: Icons.arrow_forward,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) return;
              final uid = context.read<AuthViewModel>().currentUser?.uid;
              if (uid == null) {
                flowSnack(
                  context,
                  'Vui lòng đăng nhập trước khi tạo thực đơn.',
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreatePlanScreen(
                    uid: uid,
                    isOlderAdult: _isOlderAdult,
                    weightKg: double.parse(
                      _weight.text.trim().replaceAll(',', '.'),
                    ),
                    mealsPerDay: _mealsPerDay,
                    eatingWindowHours: _mealsPerDay == 2 ? 14 : 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// S03: explicitly start generation; handles Loading/Empty/Error + Retry/Back.
class CreatePlanScreen extends StatefulWidget {
  final String uid;
  final bool isOlderAdult;
  final double weightKg;
  final int mealsPerDay;
  final int eatingWindowHours;

  const CreatePlanScreen({
    super.key,
    required this.uid,
    required this.isOlderAdult,
    required this.weightKg,
    required this.mealsPerDay,
    required this.eatingWindowHours,
  });

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  bool _started = false;

  Future<void> _generate() async {
    if (_started) return;
    setState(() => _started = true);
    final vm = context.read<MealPlanViewModel>();
    await vm.generatePlan(
      uid: widget.uid,
      age: widget.isOlderAdult ? 65 : 64,
      weightKg: widget.weightKg,
      mealsPerDay: widget.mealsPerDay,
      eatingWindowHours: widget.eatingWindowHours,
    );
    if (!mounted) return;
    if (vm.currentPlanState is ViewStateSuccess<MealPlanModel>) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
      );
    } else {
      setState(() => _started = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MealPlanViewModel>().currentPlanState;
    return FlowFrame(
      title: 'Tạo thực đơn',
      bottomNavigationBar: const _FlowOneNavigation(selectedIndex: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_started &&
              state is! ViewStateError<MealPlanModel> &&
              state is! ViewStateEmpty<MealPlanModel>) ...[
            Text('Xây dựng chu kỳ 7 ngày', style: AppTypography.headingM),
            const SizedBox(height: AppSpacing.s16),
            const _FieldLabel('Tùy chọn chính'),
            const _ChoiceCard(
              title: 'Nhịp 7 ngày tiêu chuẩn',
              subtitle: 'Chu kỳ tuần được đề xuất',
              selected: true,
            ),
            const SizedBox(height: AppSpacing.s8),
            _ChoiceCard(
              title: '${widget.mealsPerDay} bữa/ngày',
              subtitle: 'Tần suất bữa ăn',
              selected: true,
            ),
            const SizedBox(height: AppSpacing.s8),
            const _ChoiceCard(
              title: 'Trường thọ giàu thực vật',
              subtitle: 'Chế độ ăn uống',
              selected: true,
            ),
            const SizedBox(height: AppSpacing.s24),
            const _FieldLabel('Thiết lập dinh dưỡng tùy chọn'),
            _ReadOnlyResult(
              title: 'Mục tiêu protein',
              value:
                  '${calculateProteinTargetForAgeGroup(widget.weightKg, isOlderAdult: widget.isOlderAdult).round()} g protein/ngày',
            ),
            const SizedBox(height: AppSpacing.s8),
            const _ReadOnlyResult(
              title: '7 ngày • Giàu thực vật',
              value: 'Sẵn sàng tạo thực đơn tuần',
              neutral: true,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              text: 'Tạo thực đơn tuần',
              icon: Icons.arrow_forward,
              onPressed: _generate,
            ),
          ] else
            FlowStateView<MealPlanModel>(
              state: state,
              onRetry: _generate,
              onBack: () => Navigator.of(context).pop(),
              onData: (_) => const Text('Đã tạo thực đơn 7 ngày.'),
            ),
        ],
      ),
    );
  }
}

/// S04: full seven-day result; save with honest error handling.
class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  var _selectedDay = 0;

  DateTime _dateForDay(MealPlanModel plan, int dayIndex) {
    final created = DateTime(
      plan.createdAt.year,
      plan.createdAt.month,
      plan.createdAt.day,
    );
    final monday = created.subtract(
      Duration(days: created.weekday - DateTime.monday),
    );
    return monday.add(Duration(days: dayIndex.clamp(0, 6)));
  }

  Future<void> _save(BuildContext context) async {
    final vm = context.read<MealPlanViewModel>();
    final ok = await vm.saveActivePlan();
    if (!context.mounted) return;
    flowSnack(
      context,
      ok
          ? 'Đã lưu kế hoạch lên Firestore.'
          : (vm.saveState is ViewStateError<bool>
                ? (vm.saveState as ViewStateError<bool>).message
                : 'Chưa xác nhận lưu. Thực đơn trên màn hình vẫn được giữ.'),
      actionLabel: ok ? null : 'Thử lại',
      onAction: ok ? null : () => _save(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealPlanViewModel>();
    final plan = vm.activePlan;
    return FlowFrame(
      title: 'Thực đơn tuần',
      bottomNavigationBar: const _FlowOneNavigation(selectedIndex: 1),
      child: plan == null
          ? FlowStateView<MealPlanModel>(
              state: vm.currentPlanState,
              onData: (_) => const Text('Thực đơn đã sẵn sàng.'),
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PreferencesScreen()),
              ),
              onBack: () => Navigator.of(context).pop(),
            )
          : Builder(
              builder: (context) {
                final selected = plan.days.isEmpty
                    ? null
                    : plan.days[_selectedDay.clamp(0, plan.days.length - 1)];
                final selectedDate = selected == null
                    ? null
                    : _dateForDay(plan, selected.dayIndex);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tổng quan tuần của bạn',
                      style: AppTypography.headingM,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plan.days.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final day = plan.days[index];
                          final selectedDay = index == _selectedDay;
                          final date = _dateForDay(plan, day.dayIndex);
                          return Semantics(
                            button: true,
                            selected: selectedDay,
                            label:
                                '${day.dayName}, ngày ${date.day} tháng ${date.month}',
                            child: InkWell(
                              key: Key('weekly-day-${day.dayIndex}'),
                              borderRadius: AppRadius.roundedFull,
                              onTap: () => setState(() => _selectedDay = index),
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 52),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedDay
                                      ? AppColors.actionPrimary
                                      : Colors.transparent,
                                  borderRadius: AppRadius.roundedFull,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${_shortDay(day.dayIndex)}\n${date.day}',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.label.copyWith(
                                    color: selectedDay
                                        ? AppColors.actionOnPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    if (selected != null) ...[
                      Text(
                        '${selected.dayName} • ${selectedDate!.day} tháng ${selectedDate.month}',
                        style: AppTypography.labelStrong,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      for (
                        var index = 0;
                        index < selected.meals.length;
                        index++
                      ) ...[
                        _MealPlanCard(
                          recipe: selected.meals[index],
                          primary: index == 0,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailsScreen(
                                recipe: selected.meals[index],
                                dayIndex: selected.dayIndex,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                      ],
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        decoration: const BoxDecoration(
                          color: AppColors.bgPeach,
                          borderRadius: AppRadius.rounded12,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ghi chú trong ngày',
                              style: AppTypography.labelStrong,
                            ),
                            SizedBox(height: AppSpacing.s4),
                            Text(
                              'Nhắc bổ sung Omega-3 • luôn hiển thị nguồn món ăn',
                              style: AppTypography.supporting,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: plan.id.isEmpty ? 'Lưu thực đơn' : 'Lưu thay đổi',
                      icon: Icons.arrow_forward,
                      isLoading: vm.saveState is ViewStateLoading<bool>,
                      onPressed: plan.isDraft ? () => _save(context) : null,
                    ),
                    if (vm.saveState is ViewStateError<bool>)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          (vm.saveState as ViewStateError<bool>).message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Xem nguyên liệu',
                      icon: Icons.shopping_cart_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IngredientSummaryScreen(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _shortDay(int dayIndex) =>
      const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][dayIndex.clamp(0, 6)];
}

/// S10: Firestore-backed saved plans; open plan with stable state.
class SavedPlansScreen extends StatefulWidget {
  const SavedPlansScreen({super.key});
  @override
  State<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends State<SavedPlansScreen> {
  void _refresh() {
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid != null) context.read<MealPlanViewModel>().fetchSavedPlans(uid);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealPlanViewModel>();
    return FlowFrame(
      title: 'Thực đơn đã lưu',
      bottomNavigationBar: const _FlowOneNavigation(selectedIndex: 1),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại kế hoạch',
          onPressed: _refresh,
        ),
      ],
      child: FlowStateView<List<MealPlanModel>>(
        state: vm.savedPlansState,
        emptyTitle: 'Chưa có thực đơn đã lưu',
        onRetry: _refresh,
        onBack: () => Navigator.of(context).pop(),
        onData: (plans) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Các tuần đã lưu', style: AppTypography.headingM),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Mở thực đơn trước đây hoặc tạo một thực đơn mới.',
              style: AppTypography.supporting,
            ),
            const SizedBox(height: AppSpacing.s16),
            for (var index = 0; index < plans.length; index++) ...[
              _SavedPlanCard(
                plan: plans[index],
                current: index == 0,
                onTap: () {
                  vm.selectSavedPlan(plans[index]);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              text: 'Tạo thực đơn mới',
              icon: Icons.arrow_forward,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PreferencesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
    child: Text(text, style: AppTypography.labelStrong),
  );
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _ChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.rounded12,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: selected ? AppColors.bgSelected : AppColors.bgSurface,
        border: Border.all(
          color: selected
              ? AppColors.actionPrimary
              : AppColors.borderDecorative,
        ),
        borderRadius: AppRadius.rounded12,
        boxShadow: AppElevation.level1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelStrong),
                const SizedBox(height: AppSpacing.s4),
                Text(subtitle, style: AppTypography.supporting),
              ],
            ),
          ),
          if (selected)
            Text(
              'Đã chọn',
              style: AppTypography.label.copyWith(
                color: AppColors.actionPrimary,
              ),
            ),
        ],
      ),
    ),
  );
}

class _ReadOnlyResult extends StatelessWidget {
  final String title;
  final String value;
  final bool neutral;

  const _ReadOnlyResult({
    required this.title,
    required this.value,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.s12),
    decoration: BoxDecoration(
      color: neutral ? AppColors.bgSurface : AppColors.bgPeach,
      borderRadius: AppRadius.rounded12,
      border: neutral ? Border.all(color: AppColors.borderDecorative) : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelStrong),
        const SizedBox(height: AppSpacing.s4),
        Text(value, style: AppTypography.supporting),
      ],
    ),
  );
}

class _MealPlanCard extends StatelessWidget {
  final RecipeModel recipe;
  final bool primary;
  final VoidCallback onTap;

  const _MealPlanCard({
    required this.recipe,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rounded12,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primary)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: AppSpacing.s12),
                    decoration: const BoxDecoration(
                      color: AppColors.bgSelected,
                      borderRadius: AppRadius.rounded12,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: AppColors.actionPrimary,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.name, style: AppTypography.labelStrong),
                      const SizedBox(height: AppSpacing.s4),
                      if (recipe.sourceNote.isNotEmpty)
                        Text(
                          recipe.sourceNote,
                          style: AppTypography.supporting,
                        ),
                    ],
                  ),
                ),
                Text(
                  primary ? '' : 'Đang chờ',
                  style: AppTypography.supporting,
                ),
              ],
            ),
            if (recipe.isBookCitation) ...[
              const SizedBox(height: AppSpacing.s8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: AppSpacing.s4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.bgSelected,
                      borderRadius: AppRadius.roundedFull,
                    ),
                    child: const Text('Từ sách', style: AppTypography.label),
                  ),
                  const Text('Đang chờ', style: AppTypography.supporting),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SavedPlanCard extends StatelessWidget {
  final MealPlanModel plan;
  final bool current;
  final VoidCallback onTap;

  const _SavedPlanCard({
    required this.plan,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      title: Text(plan.title, style: AppTypography.labelStrong),
      subtitle: Text(
        '${plan.createdAt.toLocal().toString().split(' ').first} • 7 days',
        style: AppTypography.supporting,
      ),
      trailing: Text(
        current ? 'Hiện tại' : 'Đã lưu',
        style: AppTypography.label.copyWith(color: AppColors.actionPrimary),
      ),
      onTap: onTap,
    ),
  );
}

class _FlowOneNavigation extends StatelessWidget {
  final int selectedIndex;
  const _FlowOneNavigation({required this.selectedIndex});

  @override
  Widget build(BuildContext context) => AppNavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      if (index == selectedIndex) return;
      if (index == 0) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (index == 1) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SavedPlansScreen()));
      }
    },
  );
}
