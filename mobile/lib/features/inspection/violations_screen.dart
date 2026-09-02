import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'signatures_screen.dart';

class ViolationsScreen extends ConsumerStatefulWidget {
  const ViolationsScreen({
    super.key,
    required this.inspectionId,
    required this.premiseId,
    this.visitId,
  });

  final String inspectionId;
  final String premiseId;
  final String? visitId;

  @override
  ConsumerState<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends ConsumerState<ViolationsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final rows = await ref.read(inspectionRepositoryProvider).suggestedViolations(widget.inspectionId);
      setState(() {
        _rows = rows;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Violations & notices')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Failed items generate a suggested improvement notice. Change the deadline before sign-off if needed.',
                ),
                const SizedBox(height: 12),
                if (_rows.isEmpty) const Text('No failed items. You can still complete the inspection.'),
                for (var i = 0; i < _rows.length; i++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_rows[i]['item_title'] as String, style: Theme.of(context).textTheme.titleMedium),
                          Text(_rows[i]['legal_provision'] as String),
                          const SizedBox(height: 8),
                          Text('Notice: ${_rows[i]['notice_type']}'),
                          TextFormField(
                            initialValue: _rows[i]['deadline'] as String,
                            decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)'),
                            onChanged: (value) => _rows[i]['deadline'] = value,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ref.read(inspectionRepositoryProvider).saveViolations(widget.inspectionId, _rows);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignaturesScreen(
                          inspectionId: widget.inspectionId,
                          premiseId: widget.premiseId,
                          visitId: widget.visitId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Continue to signatures'),
                ),
              ],
            ),
    );
  }
}
