import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../providers.dart';

class AddPremiseScreen extends ConsumerStatefulWidget {
  const AddPremiseScreen({super.key});

  @override
  ConsumerState<AddPremiseScreen> createState() => _AddPremiseScreenState();
}

class _AddPremiseScreenState extends ConsumerState<AddPremiseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _riskLevel = 'low';

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePremise() async {
    if (!_formKey.currentState!.validate()) return;
    
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return; // Cannot save without being logged in

    final premiseId = const Uuid().v4();
    final qrCode = 'phi://premise/$premiseId';

    final payload = {
      'id': premiseId,
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'owner_name': _ownerController.text.trim(),
      'owner_phone': _phoneController.text.trim(),
      'qr_code': qrCode,
      'latitude': 0.0, // To be implemented with GPS
      'longitude': 0.0,
      'risk': _riskLevel,
      'moh_area': session.mohArea,
      'compliance_score': 100, // Starting score
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    // Save to local database
    final db = ref.read(dbProvider);
    await db.upsert('premises', payload);

    // Queue for sync
    await db.enqueue(
      const Uuid().v4(),
      'upsert_premise',
      payload,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Establishment registered locally. Will sync when online.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Establishment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Establishment Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Owner Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _riskLevel,
                decoration: const InputDecoration(
                  labelText: 'Risk Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low Risk')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium Risk')),
                  DropdownMenuItem(value: 'high', child: Text('High Risk')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical Risk')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _riskLevel = value);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savePremise,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Establishment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
