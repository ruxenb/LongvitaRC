// QA host compositions for CHARLIE-UI-01. Each builder mirrors one Figma
// component set or the Responsive QA frame so screenshots can be compared
// side by side with the Figma reference. Copy here is the Figma sample
// copy; it is QA fixture text, not app data.
import 'package:flutter/material.dart';
import 'package:longvita/widgets/longvita_widgets.dart';

import 'qa_support.dart';

/// Canvas-coloured sheet with Figma's component-set padding (24) and
/// spacing (24 horizontal, 32 vertical).
class QaSheet extends StatelessWidget {
  final List<Widget> children;
  final double itemWidth;

  const QaSheet({super.key, required this.children, this.itemWidth = 328});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 32,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        ),
      ),
    );
  }
}

Widget qaButtons() {
  Widget row(AppButtonVariant variant, String text, IconData icon) => Wrap(
        spacing: 24,
        children: [
          SizedBox(
            width: 328,
            child: AppButton(
                text: text, variant: variant, icon: icon, onPressed: () {}),
          ),
          SizedBox(
            width: 328,
            child: AppButton(
                text: text,
                variant: variant,
                icon: icon,
                onPressed: () {},
                debugForcePressed: true),
          ),
          SizedBox(
            width: 328,
            child: AppButton(text: text, variant: variant, icon: icon),
          ),
          SizedBox(
            width: 328,
            child: AppButton(
              text: text,
              loadingText: 'Please wait…',
              variant: variant,
              icon: icon,
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ],
      );

  return Scaffold(
    backgroundColor: AppColors.bgCanvas,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(AppButtonVariant.primary, 'Generate Weekly Plan',
              AppIcons.arrowForward),
          const SizedBox(height: 32),
          row(AppButtonVariant.secondary, 'Shopping List · 24 items',
              AppIcons.shoppingCart),
          const SizedBox(height: 32),
          row(AppButtonVariant.destructive, 'Delete plan',
              AppIcons.deleteOutline),
        ],
      ),
    ),
  );
}

Widget qaTextFields() {
  TextEditingController c(String text) => TextEditingController(text: text);
  return QaSheet(children: [
    const AppTextField(
      label: 'Your weight (kg)',
      hintText: 'Enter weight',
      unit: 'kg',
      helperText: 'Used to personalize your meal plan.',
    ),
    _FocusedField(controller: c('55')),
    AppTextField(
      label: 'Your weight (kg)',
      controller: c('55'),
      unit: 'kg',
      helperText: 'Used to personalize your meal plan.',
    ),
    AppTextField(
      label: 'Your weight (kg)',
      controller: c('-5'),
      unit: 'kg',
      errorText: 'Enter a valid positive number.',
    ),
    const AppTextField(
      label: 'Your weight (kg)',
      hintText: 'Enter weight',
      unit: 'kg',
      helperText: 'Used to personalize your meal plan.',
      enabled: false,
    ),
  ]);
}

class _FocusedField extends StatefulWidget {
  final TextEditingController controller;
  const _FocusedField({required this.controller});

  @override
  State<_FocusedField> createState() => _FocusedFieldState();
}

class _FocusedFieldState extends State<_FocusedField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Your weight (kg)',
      controller: widget.controller,
      focusNode: _focus,
      unit: 'kg',
      helperText: 'Used to personalize your meal plan.',
    );
  }
}

Widget qaCards() => QaSheet(children: [
      AppMealCard(
        title: 'Warm Lentil & Roasted Butternut Squash Salad',
        description: 'Lunch · 12:30 PM',
        image: qaMealPhoto,
        sourceBadge: const AppBadge(kind: AppBadgeKind.fromBook),
        status: 'Pending',
        onTap: () {},
      ),
      AppMealCard(
        title: 'Warm Lentil & Roasted Butternut Squash Salad',
        description: 'Lunch · 12:30 PM',
        image: qaMealPhoto,
        sourceBadge: const AppBadge(kind: AppBadgeKind.fromBook),
        status: 'Pending',
        onTap: () {},
        debugForcePressed: true,
      ),
      AppSummaryCard(
        title: 'Your 7-day rhythm',
        description:
            'Review your plan, explore recipes and prepare your shopping list.',
        note: '7 days · meals planned',
        onTap: () {},
      ),
      AppSummaryCard(
        title: 'Your 7-day rhythm',
        description:
            'Review your plan, explore recipes and prepare your shopping list.',
        note: '7 days · meals planned',
        onTap: () {},
        debugForcePressed: true,
      ),
    ]);

Widget qaNavigation() => QaSheet(itemWidth: 360, children: [
      for (var i = 0; i < 4; i++)
        AppNavigationBar(selectedIndex: i, onDestinationSelected: (_) {}),
    ]);

Widget qaTopBars() => QaSheet(itemWidth: 360, children: [
      AppTopBar(onBack: () {}),
      AppTopBar(
        onBack: () {},
        actions: [
          AppIconButton(
            icon: AppIcons.bookmarkBorder,
            semanticLabel: 'Save',
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ],
      ),
    ]);

/// Dialog bodies rendered inline (no route) so all five kinds fit one shot.
Widget qaDialogs() {
  return Scaffold(
    backgroundColor: AppColors.bgCanvas,
    body: Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final d in <Widget>[
              AppDialog.confirmation(
                title: 'Save this plan?',
                message: 'Keep this weekly plan so you can return to it later.',
                primaryLabel: 'Save plan',
                onPrimary: () {},
                secondaryLabel: 'Keep editing',
                onSecondary: () {},
              ),
              AppDialog.destructive(
                title: 'Delete this plan?',
                message:
                    'This removes the saved plan. You can keep it by choosing Cancel.',
                primaryLabel: 'Delete plan',
                onPrimary: () {},
                secondaryLabel: 'Cancel',
                onSecondary: () {},
              ),
              AppDialog.error(
                title: 'Couldn’t save your plan',
                message:
                    'Your current plan is still here. Check your connection and try again.',
                primaryLabel: 'Try again',
                onPrimary: () {},
                secondaryLabel: 'Cancel',
                onSecondary: () {},
              ),
              AppDialog.edit(
                title: 'Edit ingredient',
                message: 'Adjust the quantity for your shopping list.',
                content: AppTextField(
                  label: 'Quantity',
                  controller: TextEditingController(text: '500'),
                  unit: 'g',
                  helperText: 'Lentils · grams',
                ),
                primaryLabel: 'Save changes',
                onPrimary: () {},
                secondaryLabel: 'Cancel',
                onSecondary: () {},
              ),
              AppDialog.edit(
                title: 'Edit ingredient',
                message: 'Correct the quantity before saving.',
                content: AppTextField(
                  label: 'Quantity',
                  controller: TextEditingController(text: '-5'),
                  unit: 'g',
                  errorText: 'Enter a positive quantity, for example 500.',
                ),
                primaryLabel: 'Save changes',
                secondaryLabel: 'Cancel',
                onSecondary: () {},
              ),
            ])
              SizedBox(width: 360, child: d),
          ],
        ),
      );
    }),
  );
}

Widget qaStates() => QaSheet(children: [
      const LoadingView(
        title: 'Preparing your weekly plan',
        message: 'Finding meals that match your preferences…',
      ),
      const LoadingView(
        style: LoadingViewStyle.skeleton,
        title: 'Preparing your weekly plan',
        message: 'Finding meals that match your preferences…',
      ),
      EmptyView(
        icon: AppIcons.calendarToday,
        title: 'Your week starts here',
        message: 'Create a plan to see your meals and ingredients in one place.',
        actionLabel: 'Create weekly plan',
        onAction: () {},
      ),
      EmptyView(
        icon: AppIcons.shoppingCart,
        title: 'No ingredients yet',
        message: 'Choose a weekly plan to prepare your ingredient summary.',
        actionLabel: 'Return to plan',
        onAction: () {},
      ),
      EmptyView(
        icon: AppIcons.swapHoriz,
        title: 'No alternatives found',
        message: 'Try different preferences, or keep your original meal.',
        actionLabel: 'Review preferences',
        onAction: () {},
      ),
      ErrorView(
        title: 'Couldn’t create your plan',
        message:
            'The connection was interrupted. Your preferences are still saved.',
        onRetry: () {},
        backLabel: 'Go back',
        onBack: () {},
      ),
      ErrorView(
        title: 'Couldn’t save your plan',
        message:
            'Your generated plan is still on screen. Reconnect and try again.',
        onRetry: () {},
        backLabel: 'Go back',
        onBack: () {},
      ),
      ErrorView(
        title: 'Couldn’t replace this meal',
        message: 'Your original meal has been kept. Try the replacement again.',
        onRetry: () {},
        backLabel: 'Go back',
        onBack: () {},
      ),
    ]);

Widget qaSupporting() => Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(spacing: 24, runSpacing: 24, children: [
              AppBadge(kind: AppBadgeKind.fromBook),
              AppBadge(kind: AppBadgeKind.appSuggestion),
              AppBadge(kind: AppBadgeKind.logged),
              AppBadge(kind: AppBadgeKind.pending),
              AppBadge(kind: AppBadgeKind.plantRich),
            ]),
            const SizedBox(height: 32),
            Wrap(spacing: 24, children: [
              AppIconButton(
                  icon: AppIcons.arrowBack,
                  semanticLabel: 'Back',
                  onPressed: () {}),
              AppIconButton(
                  icon: AppIcons.arrowBack,
                  semanticLabel: 'Back',
                  onPressed: () {},
                  debugForcePressed: true),
              const AppIconButton(
                  icon: AppIcons.arrowBack, semanticLabel: 'Back'),
              AppDaySelector(day: 'Mon', date: '14', onTap: () {}),
              AppDaySelector(
                  day: 'Mon', date: '14', selected: true, onTap: () {}),
            ]),
            const SizedBox(height: 32),
            Wrap(spacing: 24, runSpacing: 24, children: [
              SizedBox(
                width: 328,
                child: AppCheckboxRow(
                    label: 'Lentils · 500 g',
                    checked: false,
                    onChanged: (_) {}),
              ),
              SizedBox(
                width: 328,
                child: AppCheckboxRow(
                    label: 'Lentils · 500 g', checked: true, onChanged: (_) {}),
              ),
              const SizedBox(
                width: 328,
                child:
                    AppCheckboxRow(label: 'Lentils · 500 g', checked: false),
              ),
            ]),
            const SizedBox(height: 32),
            Wrap(spacing: 24, runSpacing: 24, children: [
              SizedBox(
                width: 328,
                child: AppSnackBarContent(
                  message: 'Ingredient removed',
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
              ),
              AppQuantityStepper(
                valueLabel: '55 kg',
                onDecrement: () {},
                onIncrement: () {},
              ),
            ]),
          ],
        ),
      ),
    );

/// Mirror of Figma "Longvita / Responsive QA 360–412" viewport (58:717 /
/// 58:770): AppBar, Heading/M, Supporting, Meal card, error TextField,
/// primary Button and Navigation with Plan selected, Vietnamese copy.
Widget qaResponsive() => Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(onBack: () {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Một tuần ăn uống chủ động',
                style: AppTypography.headingM),
            const SizedBox(height: AppSpacing.s16),
            const Text(
              'Từ màn hình Stitch đến những thành phần có thể dùng lại.',
              style: AppTypography.supporting,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppMealCard(
              title: 'Salad đậu lăng và bí đỏ nướng cùng rau xanh',
              description: 'Bữa trưa · 12:30',
              image: qaMealPhoto,
              sourceBadge: const AppBadge(kind: AppBadgeKind.fromBook),
              status: 'Chưa ghi',
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              label: 'Số lượng nguyên liệu',
              controller: TextEditingController(text: '-5'),
              unit: 'g',
              errorText:
                  'Vui lòng nhập số lượng lớn hơn 0 để lưu thay đổi vào danh sách đi chợ.',
            ),
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              text: 'Tạo thực đơn phù hợp cho cả tuần',
              icon: AppIcons.arrowForward,
              onPressed: () {},
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          AppNavigationBar(selectedIndex: 1, onDestinationSelected: (_) {}),
    );
