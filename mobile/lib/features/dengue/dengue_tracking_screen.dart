import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'add_dengue_case_screen.dart';

class DengueTrackingScreen extends ConsumerStatefulWidget {
  const DengueTrackingScreen({super.key});

  @override
  ConsumerState<DengueTrackingScreen> createState() => _DengueTrackingScreenState();
}

class _DengueTrackingScreenState extends ConsumerState<DengueTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DengueCase> _cases = [];
  bool _loading = true;
  String _filter = 'all'; // 'all', 'active', 'investigated', 'cleared'
  String _searchQuery = '';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    setState(() => _loading = true);
    final maps = await ref.read(dbProvider).all('dengue_cases', orderBy: 'reported_date DESC');
    setState(() {
      _cases = maps.map(DengueCase.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _updateCaseStatus(DengueCase item, String newStatus, String actionNote) async {
    final updated = DengueCase(
      id: item.id,
      patientName: item.patientName,
      address: item.address,
      reportedDate: item.reportedDate,
      latitude: item.latitude,
      longitude: item.longitude,
      riskLevel: newStatus == 'cleared' ? 'low' : item.riskLevel,
      status: newStatus,
      actionTaken: actionNote.isEmpty ? item.actionTaken : actionNote,
      notes: item.notes,
    );

    await ref.read(dbProvider).upsert('dengue_cases', updated.toMap());
    await _loadCases();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated: ${newStatus.toUpperCase()} ✅'), backgroundColor: Colors.green),
      );
    }
  }

  Color _getRiskColor(String risk, String status) {
    if (status == 'cleared') return Colors.green;
    switch (risk.toLowerCase()) {
      case 'critical':
        return Colors.red.shade800;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.blue;
    }
  }

  void _showCaseDetails(DengueCase c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final riskColor = _getRiskColor(c.riskLevel, c.status);
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.patientName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor),
                    ),
                    child: Text(
                      '${c.status.toUpperCase()} (${c.riskLevel.toUpperCase()})',
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(c.address, style: const TextStyle(color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Reported: ${c.reportedDate}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100m Danger Radius Hotspot: සියලු අවට පරිශ්‍ර පරීක්ෂා කර මදුරු කීට මර්දනය සහ ධූමායනය (Fogging) කළ යුතුය.',
                        style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              if (c.actionTaken != null && c.actionTaken!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('ගත් පියවර (Action Taken): ${c.actionTaken}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
              if (c.notes != null && c.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('සටහන් (Notes): ${c.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 20),
              const Text('තත්ත්වය වෙනස් කිරීම (Update Action):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _updateCaseStatus(c, 'investigated', 'Premises inspected & notices served');
                      },
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Investigated'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _updateCaseStatus(c, 'cleared', '100m zone fogged & larvae cleared');
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Mark Cleared'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _cases.where((c) => c.status == 'active').length;
    final investigatedCount = _cases.where((c) => c.status == 'investigated').length;
    final clearedCount = _cases.where((c) => c.status == 'cleared').length;

    final filteredCases = _cases.where((c) {
      final matchesFilter = _filter == 'all' || c.status == _filter;
      final matchesSearch = c.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.address.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dengue Hotspots & Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Hotspot Map'),
            Tab(icon: Icon(Icons.list_alt), text: 'Cases List'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCases,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats summary bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge('Active (Hotspots)', activeCount, Colors.red),
                      _buildStatBadge('Investigated', investigatedCount, Colors.orange),
                      _buildStatBadge('Cleared', clearedCount, Colors.green),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: MAP VIEW
                      _buildMapView(filteredCases),

                      // TAB 2: LIST VIEW
                      _buildListView(filteredCases),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDengueCaseScreen()),
          );
          if (res == true) _loadCases();
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Report Dengue Case'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Widget _buildStatBadge(String title, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMapView(List<DengueCase> casesToDisplay) {
    final center = casesToDisplay.isNotEmpty
        ? LatLng(casesToDisplay.first.latitude, casesToDisplay.first.longitude)
        : const LatLng(6.9271, 79.8612);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'lk.gov.moh.phi_mobile',
            ),
            // 100m Hotspot Radius Circles around cases
            CircleLayer(
              circles: casesToDisplay.map((c) {
                final color = _getRiskColor(c.riskLevel, c.status);
                final circleAlpha = c.status == 'active' ? 0.28 : (c.status == 'investigated' ? 0.20 : 0.10);
                return CircleMarker(
                  point: LatLng(c.latitude, c.longitude),
                  radius: 100, // 100-meter inspection and fogging radius
                  useRadiusInMeter: true,
                  color: color.withValues(alpha: circleAlpha),
                  borderColor: color,
                  borderStrokeWidth: c.status == 'active' ? 2.0 : 1.0,
                );
              }).toList(),
            ),
            // Center Pin Markers
            MarkerLayer(
              markers: casesToDisplay.map((c) {
                final color = _getRiskColor(c.riskLevel, c.status);
                return Marker(
                  width: 44,
                  height: 44,
                  point: LatLng(c.latitude, c.longitude),
                  child: GestureDetector(
                    onTap: () => _showCaseDetails(c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                        border: Border.all(color: color, width: 2.5),
                      ),
                      child: Icon(
                        c.status == 'cleared' ? Icons.check : (c.status == 'active' ? Icons.pest_control : Icons.search),
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Filter bar overlay
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'සියල්ල (All)'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Active Hotspots (🔴)'),
                const SizedBox(width: 8),
                _buildFilterChip('investigated', 'Investigated (🟡)'),
                const SizedBox(width: 8),
                _buildFilterChip('cleared', 'Cleared (🟢)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
      selected: selected,
      selectedColor: Colors.red.shade700,
      backgroundColor: Colors.white,
      elevation: 2,
      onSelected: (val) {
        setState(() => _filter = value);
      },
    );
  }

  Widget _buildListView(List<DengueCase> casesToDisplay) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'රෝගියාගේ නම හෝ ලිපිනය සොයන්න...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: casesToDisplay.isEmpty
              ? const Center(child: Text('ඩෙංගු වාර්තා හමු නොවීය.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: casesToDisplay.length,
                  itemBuilder: (ctx, idx) {
                    final c = casesToDisplay[idx];
                    final color = _getRiskColor(c.riskLevel, c.status);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(Icons.pest_control, color: color),
                        ),
                        title: Text(c.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.address),
                            Text('Reported: ${c.reportedDate} • Status: ${c.status.toUpperCase()}',
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCaseDetails(c),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
