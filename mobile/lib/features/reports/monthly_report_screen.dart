import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'monthly_report_pdf.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  DateTime _selectedPeriod = DateTime(DateTime.now().year, DateTime.now().month);
  bool _generating = false;
  bool _loadingStats = true;

  int _inspectionsCount = 0;
  int _violationsCount = 0;
  int _dengueCount = 0;
  int _complaintsCount = 0;
  int _premisesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPeriodStats();
  }

  Future<void> _loadPeriodStats() async {
    setState(() => _loadingStats = true);
    final db = ref.read(dbProvider);
    final year = _selectedPeriod.year;
    final month = _selectedPeriod.month;
    final monthStr = month.toString().padLeft(2, '0');
    final monthPrefix = '$year-$monthStr';

    final premises = await db.all('premises');
    final inspections = await db.all(
      'inspections',
      where: "status = 'completed' AND (completed_at LIKE ? OR started_at LIKE ?)",
      args: ['$monthPrefix%', '$monthPrefix%'],
    );

    int viosCount = 0;
    for (final insp in inspections) {
      final vios = await db.all('violations', where: 'inspection_id = ?', args: [insp['id']]);
      viosCount += vios.length;
    }

    final dengue = await db.all(
      'dengue_cases',
      where: 'reported_date LIKE ?',
      args: ['$monthPrefix%'],
    );

    final complaints = await db.all(
      'complaints',
      where: 'received_date LIKE ?',
      args: ['$monthPrefix%'],
    );

    setState(() {
      _premisesCount = premises.length;
      _inspectionsCount = inspections.length;
      _violationsCount = viosCount;
      _dengueCount = dengue.length;
      _complaintsCount = complaints.length;
      _loadingStats = false;
    });
  }

  Future<void> _generateAndPreviewPdf() async {
    final officer = ref.read(sessionProvider).valueOrNull ??
        const SessionUser(
          id: '1',
          email: 'phi@moh.lk',
          fullName: 'PHI K. Dissanayake',
          role: 'phi',
          mohArea: 'Colombo MOH',
        );

    setState(() => _generating = true);
    try {
      final file = await buildMonthlyReportPdf(
        db: ref.read(dbProvider),
        officer: officer,
        year: _selectedPeriod.year,
        month: _selectedPeriod.month,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (_) => file.readAsBytes(),
        name: 'MOH_Monthly_Report_${_selectedPeriod.year}_${_selectedPeriod.month}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _changePeriod(int monthsToAdd) {
    setState(() {
      _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month + monthsToAdd);
    });
    _loadPeriodStats();
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_selectedPeriod);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MOH Monthly Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Month Selector
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                children: [
                  const Text(
                    'වාර්තාගත මාසය තෝරන්න (Select Month)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changePeriod(-1),
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        tooltip: 'Previous Month',
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            monthName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _changePeriod(1),
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        tooltip: 'Next Month',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Metrics Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName මාසික සාරාංශය',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Premises: $_premisesCount',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_loadingStats)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildMetricCard(
                  title: 'Inspections Done',
                  count: '$_inspectionsCount',
                  icon: Icons.checklist,
                  color: Colors.blue,
                ),
                _buildMetricCard(
                  title: 'Legal Notices',
                  count: '$_violationsCount',
                  icon: Icons.gavel,
                  color: Colors.deepOrange,
                ),
                _buildMetricCard(
                  title: 'Dengue Hotspots',
                  count: '$_dengueCount',
                  icon: Icons.pest_control,
                  color: Colors.red,
                ),
                _buildMetricCard(
                  title: 'Complaints',
                  count: '$_complaintsCount',
                  icon: Icons.report_problem,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Information Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'සෞඛ්‍ය වෛද්‍ය නිලධාරී (MOH) කාර්යාලය වෙත ඉදිරිපත් කළ යුතු නිල ආකෘති පත්‍රයට අනුව PDF වාර්තාව ස්වයංක්‍රීයව සෑදේ.',
                      style: TextStyle(fontSize: 13, color: Colors.indigo.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button: One-Click PDF Generator
            FilledButton.icon(
              onPressed: _generating ? null : _generateAndPreviewPdf,
              icon: _generating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf, size: 22),
              label: const Text(
                'Generate Official PDF Report (එක Click එකකින්)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF එක Preview බලා WhatsApp හෝ Email මගින් MOH කාර්යාලයට යැවිය හැක.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 26),
                Text(
                  count,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}
