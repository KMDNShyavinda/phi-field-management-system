import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import 'complaint_details_screen.dart';

class ComplaintListScreen extends ConsumerStatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  ConsumerState<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends ConsumerState<ComplaintListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(dbProvider).all('complaints', orderBy: 'priority DESC, received_date DESC'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('No complaints assigned.'));
          }

          final complaints = rows.map(Complaint.fromMap).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.warning_rounded,
                    color: _getPriorityColor(complaint.priority),
                    size: 32,
                  ),
                  title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${complaint.trackingNo} - ${complaint.status.toUpperCase()}\n${complaint.description}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintDetailsScreen(complaint: complaint),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
      case 'low':
      default:
        return Colors.blue;
    }
  }
}
