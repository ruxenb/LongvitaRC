import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/recipe_model.dart';
import 'admin_service.dart';
import 'review_queue_item.dart';

enum AdminLoadState { loading, ready, empty, error }

abstract class _AdminViewModel extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class RecipeAdminViewModel extends _AdminViewModel {
  final IAdminService service;
  StreamSubscription<List<RecipeModel>>? _subscription;
  List<RecipeModel> _all = const [];
  String query = '';
  AdminLoadState state = AdminLoadState.loading;
  String? error;
  bool saving = false;

  RecipeAdminViewModel(this.service);

  List<RecipeModel> get recipes {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return _all;
    return _all
        .where(
          (row) =>
              row.name.toLowerCase().contains(term) ||
              row.category.toLowerCase().contains(term),
        )
        .toList(growable: false);
  }

  void start() {
    state = AdminLoadState.loading;
    _subscription?.cancel();
    _subscription = service.watchRecipes().listen(
      (rows) {
        _all = rows;
        state = rows.isEmpty ? AdminLoadState.empty : AdminLoadState.ready;
        error = null;
        notifyListeners();
      },
      onError: (Object value) {
        state = AdminLoadState.error;
        error = value.toString();
        notifyListeners();
      },
    );
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> save(RecipeModel recipe) async {
    saving = true;
    notifyListeners();
    try {
      await service.saveRecipe(recipe);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> archive(RecipeModel recipe) =>
      service.setRecipeArchived(recipe.id, !recipe.isArchived);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class ReviewQueueViewModel extends _AdminViewModel {
  final IAdminService service;
  StreamSubscription<List<ReviewQueueItem>>? _subscription;
  List<ReviewQueueItem> plans = const [];
  AdminLoadState state = AdminLoadState.loading;
  String? error;
  String? processingId;

  ReviewQueueViewModel(this.service);

  void start() {
    state = AdminLoadState.loading;
    _subscription?.cancel();
    _subscription = service.watchSubmittedPlans().listen(
      (rows) {
        plans = rows;
        state = rows.isEmpty ? AdminLoadState.empty : AdminLoadState.ready;
        error = null;
        notifyListeners();
      },
      onError: (Object value) {
        state = AdminLoadState.error;
        error = value.toString();
        notifyListeners();
      },
    );
  }

  Future<void> review(
    ReviewQueueItem plan,
    String status, {
    String? reason,
  }) async {
    if (status == 'approved' && !plan.canApprove) {
      throw StateError('Không thể duyệt thực đơn có dữ liệu lỗi.');
    }
    processingId = plan.id;
    notifyListeners();
    try {
      await service.reviewPlan(plan.id, status, reason: reason);
    } finally {
      processingId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class DashboardViewModel extends _AdminViewModel {
  final IAdminService service;
  AdminLoadState state = AdminLoadState.loading;
  AdminDashboardMetrics? metrics;
  String? error;

  DashboardViewModel(this.service);

  Future<void> load() async {
    state = AdminLoadState.loading;
    error = null;
    notifyListeners();
    try {
      metrics = await service.loadMetrics();
      final value = metrics!;
      state =
          value.activeRecipes == 0 &&
              value.submittedPlans == 0 &&
              value.approvedPlans == 0
          ? AdminLoadState.empty
          : AdminLoadState.ready;
    } catch (value) {
      state = AdminLoadState.error;
      error = value.toString();
    }
    notifyListeners();
  }
}
