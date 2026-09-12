import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/db/app_database.dart';
import '../../domain/models.dart';

Future<File> buildMonthlyReportPdf({
  required AppDatabase db,
  required SessionUser officer,
  required int year,
  required int month,
}) async {
  final monthStr = month.toString().padLeft(2, '0');
  final monthPrefix = '$year-$monthStr';
  final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
  final generatedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  // 1. Fetch Premises
  final allPremises = await db.all('premises');
  final premisesMap = {for (final p in allPremises) p['id'] as String: p};

  // 2. Fetch Inspections in this month
  final inspections = await db.all(
    'inspections',
    where: "status = 'completed' AND (completed_at LIKE ? OR started_at LIKE ?)",
    args: ['$monthPrefix%', '$monthPrefix%'],
    orderBy: 'completed_at DESC',
  );

  // 3. Fetch Violations in this month
  final inspectionIds = inspections.map((i) => i['id'] as String).toList();
  final allViolations = <Map<String, dynamic>>[];
  for (final id in inspectionIds) {
    final vios = await db.all('violations', where: 'inspection_id = ?', args: [id]);
    allViolations.addAll(vios);
  }

  // 4. Fetch Dengue Cases in this month
  final dengueCases = await db.all(
    'dengue_cases',
    where: 'reported_date LIKE ?',
    args: ['$monthPrefix%'],
    orderBy: 'reported_date DESC',
  );

  // 5. Fetch Complaints in this month
  final complaints = await db.all(
    'complaints',
    where: 'received_date LIKE ?',
    args: ['$monthPrefix%'],
    orderBy: 'received_date DESC',
  );

  // 6. Summary metrics
  final totalPremises = allPremises.length;
  final totalInspections = inspections.length;
  final totalViolations = allViolations.length;
  final totalDengue = dengueCases.length;
  final activeDengue = dengueCases.where((c) => c['status'] == 'active').length;
  final clearedDengue = dengueCases.where((c) => c['status'] == 'cleared').length;
  final totalComplaints = complaints.length;

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // Official Letterhead / Header
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.indigo900)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'MINISTRY OF HEALTH — SRI LANKA',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'OFFICE OF THE MEDICAL OFFICER OF HEALTH (MOH)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'PUBLIC HEALTH INSPECTOR (PHI) MONTHLY PERFORMANCE REPORT',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Officer and Area Info Box
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MOH Area: ${officer.mohArea}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('PHI Officer: ${officer.fullName}'),
                  pw.Text('Email: ${officer.email}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Report Period: $monthName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  pw.Text('Generated On: $generatedDate'),
                  pw.Text('Report Status: Official Record', style: const pw.TextStyle(color: PdfColors.green800)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Executive Summary KPI Box
        pw.Text('1. Executive Performance Summary', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
              children: [
                _buildKpiCell('Total Premises in Area', '$totalPremises'),
                _buildKpiCell('Inspections Completed', '$totalInspections'),
                _buildKpiCell('Improvement Notices', '$totalViolations'),
              ],
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
              children: [
                _buildKpiCell('Total Dengue Cases', '$totalDengue'),
                _buildKpiCell('Active 100m Hotspots', '$activeDengue'),
                _buildKpiCell('Public Complaints', '$totalComplaints'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Section 2: Inspections Conducted
        pw.Text('2. Food & Health Inspections Completed ($totalInspections)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 6),
        if (inspections.isEmpty)
          pw.Text('No inspections recorded for this calendar month.', style: const pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Premise Name', 'Address', 'Status', 'Risk Level'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            data: [
              for (final insp in inspections) ...[
                [
                  (insp['completed_at'] as String? ?? insp['started_at'] as String? ?? '').substring(0, 10),
                  premisesMap[insp['premise_id']]?['name'] as String? ?? 'Unknown Premise',
                  premisesMap[insp['premise_id']]?['address'] as String? ?? '',
                  (insp['status'] as String? ?? '').toUpperCase(),
                  (premisesMap[insp['premise_id']]?['risk'] as String? ?? 'N/A').toUpperCase(),
                ],
              ],
            ],
          ),
        pw.SizedBox(height: 20),

        // Section 3: Violations and Legal Actions
        pw.Text('3. Legal Notices & Offenses Detected ($totalViolations)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 6),
        if (allViolations.isEmpty)
          pw.Text('No statutory violations or legal notices issued during this month.', style: const pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Inspection ID', 'Notice Type', 'Statutory / Legal Provision', 'Deadline'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            data: [
              for (final vio in allViolations) ...[
                [
                  (vio['inspection_id'] as String? ?? '').substring(0, 8),
                  vio['notice_type'] as String? ?? 'Notice',
                  vio['legal_provision'] as String? ?? 'Food Act No. 26 of 1980',
                  vio['deadline'] as String? ?? 'Immediate',
                ],
              ],
            ],
          ),
        pw.SizedBox(height: 20),

        // Section 4: Dengue Surveillance & 100m Hotspot Control
        pw.Text('4. Dengue Surveillance & Hotspot Control ($totalDengue Cases, $clearedDengue Cleared)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 6),
        if (dengueCases.isEmpty)
          pw.Text('No dengue patients or vector hotspots reported in this month.', style: const pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Case ID', 'Patient / Location', 'Reported Date', 'Status', '100m Control Action'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            data: [
              for (final d in dengueCases) ...[
                [
                  d['id'] as String? ?? '',
                  '${d['patient_name'] ?? ''}\n${d['address'] ?? ''}',
                  d['reported_date'] as String? ?? '',
                  (d['status'] as String? ?? '').toUpperCase(),
                  d['action_taken'] as String? ?? '100m inspection pending',
                ],
              ],
            ],
          ),
        pw.SizedBox(height: 20),

        // Section 5: Public Complaints
        pw.Text('5. Public Health Complaints Addressed ($totalComplaints)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 6),
        if (complaints.isEmpty)
          pw.Text('No public health complaints registered for this month.', style: const pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Tracking No', 'Complaint Title', 'Date', 'Priority', 'Status'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            data: [
              for (final c in complaints) ...[
                [
                  c['tracking_no'] as String? ?? c['id'] as String? ?? '',
                  c['title'] as String? ?? '',
                  c['received_date'] as String? ?? '',
                  (c['priority'] as String? ?? '').toUpperCase(),
                  (c['status'] as String? ?? '').toUpperCase(),
                ],
              ],
            ],
          ),
        pw.SizedBox(height: 30),

        // Section 6: Official Sign-off and Declarations
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'I hereby certify that the information provided above is a true and complete record of all public health field duties, food establishment inspections, and disease control activities conducted during this month.',
                style: const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 35),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Public Health Inspector (PHI)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('${officer.fullName} — ${officer.mohArea}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: $generatedDate', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Medical Officer of Health (MOH)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Office Seal & Endorsement', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: .......................................', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final filePath = p.join(dir.path, 'MOH_Monthly_Report_${year}_$monthStr.pdf');
  final file = File(filePath);
  await file.writeAsBytes(await doc.save());
  return file;
}

pw.Widget _buildKpiCell(String title, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 2),
        pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
      ],
    ),
  );
}
