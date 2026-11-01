import 'dart:typed_data';
import '../models/meal_plan_model.dart';

abstract class IReportService {
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan);
}
