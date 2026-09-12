import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';

class AddSchoolClinicScreen extends ConsumerStatefulWidget {
  const AddSchoolClinicScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<AddSchoolClinicScreen> createState() => _AddSchoolClinicScreenState();
}

class _AddSchoolClinicScreenState extends ConsumerState<AddSchoolClinicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _deficienciesController = TextEditingController();
  final _recommendationsController = TextEditingController();

  String _category = 'school_canteen'; // 'school_canteen' or 'mch_clinic'
  DateTime _inspectionDate = DateTime.now();
  String _overallGrade = 'A - Excellent';
  String _status = 'passed';

  bool _healthyFoodCompliance = true;
  bool _handwashingSanitation = true;
  bool _foodHandlerCleanliness = true;
  bool _coldChainMaintained = true;
  bool _biomedicalWasteDisposal = true;

  bool _saving = false;

  final _grades = const [
    'A - Excellent',
    'B - Satisfactory',
    'C - Needs Improvement',
    'D - Unacceptable / Action Required',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _deficienciesController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ymd = DateFormat('yyyy-MM-dd');
    final id = 'SCI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final record = SchoolClinicInspection(
      id: id,
      category: _category,
      facilityName: _nameController.text.trim(),
      facilityAddress: _addressController.text.trim(),
      contactPerson: _contactController.text.trim(),
      inspectionDate: ymd.format(_inspectionDate),
      overallGrade: _overallGrade,
      status: _status,
      healthyFoodCompliance: _healthyFoodCompliance,
      handwashingSanitation: _handwashingSanitation,
      foodHandlerCleanliness: _foodHandlerCleanliness,
      coldChainMaintained: _coldChainMaintained,
      biomedicalWasteDisposal: _biomedicalWasteDisposal,
      findingsDeficiencies: _deficienciesController.text.trim().isEmpty ? null : _deficienciesController.text.trim(),
      recommendations: _recommendationsController.text.trim().isEmpty ? null : _recommendationsController.text.trim(),
    );

    try {
      await ref.read(dbProvider).upsert('school_clinic_inspections', record.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_category == 'school_canteen' ? 'School Canteen' : 'MCH Clinic'} inspection recorded! 🏫🏥✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ymd = DateFormat('yyyy-MM-dd');
    final isCanteen = _category == 'school_canteen';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCanteen ? 'School Canteen Inspection' : 'MCH Clinic Inspection'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'school_canteen', label: Text('පාසල් ආපනශාලා (Canteen)'), icon: Icon(Icons.school)),
                ButtonSegment(value: 'mch_clinic', label: Text('මාතෘ/ළමා සායන (MCH)'), icon: Icon(Icons.local_hospital)),
              ],
              selected: {_category},
              onSelectionChanged: (set) {
                setState(() => _category = set.first);
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'ස්ථානයේ තොරතුරු (Facility Information)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isCanteen ? 'පාසලේ සහ ආපනශාලාවේ නම (School / Canteen) *' : 'සායන මධ්‍යස්ථානයේ නම (Clinic Name) *',
                hintText: isCanteen ? 'e.g. Royal College Main Canteen' : 'e.g. Bambalapitiya MCH Center',
                prefixIcon: Icon(isCanteen ? Icons.school : Icons.local_hospital),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter facility name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'ලිපිනය / ප්‍රදේශය (Address)',
                hintText: 'e.g. Rajakeeya Mawatha, Colombo 07',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: isCanteen ? 'විදුහල්පති / පාලක (Principal / Manager)' : 'භාර නිලධාරී / SPHN / PHM (Officer In-Charge)',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.indigo),
              title: const Text('පරීක්ෂා කළ දිනය (Inspection Date)'),
              subtitle: Text(ymd.format(_inspectionDate), style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _inspectionDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _inspectionDate = picked);
                },
                child: const Text('Change Date'),
              ),
            ),
            const Divider(height: 24),

            Text(
              isCanteen ? 'ආපනශාලා සෞඛ්‍ය නිර්ණායක (Canteen Checklist)' : 'සායන සෞඛ්‍ය සහ ආරක්ෂණ නිර්ණායක (Clinic Checklist)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),

            if (isCanteen) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('චක්‍රලේඛ අනුකූලතාවය (Healthy Food Compliance)'),
                subtitle: const Text('පැණිබීම, තහනම් කෘත්‍රීම රසකාරක/කෑම නොමැති බව'),
                value: _healthyFoodCompliance,
                onChanged: (v) => setState(() => _healthyFoodCompliance = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('අත්සේදුම් සහ සනීපාරක්ෂක පහසුකම් (Handwashing)'),
                subtitle: const Text('සබන් සහිත පිරිසිදු ජල පහසුකම් සිසුන්ට තිබීම'),
                value: _handwashingSanitation,
                onChanged: (v) => setState(() => _handwashingSanitation = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ආහාර හසුරුවන්නන්ගේ පිරිසිදුකම (Staff Cleanliness)'),
                subtitle: const Text('ඒප්‍රන්/හිස්වැසුම් පැළඳීම සහ වෛද්‍ය සහතික තිබීම'),
                value: _foodHandlerCleanliness,
                onChanged: (v) => setState(() => _foodHandlerCleanliness = v),
              ),
            ] else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('එන්නත් ශීතකරණ උෂ්ණත්වය (Cold Chain 2°C - 8°C)'),
                subtitle: const Text('දිනපතා උෂ්ණත්ව සටහන පවත්වාගෙන යාම'),
                value: _coldChainMaintained,
                onChanged: (v) => setState(() => _coldChainMaintained = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ජෛව වෛද්‍ය අපද්‍රව්‍ය කළමනාකරණය (Waste Disposal)'),
                subtitle: const Text('කහ බෑග් සහ කටු බහාලුම් (Sharps Boxes) නිසි පරිදි භාවිතය'),
                value: _biomedicalWasteDisposal,
                onChanged: (v) => setState(() => _biomedicalWasteDisposal = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('සායන සනීපාරක්ෂාව සහ අත්සේදුම් (Sanitation)'),
                subtitle: const Text('විෂබීජ නාශක දියර සහ පිරිසිදු පානීය ජල පහසුකම්'),
                value: _handwashingSanitation,
                onChanged: (v) => setState(() => _handwashingSanitation = v),
              ),
            ],

            const Divider(height: 24),
            const Text(
              'ශ්‍රේණිගත කිරීම සහ තත්ත්වය (Grading & Action)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _overallGrade,
                    decoration: const InputDecoration(labelText: 'ශ්‍රේණිය (Grade)', border: OutlineInputBorder()),
                    items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => _overallGrade = v ?? _overallGrade),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'තත්ත්වය (Status)', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'passed', child: Text('Passed (අනුමතයි 🟢)')),
                      DropdownMenuItem(value: 'warning_issued', child: Text('Warning (අවවාද 🟡)')),
                      DropdownMenuItem(value: 'follow_up_required', child: Text('Follow-up (🔴)')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _deficienciesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'නිරීක්ෂණය වූ අඩුපාඩු (Findings & Deficiencies)',
                hintText: 'e.g. Artificial flavored biscuits displayed / Sharps box full',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recommendationsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ලබාදුන් උපදෙස් සහ නිර්දේශ (Recommendations)',
                hintText: 'e.g. Issued 14-day notice to remove banned items / Requisition sharps box',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _saveInspection,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Save Inspection Record', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.indigo.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
