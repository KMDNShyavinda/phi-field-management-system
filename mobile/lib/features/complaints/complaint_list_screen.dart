import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../providers.dart';

class ComplaintListScreen extends ConsumerWidget {
  const ComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onTap: () {
                    // Navigate to complaint details (To be implemented)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint details screen coming soon')),
                    );
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
