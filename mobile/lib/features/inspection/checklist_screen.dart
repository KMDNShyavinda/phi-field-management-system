import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'violations_screen.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({
    super.key,
    required this.inspectionId,
    required this.premiseId,
    this.visitId,
  });

  final String inspectionId;
  final String premiseId;
  final String? visitId;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final _notes = <String, TextEditingController>{};
  final _results = <String, String>{};

  @override
  void dispose() {
    for (final controller in _notes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _setResult(ChecklistItem item, String result) async {
    setState(() => _results[item.id] = result);
    await ref.read(inspectionRepositoryProvider).saveAnswer(
          inspectionId: widget.inspectionId,
          itemId: item.id,
          result: result,
          notes: _notes[item.id]?.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital checklist')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(dbProvider).all('checklist_items', orderBy: 'sort_order'),
        builder: (context, snapshot) {
          final items = (snapshot.data ?? []).map(ChecklistItem.fromMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Mark Pass / Fail / N/A. Capture a photo on any failed item when possible.'),
              const SizedBox(height: 12),
              for (final item in items) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                        Text(item.description),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'pass', label: Text('Pass')),
                            ButtonSegment(value: 'fail', label: Text('Fail')),
                            ButtonSegment(value: 'na', label: Text('N/A')),
                          ],
                          emptySelectionAllowed: true,
                          selected: {
                            if (_results[item.id] != null) _results[item.id]!,
                          },
                          onSelectionChanged: (value) {
                            if (value.isEmpty) return;
                            _setResult(item, value.first);
                          },
                        ),
                        TextField(
                          controller: _notes.putIfAbsent(item.id, TextEditingController.new),
                          decoration: const InputDecoration(labelText: 'Notes'),
                          onChanged: (val) {
                            if (_results[item.id] != null) {
                              _setResult(item, _results[item.id]!);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: ref.read(inspectionRepositoryProvider).getPreviousPhoto(
                                inspectionId: widget.inspectionId,
                                itemId: item.id,
                              ),
                          builder: (context, photoSnap) {
                            final prevPhoto = photoSnap.data;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (prevPhoto != null && prevPhoto['storage_path'] != null) ...[
                                  const Text('Before (Last Inspection):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(File(prevPhoto['storage_path'] as String)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(source: ImageSource.camera) ??
                                        await picker.pickImage(source: ImageSource.gallery);
                                    if (picked == null) return;
                                    await ref.read(inspectionRepositoryProvider).attachPhoto(
                                          inspectionId: widget.inspectionId,
                                          itemId: item.id,
                                          source: File(picked.path),
                                        );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Photo stored with GPS/time hash')),
                                    );
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(prevPhoto != null ? 'Take "After" photo' : 'Attach evidence photo'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViolationsScreen(
                        inspectionId: widget.inspectionId,
                        premiseId: widget.premiseId,
                        visitId: widget.visitId,
                      ),
                    ),
                  );
                },
                child: const Text('Review violations & notices'),
              ),
            ],
          );
        },
      ),
    );
  }
}
