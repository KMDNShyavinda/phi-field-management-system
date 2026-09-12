import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'add_food_handler_screen.dart';

class FoodHandlersScreen extends ConsumerStatefulWidget {
  const FoodHandlersScreen({super.key, this.filterPremiseId});

  final String? filterPremiseId;

  @override
  ConsumerState<FoodHandlersScreen> createState() => _FoodHandlersScreenState();
}

class _FoodHandlersScreenState extends ConsumerState<FoodHandlersScreen> {
  List<FoodHandler> _handlers = [];
  Map<String, Premise> _premisesMap = {};
  bool _loading = true;
  String _statusFilter = 'all'; // 'all', 'expiring_soon', 'expired', 'valid'
  String? _selectedPremiseId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedPremiseId = widget.filterPremiseId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = ref.read(dbProvider);

    final premiseRows = await db.all('premises');
    final premises = premiseRows.map(Premise.fromMap).toList();
    final pMap = {for (final p in premises) p.id: p};

    final handlerRows = await db.all('food_handlers', orderBy: 'expiry_date ASC');
    final list = handlerRows.map(FoodHandler.fromMap).toList();

    setState(() {
      _premisesMap = pMap;
      _handlers = list;
      _loading = false;
    });
  }

  Future<void> _renewCertificate(FoodHandler handler) async {
    final ymd = DateFormat('yyyy-MM-dd');
    final newExpiry = DateTime.now().add(const Duration(days: 365));
    final newIssued = DateTime.now();

    final updated = FoodHandler(
      id: handler.id,
      premiseId: handler.premiseId,
      fullName: handler.fullName,
      nic: handler.nic,
      role: handler.role,
      certificateNo: 'MOH/COL/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      issuedDate: ymd.format(newIssued),
      expiryDate: ymd.format(newExpiry),
      status: 'valid',
      notes: 'Renewed after passing fresh medical examination on ${ymd.format(newIssued)}.',
    );

    await ref.read(dbProvider).upsert('food_handlers', updated.toMap());
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${handler.fullName}\'s certificate renewed for 1 full year! 🩺🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteHandler(FoodHandler handler) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Food Handler Record?'),
        content: Text('Are you sure you want to delete ${handler.fullName}?'),
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
      await db.delete('food_handlers', where: 'id = ?', whereArgs: [handler.id]);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic counts
    final expiredCount = _handlers.where((h) => h.calculatedStatus == 'expired').length;
    final expiringSoonCount = _handlers.where((h) => h.calculatedStatus == 'expiring_soon').length;
    final validCount = _handlers.where((h) => h.calculatedStatus == 'valid').length;

    // Filter list
    final filtered = _handlers.where((h) {
      final currentStatus = h.calculatedStatus;
      final matchesStatus = _statusFilter == 'all' || currentStatus == _statusFilter;
      final matchesPremise = _selectedPremiseId == null || h.premiseId == _selectedPremiseId;
      final matchesSearch = h.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.nic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.certificateNo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesPremise && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Handlers\' Certificates'),
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
                // KPI Header Cards
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricSummary('Expired', expiredCount, Colors.red),
                      _buildMetricSummary('Expiring Soon', expiringSoonCount, Colors.orange.shade800),
                      _buildMetricSummary('Valid', validCount, Colors.green),
                      _buildMetricSummary('Total Staff', _handlers.length, Colors.indigo),
                    ],
                  ),
                ),

                // Filters & Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    children: [
                      // Search box
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'සේවකයා, NIC හෝ සහතික අංකය සොයන්න...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 8),

                      // Status Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'සියල්ල (All)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('expired', 'Expired (කල් ඉකුත් වූ 🔴)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('expiring_soon', 'Expiring Soon (දින 30ක් ඇතුළත 🟡)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('valid', 'Valid (වලංගු 🟢)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // Handlers List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('සහතික වාර්තා හමු නොවීය.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final h = filtered[idx];
                            final premise = _premisesMap[h.premiseId];
                            final status = h.calculatedStatus;
                            final days = h.daysUntilExpiry;

                            Color statusColor = Colors.green;
                            String statusLabel = 'Valid ($days days left)';
                            if (status == 'expired') {
                              statusColor = Colors.red;
                              statusLabel = 'EXPIRED (${days.abs()} days ago)';
                            } else if (status == 'expiring_soon') {
                              statusColor = Colors.orange.shade900;
                              statusLabel = 'EXPIRES IN $days DAYS';
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: status == 'expired' ? Colors.red.shade300 : (status == 'expiring_soon' ? Colors.orange.shade300 : Colors.transparent),
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
                                          child: Text(
                                            h.fullName,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.work_outline, size: 15, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${h.role} • NIC: ${h.nic}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.storefront, size: 15, color: Colors.indigo),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            premise?.name ?? 'Establishment',
                                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Cert No: ${h.certificateNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            Text('Issued: ${h.issuedDate} | Expiry: ${h.expiryDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.published_with_changes, color: Colors.indigo),
                                              tooltip: 'Renew Certificate (+1 Year)',
                                              onPressed: () => _renewCertificate(h),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                              tooltip: 'Delete',
                                              onPressed: () => _deleteHandler(h),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (h.notes != null && h.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Notes: ${h.notes}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                                    ],
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
              builder: (_) => AddFoodHandlerScreen(initialPremiseId: _selectedPremiseId),
            ),
          );
          if (res == true) _loadData();
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Food Handler'),
        backgroundColor: Colors.indigo.shade900,
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
      selectedColor: Colors.indigo.shade900,
      backgroundColor: Colors.white,
      elevation: 1,
      onSelected: (val) => setState(() => _statusFilter = value),
    );
  }
}
