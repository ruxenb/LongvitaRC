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
    title: 'Preferences',
    bottomNavigationBar: const _FlowOneNavigation(selectedIndex: 0),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Make the plan fit you', style: AppTypography.headingM),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Only a few inputs are needed. Calculated values stay read-only.',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: AppSpacing.s24),
          const _FieldLabel('Age group'),
          _ChoiceCard(
            title: 'Under 65',
            subtitle: 'Standard protein guidance',
            selected: !_isOlderAdult,
            onTap: () => setState(() => _isOlderAdult = false),
          ),
          const SizedBox(height: AppSpacing.s8),
          _ChoiceCard(
            title: '65 or older',
            subtitle: 'Adjusted guidance from the source',
            selected: _isOlderAdult,
            onTap: () => setState(() => _isOlderAdult = true),
          ),
          const SizedBox(height: AppSpacing.s24),
          const _FieldLabel('Weight and protein'),
          TextFormField(
            controller: _weight,
            key: const Key('preferences-weight'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Your weight (kg)',
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
                  ? 'Enter a valid weight from 25–300 kg'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.s8),
          _ReadOnlyResult(
            title: 'Calculated target',
            value: _isOlderAdult
                ? '55 g protein/day • 1.0 g/kg'
                : '44 g protein/day • 0.8 g/kg',
          ),
          const SizedBox(height: AppSpacing.s24),
          const _FieldLabel('Meals per day'),
          _ChoiceCard(
            key: const Key('preferences-meals-3'),
            title: '3 meals / day',
            subtitle: 'Balanced default',
            selected: _mealsPerDay == 3,
            onTap: () => setState(() => _mealsPerDay = 3),
          ),
          const SizedBox(height: AppSpacing.s8),
          _ChoiceCard(
            key: const Key('preferences-meals-2'),
            title: '2 meals / day',
            subtitle: 'Longer fasting window',
            selected: _mealsPerDay == 2,
            onTap: () => setState(() => _mealsPerDay = 2),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Continue',
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
                    age: _isOlderAdult ? 70 : 55,
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
      title: 'Create plan',
      bottomNavigationBar: const _FlowOneNavigation(selectedIndex: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_started &&
              state is! ViewStateError<MealPlanModel> &&
              state is! ViewStateEmpty<MealPlanModel>) ...[
            Text('Craft your 7-day cycle', style: AppTypography.headingM),
            const SizedBox(height: AppSpacing.s16),
            const _FieldLabel('Essential preferences'),
            const _ChoiceCard(
              title: 'Standard 7-day rhythm',
              subtitle: 'Recommended weekly cycle',
              selected: true,
            ),
            const SizedBox(height: AppSpacing.s8),
            _ChoiceCard(
              title: '${widget.mealsPerDay} meals / day',
              subtitle: 'Meal frequency',
              selected: true,
            ),
            const SizedBox(height: AppSpacing.s8),
            const _ChoiceCard(
              title: 'Plant-rich longevity',
              subtitle: 'Dietary pattern',
              selected: true,
            ),
            const SizedBox(height: AppSpacing.s24),
            const _FieldLabel('Optional nutrient settings'),
            _ReadOnlyResult(
              title: 'Protein target',
              value:
                  '${widget.weightKg.toStringAsFixed(0)} kg • calculated from your profile',
            ),
            const SizedBox(height: AppSpacing.s8),
            const _ChoiceCard(
              title: 'Low-mercury fish',
              subtitle: '2 meals this week',
              selected: false,
            ),
            const SizedBox(height: AppSpacing.s8),
            const _ReadOnlyResult(
              title: '7 days • Plant-rich',
              value: 'Ready to generate your week',
              neutral: true,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              text: 'Generate Weekly Plan',
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
      title: 'Weekly plan',
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your week at a glance',
                      style: AppTypography.headingM,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plan.days.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final day = plan.days[index];
                          final selectedDay = index == _selectedDay;
                          return InkWell(
                            key: Key('weekly-day-${day.dayIndex}'),
                            borderRadius: AppRadius.roundedFull,
                            onTap: () => setState(() => _selectedDay = index),
                            child: Container(
                              width: 42,
                              decoration: BoxDecoration(
                                color: selectedDay
                                    ? AppColors.actionPrimary
                                    : Colors.transparent,
                                borderRadius: AppRadius.roundedFull,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${_shortDay(day.dayName)}\n${19 + index}',
                                textAlign: TextAlign.center,
                                style: AppTypography.label.copyWith(
                                  color: selectedDay
                                      ? AppColors.actionOnPrimary
                                      : AppColors.textPrimary,
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
                        '${selected.dayName} • ${19 + _selectedDay} October',
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
                              'Daily note',
                              style: AppTypography.labelStrong,
                            ),
                            SizedBox(height: AppSpacing.s4),
                            Text(
                              'Omega-3 reminder • keep source labels visible',
                              style: AppTypography.supporting,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: plan.id.isEmpty ? 'Save Plan' : 'Save Changes',
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
                      text: 'View Ingredients',
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

  String _shortDay(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('hai')) return 'Mon';
    if (normalized.contains('ba')) return 'Tue';
    if (normalized.contains('tư')) return 'Wed';
    if (normalized.contains('năm')) return 'Thu';
    if (normalized.contains('sáu')) return 'Fri';
    if (normalized.contains('bảy')) return 'Sat';
    return 'Sun';
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
      title: 'Saved plans',
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
        emptyTitle: 'No saved plans yet',
        onRetry: _refresh,
        onBack: () => Navigator.of(context).pop(),
        onData: (plans) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your saved weeks', style: AppTypography.headingM),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Open a previous plan or start fresh.',
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
              text: 'Create New Plan',
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
              'Selected',
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
                      Text(
                        primary ? 'Lunch • 12:30 PM' : 'Dinner • 6:45 PM',
                        style: AppTypography.supporting,
                      ),
                    ],
                  ),
                ),
                Text(primary ? '' : 'Pending', style: AppTypography.supporting),
              ],
            ),
            if (primary) ...[
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
                    child: const Text('From Book', style: AppTypography.label),
                  ),
                  const Text('Pending', style: AppTypography.supporting),
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
        current ? 'Current' : 'Saved',
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
