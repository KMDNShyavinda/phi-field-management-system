import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';

class AddDengueCaseScreen extends ConsumerStatefulWidget {
  const AddDengueCaseScreen({super.key});

  @override
  ConsumerState<AddDengueCaseScreen> createState() => _AddDengueCaseScreenState();
}

class _AddDengueCaseScreenState extends ConsumerState<AddDengueCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController(text: '6.9271');
  final _lonController = TextEditingController(text: '79.8612');
  final _notesController = TextEditingController();
  final _actionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _riskLevel = 'high';
  String _status = 'active';
  bool _gettingLocation = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _notesController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Please enter coordinates manually.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );

      _latController.text = position.latitude.toStringAsFixed(6);
      _lonController.text = position.longitude.toStringAsFixed(6);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS coordinates captured accurately! 📍'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not obtain GPS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final id = 'D-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final dengueCase = DengueCase(
        id: id,
        patientName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        reportedDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        latitude: double.tryParse(_latController.text.trim()) ?? 6.9271,
        longitude: double.tryParse(_lonController.text.trim()) ?? 79.8612,
        riskLevel: _riskLevel,
        status: _status,
        actionTaken: _actionController.text.trim().isEmpty ? null : _actionController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(dbProvider).upsert('dengue_cases', dengueCase.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dengue case and 100m Hotspot zone registered! 🦟'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save case: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Dengue Case / Hotspot'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'රෝගියා සහ ස්ථානය පිළිබඳ විස්තර (Case Information)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'රෝගියාගේ නම / Ref ID *',
                hintText: 'e.g. Nimal Perera or Case #402',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name or case ID' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'ලිපිනය / ප්‍රදේශය (Address) *',
                hintText: 'e.g. 45/2, Temple Road, Colombo 10',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.indigo),
              title: const Text('වාර්තා වූ දිනය (Reported Date)'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              trailing: OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: const Text('Change Date'),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'GPS ඛණ්ඩාංක (Coordinates)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                TextButton.icon(
                  onPressed: _gettingLocation ? null : _getCurrentLocation,
                  icon: _gettingLocation
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Get Current GPS'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lat' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lonController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lon' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            const Text(
              'අවදානම් තත්ත්වය සහ පියවර (Risk & Action)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _riskLevel,
                    decoration: const InputDecoration(labelText: 'අවදානම (Risk)', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'critical', child: Text('Critical (🔴)')),
                      DropdownMenuItem(value: 'high', child: Text('High (🟠)')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium (🟡)')),
                      DropdownMenuItem(value: 'low', child: Text('Low (🟢)')),
                    ],
                    onChanged: (v) => setState(() => _riskLevel = v ?? 'high'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'තත්ත්වය (Status)', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active (ක්‍රියාකාරී)')),
                      DropdownMenuItem(value: 'investigated', child: Text('Investigated')),
                      DropdownMenuItem(value: 'cleared', child: Text('Cleared (පිරිසිදු කළ)')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'active'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: 'ගත් පියවර (Action Taken)',
                hintText: 'e.g. Warning given, Fogging scheduled, Larvicide applied',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'විශේෂ සටහන් (Notes & Observations)',
                hintText: 'e.g. Nearby open drains, mosquito breeding containers found...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _saveCase,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Save & Mark 100m Hotspot', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
