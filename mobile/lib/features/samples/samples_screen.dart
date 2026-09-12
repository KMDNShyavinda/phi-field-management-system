import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'add_sample_screen.dart';

class SamplesScreen extends ConsumerStatefulWidget {
  const SamplesScreen({super.key, this.filterPremiseId});

  final String? filterPremiseId;

  @override
  ConsumerState<SamplesScreen> createState() => _SamplesScreenState();
}

class _SamplesScreenState extends ConsumerState<SamplesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SampleRecord> _samples = [];
  Map<String, Premise> _premisesMap = {};
  bool _loading = true;
  String _statusFilter = 'all'; // 'all', 'pending', 'satisfactory', 'unsatisfactory'
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

    final pRows = await db.all('premises');
    final premises = pRows.map(Premise.fromMap).toList();
    final pMap = {for (final p in premises) p.id: p};

    final sRows = await db.all('samples', orderBy: 'sampled_date DESC');
    final list = sRows.map(SampleRecord.fromMap).toList();

    setState(() {
      _premisesMap = pMap;
      _samples = list;
      _loading = false;
    });
  }

  Future<void> _showUpdateResultDialog(SampleRecord sample) async {
    String newStatus = sample.labResultStatus == 'pending' ? 'satisfactory' : sample.labResultStatus;
    final detailsController = TextEditingController(text: sample.resultDetails ?? '');
    final legalController = TextEditingController(text: sample.legalActionTaken ?? '');
    DateTime resultDate = DateTime.now();
    final ymd = DateFormat('yyyy-MM-dd');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('රසායනාගාර වාර්තාව (${sample.itemName})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sample No: ${sample.sampleNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                const SizedBox(height: 12),
                const Text('ප්‍රතිඵලය (Lab Result Status):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: newStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'satisfactory', child: Text('සතුටුදායකයි - Passed (🟢)')),
                    DropdownMenuItem(value: 'unsatisfactory', child: Text('අසතුටුදායකයි - Failed / Contaminated (🔴)')),
                    DropdownMenuItem(value: 'pending', child: Text('පරීක්ෂණ මට්ටමේ - Pending (🟡)')),
                  ],
                  onChanged: (v) => setDialogState(() => newStatus = v ?? 'satisfactory'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'රසායනාගාර වාර්තාවේ සොයාගැනීම් (Findings)',
                    hintText: 'e.g. Free from adulteration / E. coli detected 24 CFU',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: legalController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ගත යුතු / ගත් නීතිමය පියවර (Legal Action Taken)',
                    hintText: 'e.g. Filed B-report under Food Act Sec 18 / Warning served',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: newStatus == 'unsatisfactory' ? Colors.red.shade800 : Colors.teal.shade800,
              ),
              child: const Text('Save Lab Result'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      final newRecord = SampleRecord(
        id: sample.id,
        premiseId: sample.premiseId,
        sampleType: sample.sampleType,
        itemName: sample.itemName,
        sampleNo: sample.sampleNo,
        sampledDate: sample.sampledDate,
        batchNo: sample.batchNo,
        testType: sample.testType,
        laboratory: sample.laboratory,
        labResultStatus: newStatus,
        resultDate: ymd.format(resultDate),
        resultDetails: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
        legalActionTaken: legalController.text.trim().isEmpty ? null : legalController.text.trim(),
        notes: sample.notes,
      );

      await ref.read(dbProvider).upsert('samples', newRecord.toMap());
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lab report updated for ${sample.itemName}! 🧪✅'),
            backgroundColor: newStatus == 'unsatisfactory' ? Colors.red : Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Counts
    final pendingCount = _samples.where((s) => s.labResultStatus == 'pending').length;
    final passedCount = _samples.where((s) => s.labResultStatus == 'satisfactory').length;
    final failedCount = _samples.where((s) => s.labResultStatus == 'unsatisfactory').length;

    // Filter by Tab (0: All, 1: Food, 2: Water)
    final tabType = _tabController.index == 1 ? 'food' : (_tabController.index == 2 ? 'water' : null);

    final filtered = _samples.where((s) {
      final matchesTab = tabType == null || s.sampleType == tabType;
      final matchesStatus = _statusFilter == 'all' || s.labResultStatus == _statusFilter;
      final matchesPremise = widget.filterPremiseId == null || s.premiseId == widget.filterPremiseId;
      final matchesSearch = s.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.sampleNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.laboratory.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesStatus && matchesPremise && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water & Food Samples'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.science), text: 'All Samples'),
            Tab(icon: Icon(Icons.restaurant), text: 'Food (ආහාර)'),
            Tab(icon: Icon(Icons.water_drop), text: 'Water (ජලය)'),
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
                      _buildMetricSummary('Pending (වාර්තා ලැබීමට)', pendingCount, Colors.orange.shade800),
                      _buildMetricSummary('Satisfactory (Passed)', passedCount, Colors.green),
                      _buildMetricSummary('Failed (අසතුටුදායක)', failedCount, Colors.red),
                      _buildMetricSummary('Total', _samples.length, Colors.indigo),
                    ],
                  ),
                ),

                // Search & Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'සාම්පලයේ නම, මුද්‍රා අංකය හෝ විද්‍යාගාරය සොයන්න...',
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
                            _buildFilterChip('pending', 'Pending (🟡)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('satisfactory', 'Satisfactory (🟢)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('unsatisfactory', 'Failed / Unsatisfactory (🔴)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // Samples List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('සාම්පල වාර්තා හමු නොවීය.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final s = filtered[idx];
                            final premise = s.premiseId != null ? _premisesMap[s.premiseId] : null;

                            Color statusColor = Colors.orange.shade800;
                            String statusLabel = 'PENDING REPORT';
                            IconData statusIcon = Icons.hourglass_top;

                            if (s.labResultStatus == 'satisfactory') {
                              statusColor = Colors.green;
                              statusLabel = 'SATISFACTORY / PASSED';
                              statusIcon = Icons.check_circle;
                            } else if (s.labResultStatus == 'unsatisfactory') {
                              statusColor = Colors.red.shade800;
                              statusLabel = 'FAILED / UNSATISFACTORY';
                              statusIcon = Icons.error;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: s.labResultStatus == 'unsatisfactory' ? Colors.red.shade400 : Colors.transparent,
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
                                        Row(
                                          children: [
                                            Icon(s.sampleType == 'water' ? Icons.water_drop : Icons.restaurant,
                                                color: s.sampleType == 'water' ? Colors.blue : Colors.orange, size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              s.itemName,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, size: 12, color: statusColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                statusLabel,
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Seal / Sample No: ${s.sampleNo}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('Source: ${premise?.name ?? 'Public / Community Water Source'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    Text('Test: ${s.testType} • Lab: ${s.laboratory}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                    Text('Sampled On: ${s.sampledDate}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    const Divider(height: 16),

                                    // Result Box if available
                                    if (s.resultDetails != null && s.resultDetails!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Lab Report Findings: ${s.resultDetails}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor)),
                                            if (s.legalActionTaken != null && s.legalActionTaken!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Action Taken: ${s.legalActionTaken}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _showUpdateResultDialog(s),
                                          icon: const Icon(Icons.edit_note, size: 18),
                                          label: const Text('Update Lab Report'),
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
              builder: (_) => AddSampleScreen(initialPremiseId: widget.filterPremiseId),
            ),
          );
          if (res == true) _loadData();
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Record New Sample'),
        backgroundColor: Colors.teal.shade800,
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
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12)),
      selected: selected,
      selectedColor: Colors.teal.shade800,
      backgroundColor: Colors.white,
      elevation: 1,
      onSelected: (val) => setState(() => _statusFilter = value),
    );
  }
}
