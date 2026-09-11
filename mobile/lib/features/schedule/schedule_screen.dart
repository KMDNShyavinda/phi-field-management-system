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
import '../../core/google_drive_service.dart';

import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String? _status;
  bool _syncing = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

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
          
          // Group visits by date for the calendar
          final Map<String, List<Map<String, dynamic>>> events = {};
          for (final v in visits) {
            final dateStr = v['visit_date'] as String;
            events.putIfAbsent(dateStr, () => []).add(v);
          }
          
          List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
            final dateStr = DateFormat('yyyy-MM-dd').format(day);
            return events[dateStr] ?? [];
          }

          final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay ?? _focusedDay);
          final selectedVisits = events[selectedDateStr] ?? [];

          return RefreshIndicator(
            onRefresh: _sync,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (session != null) Text('${session.fullName} • ${session.mohArea}'),
                        if (_status != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status!)),
                        const SizedBox(height: 16),
                        const DashboardStatsWidget(),
                        const SizedBox(height: 16),
                        
                        // Calendar Widget
                        Card(
                          elevation: 2,
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: CalendarFormat.month,
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Month',
                              CalendarFormat.twoWeeks: '2 Weeks',
                              CalendarFormat.week: 'Week',
                            },
                            eventLoader: _getEventsForDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarStyle: CalendarStyle(
                              markerDecoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Visits for $selectedDateStr',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (selectedVisits.isEmpty) 
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('No programmed visits for this day.'),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _VisitTile(visit: selectedVisits[index]),
                      childCount: selectedVisits.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // FAB padding
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
