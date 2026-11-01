import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/meal_plan_model.dart';
import 'i_report_service.dart';

class ReportService implements IReportService {
  @override
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LONGVITA — BAO CAO THUC DON TRUONG THO',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    'Trang thai: ${plan.status.toUpperCase()}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Muc tieu Dam: ${plan.targetProteinGrams.toStringAsFixed(1)} g/ngay'),
                  pw.Text('Muc tieu Calo: ${plan.targetCalories.toStringAsFixed(0)} kcal/ngay'),
                  pw.Text('Ngay tao: ${plan.createdAt.toIso8601String().substring(0, 10)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Thuc don chi tiet 7 ngay (Dr. Valter Longo Protocol):',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...plan.days.map((day) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${day.dayName} (Tong dam: ${day.totalProtein.toStringAsFixed(1)}g | Calo: ${day.totalCalories.toStringAsFixed(0)} kcal)',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                    pw.SizedBox(height: 4),
                    ...day.meals.map(
                      (m) => pw.Bullet(
                        text: '${m.name} (${m.category}) - ${m.proteinGrams}g dam, ${m.calories} kcal',
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              'Ghi chu: Ap dung nguyen tac dinh duong truong tho theo TS. Valter Longo (La dieta della longevita).',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
