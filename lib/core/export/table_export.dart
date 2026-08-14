import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart';

/// Shared CSV/PDF export for every admin report (boss batch 08/08 points 4, 10
/// and 13). Give it the column headers and the rows, it produces a file the
/// browser downloads (web) or the OS share sheet receives (mobile).
class TableExport {
  /// RFC-4180 quoting: wrap in quotes and double any embedded quote, so
  /// commas, quotes and newlines inside a cell can never break the file.
  static String _csvCell(String v) => '"${v.replaceAll('"', '""')}"';

  static Future<void> csv({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final buffer = StringBuffer()
      ..writeln(headers.map(_csvCell).join(','));
    for (final r in rows) {
      buffer.writeln(r.map(_csvCell).join(','));
    }
    // BOM so Excel opens UTF-8 (RM sign, accents) correctly.
    final bytes = Uint8List.fromList([
      0xEF, 0xBB, 0xBF,
      ...utf8.encode(buffer.toString()),
    ]);
    await saveBytes(bytes, '$filename.csv', 'text/csv');
  }

  static Future<void> pdf({
    required String filename,
    required String title,
    String? subtitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final doc = pw.Document();
    final printed =
        DateFormat('d MMM yyyy • HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (subtitle != null && subtitle.isNotEmpty)
              pw.Text(subtitle,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text('Generated $printed  •  ${rows.length} rows',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
            pw.Divider(thickness: 0.6),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4, vertical: 3),
            border: pw.TableBorder.all(
                color: PdfColors.grey400, width: 0.4),
          ),
        ],
      ),
    );

    await saveBytes(
      await doc.save(),
      '$filename.pdf',
      'application/pdf',
    );
  }
}
