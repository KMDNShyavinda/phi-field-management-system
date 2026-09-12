import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';

class AddSampleScreen extends ConsumerStatefulWidget {
  const AddSampleScreen({super.key, this.initialPremiseId});

  final String? initialPremiseId;

  @override
  ConsumerState<AddSampleScreen> createState() => _AddSampleScreenState();
}

class _AddSampleScreenState extends ConsumerState<AddSampleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _sampleNoController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();

  String _sampleType = 'food'; // 'food' or 'water'
  List<Premise> _premises = [];
  String? _selectedPremiseId;
  DateTime _sampledDate = DateTime.now();
  String _selectedTestType = 'Chemical & Adulteration Analysis';
  String _selectedLab = 'Government Analyst Department';
  bool _loadingPremises = true;
  bool _saving = false;

  final _foodTests = const [
    'Chemical & Adulteration Analysis',
    'Aflatoxin & Mycotoxins',
    'Synthetic Dyes & Harmful Colors',
    'Microbiological & Food Pathogens',
    'Heavy Metals & Preservatives',
  ];

  final _waterTests = const [
    'Bacteriological (Coliforms & E. coli)',
    'Free Residual Chlorine Test',
    'Chemical & Mineral Safety (pH, Hardness)',
    'Turbidity & Physical Analysis',
    'Heavy Metals & Lead/Arsenic',
  ];

  final _laboratories = const [
    'Government Analyst Department',
    'Medical Research Institute (MRI)',
    'MOH Water Quality Laboratory',
    'MOH On-Site Rapid Field Test Kit',
    'National Institute of Health Sciences (NIHS)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPremiseId = widget.initialPremiseId;
    _sampleNoController.text = 'MOH/COL/SMP/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _loadPremises();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _sampleNoController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPremises() async {
    final list = await ref.read(dbProvider).all('premises', orderBy: 'name ASC');
    setState(() {
      _premises = list.map(Premise.fromMap).toList();
      if (_selectedPremiseId == null && _premises.isNotEmpty) {
        _selectedPremiseId = _premises.first.id;
      }
      _loadingPremises = false;
    });
  }

  Future<void> _saveSample() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ymd = DateFormat('yyyy-MM-dd');
    final id = 'SMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final sample = SampleRecord(
      id: id,
      premiseId: _selectedPremiseId,
      sampleType: _sampleType,
      itemName: _itemController.text.trim(),
      sampleNo: _sampleNoController.text.trim(),
      sampledDate: ymd.format(_sampledDate),
      batchNo: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      testType: _selectedTestType,
      laboratory: _selectedLab,
      labResultStatus: 'pending',
      resultDetails: 'Dispatched to $_selectedLab. Awaiting formal report.',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await ref.read(dbProvider).upsert('samples', sample.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample registered & seal recorded! 🧪✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save sample: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ymd = DateFormat('yyyy-MM-dd');
    final activeTests = _sampleType == 'food' ? _foodTests : _waterTests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Food / Water Sample'),
      ),
      body: _loadingPremises
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sample Type Selector (Food vs Water)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'food', label: Text('ආහාර සාම්පල (Food)'), icon: Icon(Icons.restaurant)),
                      ButtonSegment(value: 'water', label: Text('ජල සාම්පල (Water)'), icon: Icon(Icons.water_drop)),
                    ],
                    selected: {_sampleType},
                    onSelectionChanged: (set) {
                      setState(() {
                        _sampleType = set.first;
                        _selectedTestType = _sampleType == 'food' ? _foodTests.first : _waterTests.first;
                        if (_sampleType == 'water') {
                          _selectedLab = 'MOH Water Quality Laboratory';
                        } else {
                          _selectedLab = 'Government Analyst Department';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'ස්ථානය සහ සාම්පල විස්තර (Source & Details)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String?>(
                    initialValue: _selectedPremiseId,
                    decoration: const InputDecoration(
                      labelText: 'ආශ්‍රිත ව්‍යාපාරය / ස්ථානය (Establishment / Source)',
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('පොදු ජල මූලාශ්‍රය / වෙනත් (Public / Other Source)'),
                      ),
                      ..._premises.map((p) {
                        return DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text('${p.name} (${p.address})', overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _selectedPremiseId = v),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: _sampleType == 'food' ? 'ආහාර ද්‍රව්‍යයේ නම (Food Item) *' : 'ජල සාම්පල විස්තරය (Water Source) *',
                      hintText: _sampleType == 'food' ? 'e.g. Pure Coconut Oil, Chili Powder' : 'e.g. School Well Water, Filtered Tank',
                      prefixIcon: Icon(_sampleType == 'food' ? Icons.fastfood : Icons.water),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter item name' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sampleNoController,
                          decoration: const InputDecoration(
                            labelText: 'සාම්පල / මුද්‍රා අංකය (Sample/Seal No) *',
                            prefixIcon: Icon(Icons.pin),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter sample number' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _batchController,
                          decoration: const InputDecoration(
                            labelText: 'කාණ්ඩ අංකය (Batch/Lot No)',
                            hintText: 'e.g. LOT-402',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                    title: const Text('සාම්පලය ලබාගත් දිනය (Sampled Date)'),
                    subtitle: Text(ymd.format(_sampledDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _sampledDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _sampledDate = picked);
                      },
                      child: const Text('Change Date'),
                    ),
                  ),
                  const Divider(height: 24),

                  const Text(
                    'පරීක්ෂණ සහ රසායනාගාරය (Test & Laboratory)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedTestType,
                    decoration: const InputDecoration(
                      labelText: 'අවශ්‍ය පරීක්ෂණ වර්ගය (Test Requested)',
                      prefixIcon: Icon(Icons.biotech),
                      border: OutlineInputBorder(),
                    ),
                    items: activeTests.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedTestType = v ?? _selectedTestType),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedLab,
                    decoration: const InputDecoration(
                      labelText: 'යවන රසායනාගාරය (Testing Laboratory)',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    items: _laboratories.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedLab = v ?? _selectedLab),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'විශේෂ සටහන් සහ සාක්ෂි (Observations & Notes)',
                      hintText: 'e.g. Sample divided into 4 parts under Sec 13 of Food Act. Sealed in presence of owner.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _saving ? null : _saveSample,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.save),
                    label: const Text('Save & Track Sample', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
