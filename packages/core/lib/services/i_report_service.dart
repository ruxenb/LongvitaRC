import 'dart:typed_data';

import 'package:longvita_core/models/meal_plan_model.dart';

abstract class IReportService {
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan);
}
