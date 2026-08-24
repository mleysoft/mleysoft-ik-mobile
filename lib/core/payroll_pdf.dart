import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PayrollPdf {
  static String _money(dynamic v) {
    final n = double.tryParse('$v') ?? 0;
    return '${n.toStringAsFixed(2)} TL';
  }

  static String _num(dynamic v) {
    final n = double.tryParse('$v') ?? 0;
    return n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(1);
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> period,
    required List items,
  }) async {
    final pdf = pw.Document();
    for (final raw in items) {
      final x = Map<String, dynamic>.from(raw as Map);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(26),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${period['business_unit_name'] ?? 'Firma'}', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 3),
                        pw.Text('MleySoft IK Yonetim Sistemi', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('UCRET BORDROSU', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${period['period_month']}.${period['period_year']}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.4),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
                children: [
                  pw.TableRow(children: [
                    _meta('Personel', '${x['first_name'] ?? ''} ${x['last_name'] ?? ''}'),
                    _meta('Sicil No', '${x['employee_no'] ?? '-'}'),
                    _meta('Departman', '${x['department'] ?? '-'}'),
                    _meta('Gorev', '${x['position'] ?? '-'}'),
                  ])
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('CALISMA VE IZIN OZETI', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: ['Geldi','Hafta Tatili','Yillik Izin','Ucretli Izin','Ucretsiz Izin','Rapor','Gelmedi','Hesaplanan','Takvim','Gec Kalma','Erken Cikis','Fazla Mesai']
                        .map((v) => _cell(v, bold: true)).toList(),
                  ),
                  pw.TableRow(children: [
                    _cell(_num(x['present_days'])),
                    _cell(_num(x['weekly_off_days'])),
                    _cell(_num(x['annual_leave_days'])),
                    _cell(_num(x['paid_leave_days'])),
                    _cell(_num(x['unpaid_leave_days'])),
                    _cell(_num(x['sick_days'])),
                    _cell(_num(x['absent_days'])),
                    _cell(_num(x['calculated_days'])),
                    _cell('${x['calendar_days'] ?? 0}'),
                    _cell('${x['late_minutes'] ?? 0} dk'),
                    _cell('${x['early_leave_minutes'] ?? 0} dk'),
                    _cell('${x['overtime_minutes'] ?? 0} dk'),
                  ]),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(children: [
                pw.Expanded(child: _moneyBox('Aylik Maas', _money(x['monthly_salary']))),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _moneyBox('Donem Hakedisi', _money(x['gross_salary']))),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _moneyBox('Avans / Taksit', '- ${_money(x['advance_total'])}')),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _moneyBox('NET ODENECEK', _money(x['net_salary']), strong: true)),
              ]),
              pw.Spacer(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
                _sign('Hazirlayan / IK'),
                _sign('Isveren / Yetkili'),
                _sign('Personel / Imza'),
              ]),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('MleySoft IK Yonetim Sistemi', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700))),
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }

  static pw.Widget _meta(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    ]),
  );

  static pw.Widget _cell(String value, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
    child: pw.Text(value, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.3, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
  );

  static pw.Widget _moneyBox(String label, String value, {bool strong = false}) => pw.Container(
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), color: strong ? PdfColors.grey200 : PdfColors.white),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
      pw.SizedBox(height: 4),
      pw.Text(value, style: pw.TextStyle(fontSize: strong ? 13 : 11, fontWeight: pw.FontWeight.bold)),
    ]),
  );

  static pw.Widget _sign(String text) => pw.Container(
    width: 150,
    padding: const pw.EdgeInsets.only(top: 5),
    decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
    child: pw.Text(text, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
  );

  static Future<void> share({required Map<String, dynamic> period, required List items}) async {
    final bytes = await build(period: period, items: items);
    final file = 'bordrolar-${period['business_unit_name'] ?? 'firma'}-${period['period_year']}-${period['period_month']}.pdf'.replaceAll(' ', '-');
    await Printing.sharePdf(bytes: bytes, filename: file);
  }
}
