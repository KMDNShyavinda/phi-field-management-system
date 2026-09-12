import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'add_school_clinic_screen.dart';

class SchoolsClinicsScreen extends ConsumerStatefulWidget {
  const SchoolsClinicsScreen({super.key});

  @override
  ConsumerState<SchoolsClinicsScreen> createState() => _SchoolsClinicsScreenState();
}

class _SchoolsClinicsScreenState extends ConsumerState<SchoolsClinicsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SchoolClinicInspection> _records = [];
  bool _loading = true;
  String _gradeFilter = 'all'; // 'all', 'A', 'B', 'C', 'warning'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = ref.read(dbProvider);

    final rows = await db.all('school_clinic_inspections', orderBy: 'inspection_date DESC');
    final list = rows.map(SchoolClinicInspection.fromMap).toList();

    setState(() {
      _records = list;
      _loading = false;
    });
  }

  Future<void> _deleteRecord(SchoolClinicInspection item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Inspection Record?'),
        content: Text('Are you sure you want to delete inspection for ${item.facilityName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await ref.read(dbProvider).database;
      await db.delete('school_clinic_inspections', where: 'id = ?', whereArgs: [item.id]);
      await _loadData();
    }
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green.shade700;
    if (grade.startsWith('B')) return Colors.blue.shade700;
    if (grade.startsWith('C')) return Colors.orange.shade800;
    return Colors.red.shade800;
  }

  @override
  Widget build(BuildContext context) {
    // Counts
    final gradeACount = _records.where((r) => r.overallGrade.startsWith('A')).length;
    final warningCount = _records.where((r) => r.status != 'passed').length;
    final canteensCount = _records.where((r) => r.category == 'school_canteen').length;
    final clinicsCount = _records.where((r) => r.category == 'mch_clinic').length;

    // Filter by Tab (0: All, 1: School Canteen, 2: MCH Clinic)
    final tabCategory = _tabController.index == 1 ? 'school_canteen' : (_tabController.index == 2 ? 'mch_clinic' : null);

    final filtered = _records.where((r) {
      final matchesTab = tabCategory == null || r.category == tabCategory;
      final matchesGrade = _gradeFilter == 'all' ||
          (_gradeFilter == 'warning' ? r.status != 'passed' : r.overallGrade.startsWith(_gradeFilter));
      final matchesSearch = r.facilityName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.facilityAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesGrade && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schools & Clinics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.dashboard_outlined), text: 'All Facilities'),
            Tab(icon: const Icon(Icons.school_outlined), text: 'Canteens ($canteensCount)'),
            Tab(icon: const Icon(Icons.local_hospital_outlined), text: 'Clinics ($clinicsCount)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top KPI Summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricSummary('Grade A (විශිෂ්ටයි)', gradeACount, Colors.green),
                      _buildMetricSummary('Warnings / Action', warningCount, Colors.orange.shade900),
                      _buildMetricSummary('School Canteens', canteensCount, Colors.indigo),
                      _buildMetricSummary('MCH Clinics', clinicsCount, Colors.teal),
                    ],
                  ),
                ),

                // Search & Filter
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'පාසල, සායනය හෝ ස්ථානය සොයන්න...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'සියල්ල (All)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('A', 'Grade A (🟢)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('B', 'Grade B (🔵)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('C', 'Grade C (🟡)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('warning', 'Warnings / Follow-up (🔴)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // Records List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('පරීක්ෂණ වාර්තා හමු නොවීය.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final r = filtered[idx];
                            final isCanteen = r.category == 'school_canteen';
                            final gradeColor = _getGradeColor(r.overallGrade);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: r.status != 'passed' ? Colors.orange.shade300 : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                isCanteen ? Icons.school : Icons.local_hospital,
                                                color: isCanteen ? Colors.indigo : Colors.teal,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  r.facilityName,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: gradeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: gradeColor),
                                          ),
                                          child: Text(
                                            r.overallGrade.split(' - ').first,
                                            style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (r.facilityAddress.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(r.facilityAddress, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                        ],
                                      ),
                                    if (r.contactPerson.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text('Contact: ${r.contactPerson}', style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                        ],
                                      ),
                                    const SizedBox(height: 6),
                                    Text('Inspected On: ${r.inspectionDate} • Status: ${r.status.toUpperCase()}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.status == 'passed' ? Colors.green.shade800 : Colors.deepOrange)),
                                    const Divider(height: 16),

                                    // Key Compliance Badges
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: isCanteen
                                          ? [
                                              _buildCheckChip('Healthy Circular', r.healthyFoodCompliance),
                                              _buildCheckChip('Handwashing', r.handwashingSanitation),
                                              _buildCheckChip('Staff Hygiene', r.foodHandlerCleanliness),
                                            ]
                                          : [
                                              _buildCheckChip('Cold Chain 2-8°C', r.coldChainMaintained),
                                              _buildCheckChip('Biohazard Waste', r.biomedicalWasteDisposal),
                                              _buildCheckChip('Sanitation', r.handwashingSanitation),
                                            ],
                                    ),

                                    // Findings / Recommendations if present
                                    if (r.findingsDeficiencies != null && r.findingsDeficiencies!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Findings: ${r.findingsDeficiencies}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                    ],
                                    if (r.recommendations != null && r.recommendations!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Action/Advice: ${r.recommendations}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo)),
                                    ],

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteRecord(r),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSchoolClinicScreen(
                initialCategory: _tabController.index == 2 ? 'mch_clinic' : 'school_canteen',
              ),
            ),
          );
          if (res == true) _loadData();
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Record Inspection'),
        backgroundColor: Colors.indigo.shade900,
      ),
    );
  }

  Widget _buildCheckChip(String label, bool passed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: passed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: passed ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(passed ? Icons.check_circle : Icons.cancel, size: 12, color: passed ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: passed ? Colors.green.shade900 : Colors.red.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSummary(String title, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _gradeFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12)),
      selected: selected,
      selectedColor: Colors.indigo.shade900,
      backgroundColor: Colors.white,
      elevation: 1,
      onSelected: (val) => setState(() => _gradeFilter = value),
    );
  }
}
