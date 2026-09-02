import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../domain/models.dart';
import '../../providers.dart';
import 'report_screen.dart';

class SignaturesScreen extends ConsumerStatefulWidget {
  const SignaturesScreen({
    super.key,
    required this.inspectionId,
    required this.premiseId,
    this.visitId,
  });

  final String inspectionId;
  final String premiseId;
  final String? visitId;

  @override
  ConsumerState<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends ConsumerState<SignaturesScreen> {
  final _phi = SignatureController(penStrokeWidth: 3);
  final _owner = SignatureController(penStrokeWidth: 3);
  late final TextEditingController _ownerName;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ownerName = TextEditingController();
    Future.microtask(() async {
      final premise = await ref.read(dbProvider).getById('premises', widget.premiseId);
      if (premise != null) {
        _ownerName.text = premise['owner_name'] as String? ?? '';
      }
    });
  }

  @override
  void dispose() {
    _phi.dispose();
    _owner.dispose();
    _ownerName.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final officer = ref.read(sessionProvider).valueOrNull;
    final premiseMap = await ref.read(dbProvider).getById('premises', widget.premiseId);
    if (officer == null || premiseMap == null) return;
    final phiBytes = await _phi.toPngBytes();
    final ownerBytes = await _owner.toPngBytes();
    if (phiBytes == null || ownerBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Both officer and owner must sign on screen.')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(inspectionRepositoryProvider);
      await repo.saveSignature(
        inspectionId: widget.inspectionId,
        role: 'phi',
        name: officer.fullName,
        pngBytes: phiBytes,
      );
      await repo.saveSignature(
        inspectionId: widget.inspectionId,
        role: 'owner',
        name: _ownerName.text.trim().isEmpty ? 'Owner' : _ownerName.text.trim(),
        pngBytes: ownerBytes,
      );
      final pdf = await repo.completeInspection(
        inspectionId: widget.inspectionId,
        visitId: widget.visitId ?? '',
        premise: Premise.fromMap(premiseMap),
        officer: officer,
      );
      try {
        await ref.read(syncServiceProvider).syncNow();
      } catch (_) {
        // Stay offline; outbox will drain later.
      }
      ref.read(dataTickProvider.notifier).state++;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ReportScreen(pdfPath: pdf.path, inspectionId: widget.inspectionId),
        ),
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dual signatures')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Discuss findings with the owner, then both parties sign on the screen.'),
          const SizedBox(height: 12),
          const Text('PHI signature'),
          Container(
            height: 160,
            color: Colors.white,
            child: Signature(controller: _phi, backgroundColor: Colors.white),
          ),
          TextButton(onPressed: _phi.clear, child: const Text('Clear PHI')),
          TextField(controller: _ownerName, decoration: const InputDecoration(labelText: 'Owner name')),
          const Text('Owner signature'),
          Container(
            height: 160,
            color: Colors.white,
            child: Signature(controller: _owner, backgroundColor: Colors.white),
          ),
          TextButton(onPressed: _owner.clear, child: const Text('Clear owner')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _complete,
            child: _busy ? const CircularProgressIndicator() : const Text('Generate official PDF'),
          ),
        ],
      ),
    );
  }
}
