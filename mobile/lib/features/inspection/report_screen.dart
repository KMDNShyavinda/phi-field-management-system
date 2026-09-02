import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.pdfPath, required this.inspectionId});

  final String pdfPath;
  final String inspectionId;

  @override
  Widget build(BuildContext context) {
    final file = File(pdfPath);
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Inspection $inspectionId is complete. The PDF is stored on this device and will upload when online.'),
            const SizedBox(height: 8),
            Text(pdfPath, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: file.existsSync()
                  ? () => Printing.layoutPdf(onLayout: (_) => file.readAsBytes())
                  : null,
              child: const Text('Preview / print PDF'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
