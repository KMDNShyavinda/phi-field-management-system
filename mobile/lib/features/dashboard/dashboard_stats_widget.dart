import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers.dart';
import '../reports/monthly_report_screen.dart';

class DashboardStatsWidget extends ConsumerWidget {
  const DashboardStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  title: "Today's Inspections",
                  value: stats['today_inspections'].toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: "Pending Follow-ups",
                  value: stats['pending_followups'].toString(),
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: "High Risk Places",
                  value: stats['high_risk_places'].toString(),
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
                _StatCard(
                  title: "Monthly Violations",
                  value: stats['monthly_violations'].toString(),
                  icon: Icons.gavel,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen()));
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.indigo, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Generate MOH Monthly Performance Report',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.indigo, size: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _fetchStats(WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Today's Visits (scheduled)
    final visits = await db.all('scheduled_visits', where: 'visit_date = ?', args: [today]);
    final todayInspections = visits.length;

    // Pending Follow-ups
    final followUps = await db.all('scheduled_visits', where: 'reason = ? AND status = ?', args: ['follow_up', 'pending']);
    final pendingFollowUps = followUps.length;

    // High Risk Places
    final premises = await db.all('premises');
    final highRiskPlaces = premises.where((p) => p['risk'] == 'high' || p['risk'] == 'critical').length;

    // Monthly Violations
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final violations = await db.all('violations', where: 'updated_at >= ?', args: [firstDayOfMonth]);
    final monthlyViolations = violations.length;

    return {
      'today_inspections': todayInspections,
      'pending_followups': pendingFollowUps,
      'high_risk_places': highRiskPlaces,
      'monthly_violations': monthlyViolations,
    };
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
