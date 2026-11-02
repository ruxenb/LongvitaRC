import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/meal_plan_model.dart';
import 'i_report_service.dart';

/// Static TTFs with Vietnamese glyphs. The pdf package reads only the default
/// instance of a variable font, so the app's UI fonts cannot give regular and
/// bold here, and Flutter UI fonts do not apply to `pw.Document` anyway.
const String pdfRegularFontAsset = 'assets/fonts/Roboto-Regular.ttf';
const String pdfBoldFontAsset = 'assets/fonts/Roboto-Bold.ttf';

class ReportService implements IReportService {
  final Future<ByteData> Function(String asset) _loadAsset;
  pw.ThemeData? _theme;

  ReportService({Future<ByteData> Function(String asset)? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.load;

  Future<pw.ThemeData> _loadTheme() async => _theme ??= pw.ThemeData.withFont(
        base: pw.Font.ttf(await _loadAsset(pdfRegularFontAsset)),
        bold: pw.Font.ttf(await _loadAsset(pdfBoldFontAsset)),
      );

  static String _statusLabel(String status) => switch (status) {
        'draft' => 'Bản nháp',
        'submitted' => 'Đã gửi duyệt',
        'approved' => 'Đã duyệt',
        'rejected' => 'Bị từ chối',
        _ => status,
      };

  @override
  Future<Uint8List> generateMealPlanPdf(MealPlanModel plan) async {
    final pdf = pw.Document();
    final theme = await _loadTheme();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'LONGVITA — BÁO CÁO THỰC ĐƠN TRƯỜNG THỌ',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    'Trạng thái: ${_statusLabel(plan.status)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              plan.title,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
                  pw.Text('Mục tiêu đạm: ${plan.targetProteinGrams.toStringAsFixed(1)} g/ngày'),
                  pw.Text('Mục tiêu calo: ${plan.targetCalories.toStringAsFixed(0)} kcal/ngày'),
                  pw.Text('Ngày tạo: ${plan.createdAt.toIso8601String().substring(0, 10)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Thực đơn chi tiết theo nguyên tắc của TS. Valter Longo:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...plan.days.map((day) {
              // Keeps a day together when it does not fit on the current page.
              return pw.Inseparable(
                child: pw.Container(
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
                        '${day.dayName} (Tổng đạm: ${day.totalProtein.toStringAsFixed(1)} g | Calo: ${day.totalCalories.toStringAsFixed(0)} kcal)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                      ),
                      pw.SizedBox(height: 4),
                      ...day.meals.map(
                        (m) => pw.Bullet(
                          text: '${m.name}: ${m.proteinGrams.toStringAsFixed(1)} g đạm, ${m.calories.toStringAsFixed(0)} kcal',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              'Ghi chú: Áp dụng nguyên tắc dinh dưỡng trường thọ theo TS. Valter Longo (La dieta della longevità).',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
