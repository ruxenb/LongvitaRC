import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_admin/admin/admin_app.dart';
import 'package:longvita_admin/admin/admin_auth.dart';
import 'package:longvita_core/services/admin_service.dart';
import 'package:longvita_admin/admin/admin_viewmodels.dart';
import 'package:longvita_admin/admin/dashboard_screen.dart';
import 'package:longvita_admin/admin/recipe_management_screen.dart';
import 'package:longvita_admin/admin/review_queue_screen.dart';
import 'package:longvita_core/models/review_queue_item.dart';
import 'package:longvita_core/models/ingredient_model.dart';
import 'package:longvita_core/models/meal_plan_model.dart';
import 'package:longvita_core/models/recipe_model.dart';
import 'package:provider/provider.dart';

class FakeAdminService implements IAdminService {
  final recipes = StreamController<List<RecipeModel>>.broadcast();
  final plans = StreamController<List<ReviewQueueItem>>.broadcast();
  final saved = <RecipeModel>[];
  final archived = <(String, bool)>[];
  final reviewed = <(String, String, String?)>[];
  AdminDashboardMetrics metrics = const AdminDashboardMetrics(
    activeRecipes: 0,
    submittedPlans: 0,
    approvedPlans: 0,
  );
  Object? failure;

  @override
  Stream<List<RecipeModel>> watchRecipes() => recipes.stream;
  @override
  Stream<List<ReviewQueueItem>> watchSubmittedPlans() => plans.stream;
  @override
  Future<void> saveRecipe(RecipeModel recipe) async => saved.add(recipe);
  @override
  Future<void> setRecipeArchived(String id, bool value) async {
    if (failure != null) throw failure!;
    archived.add((id, value));
  }

  @override
  Future<void> reviewPlan(String id, String status, {String? reason}) async {
    if (failure != null) throw failure!;
    reviewed.add((id, status, reason));
  }

  @override
  Future<AdminDashboardMetrics> loadMetrics() async {
    if (failure != null) throw failure!;
    return metrics;
  }
}

RecipeModel recipe({bool archived = false}) => RecipeModel(
  id: 'r1',
  name: 'Món mẫu',
  description: 'Mô tả',
  category: 'rau_cu',
  proteinGrams: 12,
  calories: 200,
  ingredients: const [
    IngredientModel(
      id: 'i1',
      name: 'Đậu',
      amount: 2.5,
      unit: 'cốc',
      category: 'dau',
    ),
  ],
  instructions: const ['Nấu'],
  imageUrl: 'https://example.test/image.png',
  sourceNote: '[web] test',
  isArchived: archived,
);

MealPlanModel plan() => MealPlanModel(
  id: 'p1',
  uid: 'u1',
  title: 'Thực đơn mẫu',
  targetCalories: 1800,
  targetProteinGrams: 60,
  status: 'submitted',
  days: List.generate(
    7,
    (index) =>
        DailyMeal(dayIndex: index, dayName: 'Ngày $index', meals: [recipe()]),
  ),
  createdAt: DateTime(2026, 11, 9),
);

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  test('admin role lookup is shared and cached until sign-out', () async {
    final cache = AdminRoleCache();
    final response = Completer<String?>();
    var loads = 0;
    Future<String?> loader() {
      loads++;
      return response.future;
    }

    final first = cache.load('u1', loader);
    final duplicate = cache.load('u1', loader);
    expect(loads, 1);
    response.complete('staff');
    expect(await first, 'staff');
    expect(await duplicate, 'staff');
    expect(await cache.load('u1', () async => 'admin'), 'staff');

    cache.clear();
    expect(await cache.load('u1', () async => 'admin'), 'admin');
  });

  test('role cache ignores a response from before clear', () async {
    final cache = AdminRoleCache();
    final oldResponse = Completer<String?>();

    final oldLoad = cache.load('u1', () => oldResponse.future);
    cache.clear();
    oldResponse.complete('admin');
    expect(await oldLoad, 'admin');

    var freshLoads = 0;
    expect(
      await cache.load('u1', () async {
        freshLoads++;
        return 'staff';
      }),
      'staff',
    );
    expect(freshLoads, 1);
  });

  test('old role request cannot overwrite or remove the new request', () async {
    final cache = AdminRoleCache();
    final oldResponse = Completer<String?>();
    final newResponse = Completer<String?>();

    final oldLoad = cache.load('u1', () => oldResponse.future);
    cache.clear();
    final newLoad = cache.load('u1', () => newResponse.future);
    final sharedNewLoad = cache.load('u1', () async => 'user');

    oldResponse.complete('admin');
    expect(await oldLoad, 'admin');
    expect(identical(newLoad, sharedNewLoad), isTrue);

    newResponse.complete('staff');
    expect(await newLoad, 'staff');
    expect(await cache.load('u1', () async => 'admin'), 'staff');
  });

  test('admin auth errors are safe and friendly', () {
    expect(
      friendlyAdminAuthError(
        FirebaseAuthException(code: 'popup-closed-by-user'),
      ),
      contains('hủy đăng nhập'),
    );
    expect(
      friendlyAdminAuthError(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
      contains('kiểm tra mạng'),
    );
    expect(
      friendlyAdminAuthError(Exception('secret')),
      isNot(contains('secret')),
    );
  });

  testWidgets('role gate covers loading, denied and authorized', (
    tester,
  ) async {
    final pending = Completer<String?>();
    await tester.pumpWidget(
      app(
        AdminRoleGate(
          role: pending.future,
          onDenied: () {},
          authorizedBuilder: (role) => Text('authorized:$role'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete('staff');
    await tester.pump();
    expect(find.text('authorized:staff'), findsOneWidget);

    await tester.pumpWidget(
      app(
        AdminRoleGate(
          // Production role lookup maps every non-staff/admin role to null.
          role: Future.value(null),
          onDenied: () {},
          authorizedBuilder: (_) => const Text('authorized'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản không có quyền'), findsOneWidget);
  });

  testWidgets('role gate reloads the same UID after logout', (tester) async {
    final cache = AdminRoleCache();
    final oldResponse = Completer<String?>();

    await tester.pumpWidget(
      app(
        AdminRoleGate(
          role: cache.load('u1', () => oldResponse.future),
          onDenied: () {},
          authorizedBuilder: (role) => Text('authorized:$role'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    cache.clear();
    final newResponse = Completer<String?>();
    await tester.pumpWidget(
      app(
        AdminRoleGate(
          role: cache.load('u1', () => newResponse.future),
          onDenied: () {},
          authorizedBuilder: (role) => Text('authorized:$role'),
        ),
      ),
    );
    oldResponse.complete('staff');
    await tester.pump();
    expect(find.text('authorized:staff'), findsNothing);

    newResponse.complete('admin');
    await tester.pump();
    expect(find.text('authorized:admin'), findsOneWidget);
  });

  test('recipe edit preserves structured ingredients and image', () {
    final original = recipe();
    final edited = editableRecipe(
      id: original.id,
      name: original.name,
      description: 'Mô tả mới',
      category: original.category,
      calories: original.calories,
      protein: original.proteinGrams,
      ingredients: 'Đậu',
      instructions: 'Nấu',
      existingIngredients: original.ingredients,
      imageUrl: original.imageUrl,
    );
    expect(edited.ingredients.single.amount, 2.5);
    expect(edited.ingredients.single.unit, 'cốc');
    expect(edited.ingredients.single.category, 'dau');
    expect(edited.imageUrl, original.imageUrl);
  });

  testWidgets('recipe create and archive actions call the service', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeAdminService();
    final vm = RecipeAdminViewModel(service);
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: vm)],
        child: app(const RecipeManagementScreen()),
      ),
    );
    await tester.pump();
    service.recipes.add([recipe()]);
    await tester.pump();
    await tester.tap(find.byTooltip('Lưu trữ'));
    await tester.pump();
    expect(service.archived, [('r1', true)]);
    await vm.save(recipe());
    expect(service.saved, hasLength(1));
  });

  testWidgets('recipe screen uses compact cards without overflow at 412px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeAdminService();
    final vm = RecipeAdminViewModel(service);
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: vm)],
        child: app(const RecipeManagementScreen()),
      ),
    );
    await tester.pump();
    service.recipes.add([recipe()]);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('recipe-compact-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-desktop-table')), findsNothing);
    expect(find.text('Món mẫu'), findsOneWidget);
    expect(find.textContaining('kcal'), findsOneWidget);
    expect(find.byTooltip('Chỉnh sửa'), findsOneWidget);
    expect(find.byTooltip('Lưu trữ'), findsOneWidget);
  });

  testWidgets('review queue approves and rejects with reason', (tester) async {
    final service = FakeAdminService();
    final events = <String>[];
    final vm = ReviewQueueViewModel(
      service,
      trackSuccessfulReview: (status) async => events.add(status),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: app(const ReviewQueueScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Hướng dẫn xét duyệt đang bật'), findsOneWidget);
    service.plans.add([ReviewQueueItem.fromMap(plan().toMap(), 'p1')]);
    await tester.pump();
    await tester.tap(find.text('Duyệt'));
    await tester.pump();
    expect(service.reviewed, contains(('p1', 'approved', null)));
    await tester.tap(find.text('Từ chối'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Thiếu dữ liệu');
    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pumpAndSettle();
    expect(service.reviewed, contains(('p1', 'rejected', 'Thiếu dữ liệu')));
    expect(events, ['approved', 'rejected']);
  });

  testWidgets('reject dialog validates empty and oversized reasons', (
    tester,
  ) async {
    final service = FakeAdminService();
    final vm = ReviewQueueViewModel(service);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: app(const ReviewQueueScreen()),
      ),
    );
    await tester.pump();
    service.plans.add([ReviewQueueItem.fromMap(plan().toMap(), 'p1')]);
    await tester.pump();
    await tester.tap(find.text('Từ chối'));
    await tester.pump();

    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pump();
    expect(find.text('Vui lòng nhập lý do từ chối.'), findsOneWidget);
    expect(find.text('Từ chối thực đơn'), findsOneWidget);
    expect(service.reviewed, isEmpty);

    final oversized = 'a' * 501;
    await tester.enterText(find.byType(TextField), oversized);
    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pump();
    expect(find.text('Lý do không được vượt quá 500 ký tự.'), findsOneWidget);
    expect(find.text('Từ chối thực đơn'), findsOneWidget);
    expect(find.text(oversized), findsOneWidget);
    expect(service.reviewed, isEmpty);

    await tester.enterText(find.byType(TextField), 'Đã bổ sung đủ dữ liệu');
    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pumpAndSettle();
    expect(service.reviewed, [('p1', 'rejected', 'Đã bổ sung đủ dữ liệu')]);
  });

  testWidgets('reject dialog accepts a 500-character reason', (tester) async {
    final service = FakeAdminService();
    final vm = ReviewQueueViewModel(service);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: app(const ReviewQueueScreen()),
      ),
    );
    await tester.pump();
    service.plans.add([ReviewQueueItem.fromMap(plan().toMap(), 'p1')]);
    await tester.pump();
    await tester.tap(find.text('Từ chối'));
    await tester.pump();

    final boundaryReason = 'a' * 500;
    await tester.enterText(find.byType(TextField), boundaryReason);
    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pumpAndSettle();
    expect(service.reviewed, [('p1', 'rejected', boundaryReason)]);
  });

  test('failed review does not emit an Analytics event', () async {
    final service = FakeAdminService()..failure = StateError('denied');
    final events = <String>[];
    final vm = ReviewQueueViewModel(
      service,
      trackSuccessfulReview: (status) async => events.add(status),
    );
    final item = ReviewQueueItem.fromMap(plan().toMap(), 'p1');

    await expectLater(vm.review(item, 'approved'), throwsStateError);
    expect(events, isEmpty);
    vm.dispose();
  });

  test('recipe retry immediately publishes its loading state', () {
    final service = FakeAdminService();
    final vm = RecipeAdminViewModel(service)
      ..state = AdminLoadState.error
      ..error = 'offline';
    var notifications = 0;
    vm.addListener(() => notifications++);

    vm.start();

    expect(vm.state, AdminLoadState.loading);
    expect(vm.error, isNull);
    expect(notifications, 1);
    vm.dispose();
  });

  test('review retry immediately publishes its loading state', () {
    final service = FakeAdminService();
    final vm = ReviewQueueViewModel(service)
      ..state = AdminLoadState.error
      ..error = 'offline';
    var notifications = 0;
    vm.addListener(() => notifications++);

    vm.start();

    expect(vm.state, AdminLoadState.loading);
    expect(vm.error, isNull);
    expect(notifications, 1);
    vm.dispose();
  });

  testWidgets('dashboard covers loading, empty, error and data', (
    tester,
  ) async {
    final service = FakeAdminService();
    final vm = DashboardViewModel(service);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: app(const DashboardScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Chưa có số liệu'), findsOneWidget);

    service.failure = StateError('offline');
    await vm.load();
    await tester.pump();
    expect(find.text('Không tải được dữ liệu'), findsOneWidget);

    service.failure = null;
    service.metrics = const AdminDashboardMetrics(
      activeRecipes: 4,
      submittedPlans: 2,
      approvedPlans: 3,
    );
    await vm.load();
    await tester.pump();
    expect(find.text('Công thức hoạt động'), findsWidgets);
    expect(find.text('4'), findsWidgets);
  });
}
