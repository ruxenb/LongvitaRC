import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan_model.dart';
import '../models/view_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/meal_plan_viewmodel.dart';
import '../widgets/app_button.dart';
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
  final _age = TextEditingController();
  final _weight = TextEditingController();
  var _mealsPerDay = 3;
  var _eatingWindow = 12;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowFrame(
    title: 'S02 • Sở thích ăn uống',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowSection(
            title: 'Thông tin để lập thực đơn',
            child: Text(
              'Thực đơn chỉ là gợi ý từ công thức đã lưu trong Firestore, '
              'không thay thế tư vấn dinh dưỡng cá nhân.',
            ),
          ),
          TextFormField(
            controller: _age,
            key: const Key('preferences-age'),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tuổi (18–120)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = int.tryParse(v?.trim() ?? '');
              return value == null || value < 18 || value > 120
                  ? 'Nhập tuổi trong khoảng 18–120'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weight,
            key: const Key('preferences-weight'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cân nặng (kg)',
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: const Key('preferences-meals'),
            initialValue: _mealsPerDay,
            decoration: const InputDecoration(
              labelText: 'Số bữa mỗi ngày',
              border: OutlineInputBorder(),
            ),
            items: [2, 3, 4, 5]
                .map(
                  (n) => DropdownMenuItem(value: n, child: Text('$n bữa/ngày')),
                )
                .toList(),
            onChanged: (v) => setState(() => _mealsPerDay = v ?? 3),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: const Key('preferences-window'),
            initialValue: _eatingWindow,
            decoration: const InputDecoration(
              labelText: 'Khung giờ ăn',
              border: OutlineInputBorder(),
            ),
            items: [10, 11, 12, 13, 14]
                .map((n) => DropdownMenuItem(value: n, child: Text('$n giờ')))
                .toList(),
            onChanged: (v) => setState(() => _eatingWindow = v ?? 12),
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
                    age: int.parse(_age.text.trim()),
                    weightKg: double.parse(
                      _weight.text.trim().replaceAll(',', '.'),
                    ),
                    mealsPerDay: _mealsPerDay,
                    eatingWindowHours: _eatingWindow,
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
  final int age;
  final double weightKg;
  final int mealsPerDay;
  final int eatingWindowHours;

  const CreatePlanScreen({
    super.key,
    required this.uid,
    required this.age,
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
      age: widget.age,
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
      title: 'S03 • Tạo thực đơn',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_started &&
              state is! ViewStateError<MealPlanModel> &&
              state is! ViewStateEmpty<MealPlanModel>) ...[
            FlowSection(
              title: 'Kiểm tra thông tin',
              child: Text(
                'Tuổi: ${widget.age} • Cân nặng: ${widget.weightKg.toStringAsFixed(1)} kg • ${widget.mealsPerDay} bữa/ngày • ${widget.eatingWindowHours} giờ ăn',
              ),
            ),
            AppButton(
              text: 'Tạo kế hoạch',
              icon: Icons.auto_awesome_outlined,
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
class WeeklyPlanScreen extends StatelessWidget {
  const WeeklyPlanScreen({super.key});

  Future<void> _save(BuildContext context) async {
    final vm = context.read<MealPlanViewModel>();
    final ok = await vm.saveActivePlan();
    if (!context.mounted) return;
    flowSnack(
      context,
      ok
          ? 'Đã lưu kế hoạch lên Firestore.'
          : 'Chưa lưu được. Thực đơn trên màn hình vẫn được giữ.',
      actionLabel: ok ? null : 'Thử lại',
      onAction: ok ? null : () => _save(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealPlanViewModel>();
    final plan = vm.activePlan;
    return FlowFrame(
      title: 'S04 • Thực đơn 7 ngày',
      child: plan == null
          ? FlowStateView<MealPlanModel>(
              state: vm.currentPlanState,
              onData: (_) => const Text('Thực đơn đã sẵn sàng.'),
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PreferencesScreen()),
              ),
              onBack: () => Navigator.of(context).pop(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FlowSection(
                  title: plan.title,
                  child: Text(
                    'Mục tiêu tham khảo: ${plan.targetCalories.toStringAsFixed(0)} kcal/ngày; ${plan.targetProteinGrams.toStringAsFixed(0)} g đạm/ngày. Trạng thái: ${plan.status}',
                  ),
                ),
                for (final day in plan.days)
                  Card(
                    child: ExpansionTile(
                      key: Key('weekly-day-${day.dayIndex}'),
                      title: Text(
                        day.dayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '${day.totalCalories.toStringAsFixed(0)} kcal • ${day.totalProtein.toStringAsFixed(1)} g đạm',
                      ),
                      children: [
                        for (var index = 0; index < day.meals.length; index++)
                          FlowItemCard(
                            title: 'Bữa ${index + 1}: ${day.meals[index].name}',
                            subtitle: 'Xem chi tiết, đổi món và nguồn tài liệu',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailsScreen(
                                  recipe: day.meals[index],
                                  dayIndex: day.dayIndex,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                AppButton(
                  text: plan.id.isEmpty ? 'Lưu kế hoạch' : 'Lưu cập nhật',
                  icon: Icons.cloud_upload_outlined,
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
                  text: 'Tổng hợp nguyên liệu',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const IngredientSummaryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Kế hoạch đã lưu',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedPlansScreen()),
                  ),
                ),
              ],
            ),
    );
  }
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
      title: 'S10 • Kế hoạch đã lưu',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại kế hoạch',
          onPressed: _refresh,
        ),
      ],
      child: FlowStateView<List<MealPlanModel>>(
        state: vm.savedPlansState,
        emptyTitle: 'Chưa có kế hoạch',
        onRetry: _refresh,
        onBack: () => Navigator.of(context).pop(),
        onData: (plans) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final plan in plans)
              FlowItemCard(
                title: plan.title,
                subtitle:
                    '${plan.status} • ${plan.createdAt.toLocal().toString().split(' ').first}',
                icon: Icons.calendar_month_outlined,
                onTap: () {
                  vm.selectSavedPlan(plan);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
