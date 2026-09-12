import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../inspection/checklist_screen.dart';
import '../food_handlers/food_handlers_screen.dart';
import '../samples/samples_screen.dart';

class PremiseScreen extends ConsumerWidget {
  const PremiseScreen({super.key, required this.premiseId, this.visitId});

  final String premiseId;
  final String? visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(dbProvider).getById('premises', premiseId),
      builder: (context, snapshot) {
        final map = snapshot.data;
        if (map == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final premise = Premise.fromMap(map);
        return Scaffold(
          appBar: AppBar(title: Text(premise.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(premise.address),
                      Text('Owner: ${premise.ownerName}'),
                      if (premise.ownerPhone != null) Text('Phone: ${premise.ownerPhone}'),
                      Text('QR: ${premise.qrCode}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(premise.risk.toUpperCase()),
                            backgroundColor: PhiTheme.riskColor(premise.risk).withValues(alpha: 0.15),
                          ),
                          const SizedBox(width: 8),
                          Text('Compliance score ${premise.complianceScore}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodHandlersScreen(filterPremiseId: premise.id),
                    ),
                  );
                },
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Food Handlers\' Medical Certificates'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SamplesScreen(filterPremiseId: premise.id),
                    ),
                  );
                },
                icon: const Icon(Icons.science_outlined),
                label: const Text('Food & Water Samples (සාම්පල වාර්තා)'),
              ),
              const SizedBox(height: 16),
              Text('Previous inspections', style: Theme.of(context).textTheme.titleMedium),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(dbProvider).all(
                      'inspections',
                      where: 'premise_id = ?',
                      args: [premiseId],
                      orderBy: 'started_at DESC',
                    ),
                builder: (context, history) {
                  final rows = history.data ?? [];
                  if (rows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No inspection history on this device yet.'),
                    );
                  }
                  return Column(
                    children: [
                      for (final row in rows)
                        ListTile(
                          title: Text(row['status'] as String),
                          subtitle: Text('${row['started_at']}\nGPS ${row['gps_status']}'),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final officer = ref.read(sessionProvider).valueOrNull;
                  if (officer == null) return;
                  try {
                    final id = await ref.read(inspectionRepositoryProvider).startInspection(
                          premise: premise,
                          officer: officer,
                          visitId: visitId,
                        );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChecklistScreen(
                          inspectionId: id,
                          premiseId: premise.id,
                          visitId: visitId,
                        ),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
                  }
                },
                child: const Text('Start digital inspection'),
              ),
            ],
          ),
        );
      },
    );
  }
}
