import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers.dart';

class AddFoodHandlerScreen extends ConsumerStatefulWidget {
  const AddFoodHandlerScreen({super.key, this.initialPremiseId});

  final String? initialPremiseId;

  @override
  ConsumerState<AddFoodHandlerScreen> createState() => _AddFoodHandlerScreenState();
}

class _AddFoodHandlerScreenState extends ConsumerState<AddFoodHandlerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _certNoController = TextEditingController();
  final _notesController = TextEditingController();

  List<Premise> _premises = [];
  String? _selectedPremiseId;
  String _selectedRole = 'Cook / Baker';
  DateTime _issuedDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _loadingPremises = true;
  bool _saving = false;

  final _roles = const [
    'Executive / Head Chef',
    'Cook / Baker',
    'Kitchen Helper / Steward',
    'Food Server / Waiter',
    'Food Packer / Cashier',
    'Beverage Preparer',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPremiseId = widget.initialPremiseId;
    _certNoController.text = 'MOH/COL/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _loadPremises();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _certNoController.dispose();
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

  Future<void> _saveHandler() async {
    if (!_formKey.currentState!.validate() || _selectedPremiseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an establishment and complete all fields.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ymd = DateFormat('yyyy-MM-dd');
    final daysUntil = _expiryDate.difference(DateTime.now()).inDays;
    String status = 'valid';
    if (daysUntil < 0) {
      status = 'expired';
    } else if (daysUntil <= 30) {
      status = 'expiring_soon';
    }

    final id = 'FH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final handler = FoodHandler(
      id: id,
      premiseId: _selectedPremiseId!,
      fullName: _nameController.text.trim(),
      nic: _nicController.text.trim(),
      role: _selectedRole,
      certificateNo: _certNoController.text.trim(),
      issuedDate: ymd.format(_issuedDate),
      expiryDate: ymd.format(_expiryDate),
      status: status,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await ref.read(dbProvider).upsert('food_handlers', handler.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical Certificate recorded successfully! 🩺✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ymd = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Medical Certificate'),
      ),
      body: _loadingPremises
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'ආහාර හසුරුවන්නා සහ ව්‍යාපාරය (Staff & Establishment)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPremiseId,
                    decoration: const InputDecoration(
                      labelText: 'ආහාර ව්‍යාපාරික ස්ථානය (Establishment) *',
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                    ),
                    items: _premises.map((p) {
                      return DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.address})', overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedPremiseId = v),
                    validator: (v) => v == null ? 'Please select premise' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'සේවකයාගේ සම්පූර්ණ නම (Full Name) *',
                      hintText: 'e.g. Sunil Shantha',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter staff member name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nicController,
                          decoration: const InputDecoration(
                            labelText: 'ජාතික හැඳුනුම්පත් අංකය (NIC) *',
                            hintText: 'e.g. 198512304567',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter NIC' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'තනතුර (Role)',
                            border: OutlineInputBorder(),
                          ),
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 24),

                  const Text(
                    'වෛද්‍ය සහතිකයේ විස්තර (Certificate Details)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _certNoController,
                    decoration: const InputDecoration(
                      labelText: 'වෛද්‍ය සහතික අංකය (Certificate No) *',
                      prefixIcon: Icon(Icons.assignment_turned_in),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter certificate number' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('නිකුත් කළ දිනය', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          subtitle: Text(ymd.format(_issuedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.edit_calendar, size: 18),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _issuedDate,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _issuedDate = picked;
                                _expiryDate = picked.add(const Duration(days: 365));
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('කල් ඉකුත්වන දිනය', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          subtitle: Text(ymd.format(_expiryDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          trailing: const Icon(Icons.event_busy, size: 18, color: Colors.red),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (picked != null) setState(() => _expiryDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'වෛද්‍ය පරීක්ෂණ සටහන් (Medical Findings & Notes)',
                      hintText: 'e.g. Cleared by Colombo General Hospital / MOH Clinic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveHandler,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.save),
                    label: const Text('Save Food Handler Certificate', style: TextStyle(fontSize: 16)),
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
