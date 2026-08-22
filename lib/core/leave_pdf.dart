import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class LeavePdf {
  static String _date(dynamic value) {
    final d = DateTime.tryParse('${value ?? ''}');
    return d == null ? '-' : DateFormat('dd.MM.yyyy').format(d);
  }

  static String _days(dynamic value) {
    final n = double.tryParse('$value') ?? 0;
    return n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(1).replaceAll('.', ',');
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> leave,
    required Map<String, dynamic> employee,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Expanded(child: pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.Text('YILLIK IZIN FORMU', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 18),
            _row('Personel', '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'),
            _row('Sicil / Personel No', '${employee['employee_no'] ?? '-'}'),
            _row('Departman / Gorev', '${employee['department'] ?? '-'} / ${employee['position'] ?? '-'}'),
            _row('Ise Giris Tarihi', _date(employee['start_date'])),
            _row('Izin Baslangic', _date(leave['start_date'])),
            _row('Izin Bitis', _date(leave['end_date'])),
            _row('Izin Suresi', '${_days(leave['day_count'])} gun'),
            _row('Aciklama', '${leave['description'] ?? '-'}'),
            pw.SizedBox(height: 28),
            pw.Text(
              'Yukarida bilgileri bulunan personelin belirtilen tarihler arasinda yillik ucretli izin kullanmasi kayit altina alinmistir.',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Container(
                width: 180,
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
                child: pw.Column(children: [
                  pw.Text('Personel', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'),
                  pw.SizedBox(height: 22),
                  pw.Text('Imza', style: const pw.TextStyle(fontSize: 9)),
                ]),
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Divider(),
            pw.Center(child: pw.Text('MleySoft IK Yonetim Sistemi', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static pw.Widget _row(String label, String value) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: .5)),
        child: pw.Row(children: [
          pw.Container(width: 135, color: PdfColors.grey200, padding: const pw.EdgeInsets.all(8), child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)))),
        ]),
      );

  static Future<void> printLeave({required Map<String, dynamic> leave, required Map<String, dynamic> employee, required String companyName}) async {
    final bytes = await build(leave: leave, employee: employee, companyName: companyName);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Yillik Izin - ${employee['first_name']} ${employee['last_name']}');
  }

  static Future<void> shareLeave({required Map<String, dynamic> leave, required Map<String, dynamic> employee, required String companyName}) async {
    final bytes = await build(leave: leave, employee: employee, companyName: companyName);
    await Printing.sharePdf(bytes: bytes, filename: 'yillik-izin-${employee['employee_no'] ?? 'personel'}.pdf');
  }
}
