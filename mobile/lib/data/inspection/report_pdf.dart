import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';
import '../db/app_database.dart';

Future<File> buildInspectionPdf({
  required AppDatabase db,
  required Map<String, dynamic> inspection,
  required Premise premise,
  required SessionUser officer,
}) async {
  final items = await db.all('checklist_items', orderBy: 'sort_order');
  final answers = {
    for (final row in await db.all('inspection_answers', where: 'inspection_id = ?', args: [inspection['id']]))
      row['item_id']: row,
  };
  final photos = await db.all('evidence_photos', where: 'inspection_id = ?', args: [inspection['id']]);
  final violations = await db.all('violations', where: 'inspection_id = ?', args: [inspection['id']]);
  final signatures = await db.all('signatures', where: 'inspection_id = ?', args: [inspection['id']]);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('PHI Inspection Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text('Medical Officer of Health — Field inspection under the Food Act No. 26 of 1980'),
        pw.SizedBox(height: 12),
        pw.Text('Inspection ID: ${inspection['id']}'),
        pw.Text('Officer: ${officer.fullName} (${officer.email})'),
        pw.Text('MOH area: ${officer.mohArea}'),
        pw.Text('Premises: ${premise.name}'),
        pw.Text('Address: ${premise.address}'),
        pw.Text('Owner: ${premise.ownerName}'),
        pw.Text('QR: ${premise.qrCode}'),
        pw.Text('Started: ${inspection['started_at']}'),
        pw.Text('Completed: ${inspection['completed_at'] ?? ''}'),
        pw.Text(
          'GPS start: ${inspection['start_lat']}, ${inspection['start_lng']} (${inspection['gps_status']})',
        ),
        pw.Text('GPS submit: ${inspection['submit_lat']}, ${inspection['submit_lng']}'),
        pw.SizedBox(height: 16),
        pw.Text('Checklist', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: const ['Item', 'Result', 'Notes'],
          data: [
            for (final item in items)
              [
                item['title'],
                (answers[item['id']]?['result'] ?? 'n/a').toString().toUpperCase(),
                answers[item['id']]?['notes'] ?? '',
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Violations / notices', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        if (violations.isEmpty) pw.Text('No failed items recorded.'),
        for (final row in violations)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              '${row['notice_type']} — deadline ${row['deadline']}\n${row['legal_provision']}',
            ),
          ),
        pw.SizedBox(height: 16),
        pw.Text('Evidence photos', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        for (final photo in photos)
          pw.Text(
            '${photo['id']}  SHA-256 ${photo['sha256']}\nCaptured ${photo['captured_at']} @ ${photo['latitude']}, ${photo['longitude']}',
          ),
        pw.SizedBox(height: 16),
        pw.Text('Signatures', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Row(
          children: [
            for (final signature in signatures)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text('${signature['signer_role']} — ${signature['signer_name']}'),
                    if (signature['image_path'] != null && File(signature['image_path'] as String).existsSync())
                      pw.Image(
                        pw.MemoryImage(File(signature['image_path'] as String).readAsBytesSync()),
                        height: 80,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final reports = Directory(p.join(dir.path, 'reports'));
  await reports.create(recursive: true);
  final file = File(p.join(reports.path, '${inspection['id']}.pdf'));
  await file.writeAsBytes(await doc.save(), flush: true);
  return file;
}
