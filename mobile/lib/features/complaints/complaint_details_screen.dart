import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../providers.dart';

class ComplaintDetailsScreen extends ConsumerStatefulWidget {
  const ComplaintDetailsScreen({super.key, required this.complaint});

  final Complaint complaint;

  @override
  ConsumerState<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends ConsumerState<ComplaintDetailsScreen> {
  late String _currentStatus;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.complaint.status;
  }

  Future<void> _markAsResolved() async {
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(dbProvider);
      
      // Create updated complaint
      final updatedComplaint = Complaint(
        id: widget.complaint.id,
        trackingNo: widget.complaint.trackingNo,
        premiseId: widget.complaint.premiseId,
        officerId: widget.complaint.officerId,
        title: widget.complaint.title,
        description: widget.complaint.description,
        priority: widget.complaint.priority,
        status: 'resolved',
        receivedDate: widget.complaint.receivedDate,
      );

      final payload = updatedComplaint.toMap();

      // Update local database
      await db.upsert('complaints', payload);

      // Queue for sync
      await db.enqueue(
        const Uuid().v4(),
        'upsert_complaint',
        payload,
      );

      setState(() {
        _currentStatus = 'resolved';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint marked as resolved. It will sync when online.')),
        );
        Navigator.pop(context, true); // Return true to signal refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve complaint: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final isResolved = _currentStatus.toLowerCase() == 'resolved';
    final priorityColor = _getPriorityColor(complaint.priority);

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Priority Badges
            Row(
              children: [
                Chip(
                  label: Text(
                    _currentStatus.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isResolved ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: isResolved ? Colors.green[800] : Colors.amber[900]),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    complaint.priority.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: priorityColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title and Tracking No
            Text(
              complaint.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tracking No: ${complaint.trackingNo}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            // Details
            _DetailItem(icon: Icons.calendar_today, label: 'Received Date', value: complaint.receivedDate),
            if (complaint.premiseId != null) 
              _DetailItem(icon: Icons.store, label: 'Premise ID', value: complaint.premiseId!),
            
            const SizedBox(height: 16),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                complaint.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Action Button
            if (!isResolved)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _markAsResolved,
                  icon: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Resolved', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
