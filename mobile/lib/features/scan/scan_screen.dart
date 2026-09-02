import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers.dart';
import '../premise/premise_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _manual = TextEditingController();
  String? _error;
  bool _handled = false;

  Future<void> _openCode(String raw) async {
    if (_handled) return;
    _handled = true;
    final premise = await ref.read(dbProvider).premiseByQr(raw);
    if (!mounted) return;
    if (premise == null) {
      setState(() {
        _handled = false;
        _error = 'No local premises match that QR. Sync while online, then retry.';
      });
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PremiseScreen(premiseId: premise['id'] as String)),
    );
  }

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraSupported = !Platform.isWindows && !Platform.isLinux;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan premises QR')),
      body: Column(
        children: [
          if (cameraSupported)
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final value = capture.barcodes.first.rawValue;
                  if (value != null) {
                    _openCode(value);
                  }
                },
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('Camera scanning is available on Android/iOS. Enter the QR payload below.')),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Enter the QR payload or premises UUID.'),
                TextField(
                  controller: _manual,
                  decoration: const InputDecoration(labelText: 'phi://premise/…'),
                ),
                if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFC62828))),
                const SizedBox(height: 8),
                FilledButton(onPressed: () => _openCode(_manual.text), child: const Text('Open premises')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
