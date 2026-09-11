import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../complaints/complaint_list_screen.dart';
import '../dashboard/dashboard_stats_widget.dart';
import '../premise/add_premise_screen.dart';
import '../premise/premise_screen.dart';
import '../scan/scan_screen.dart';
import '../map/map_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String? _status;
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _status = 'Syncing...';
    });
    try {
      await ref.read(syncServiceProvider).syncNow();
      setState(() => _status = 'Synced');
    } catch (error) {
      setState(() => _status = 'Offline - using local records. $error');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(apiProvider).logout();
    ref.invalidate(sessionProvider);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_sync);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    ref.watch(dataTickProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPremiseScreen()));
            },
            icon: const Icon(Icons.add_business),
            tooltip: 'Add Establishment',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineMapScreen()));
            },
            icon: const Icon(Icons.map),
            tooltip: 'Offline Maps',
          ),
          IconButton(
            onPressed: _syncing ? null : _sync,
            icon: _syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_sync),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintListScreen()));
            },
            icon: const Icon(Icons.report_problem),
            tooltip: 'Complaints',
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(dbProvider).all('scheduled_visits', orderBy: 'visit_date, reason'),
        builder: (context, snapshot) {
          final visits = snapshot.data ?? [];
          final todayVisits = visits.where((row) => row['visit_date'] == today).toList();
          final followUps = visits.where((row) => row['reason'] == 'follow_up').toList();
          return RefreshIndicator(
            onRefresh: _sync,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (session != null) Text('${session.fullName} · ${session.mohArea}'),
                if (_status != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status!)),
                const SizedBox(height: 16),
                const DashboardStatsWidget(),
                const SizedBox(height: 24),
                Text("Today's visits", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (todayVisits.isEmpty) const Text('No programmed visits in local storage. Sync after login.'),
                for (final visit in todayVisits) _VisitTile(visit: visit),
                const SizedBox(height: 24),
                Text('Follow-ups', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (followUps.isEmpty) const Text('No follow-up inspections queued.'),
                for (final visit in followUps) _VisitTile(visit: visit),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VisitTile extends ConsumerWidget {
  const _VisitTile({required this.visit});

  final Map<String, dynamic> visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(dbProvider).getById('premises', visit['premise_id'] as String),
      builder: (context, snapshot) {
        final premiseMap = snapshot.data;
        if (premiseMap == null) {
          return const ListTile(title: Text('Loading premises…'));
        }
        final premise = Premise.fromMap(premiseMap);
        return Card(
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PremiseScreen(premiseId: premise.id, visitId: visit['id'] as String),
                ),
              );
            },
            title: Text(premise.name),
            subtitle: Text('${visit['reason']} · ${visit['status']}\n${visit['notes'] ?? premise.address}'),
            isThreeLine: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PhiTheme.riskColor(premise.risk).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(premise.risk.toUpperCase(), style: TextStyle(color: PhiTheme.riskColor(premise.risk))),
            ),
          ),
        );
      },
    );
  }
}
