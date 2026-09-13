import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: DemoAccounts.email);
  final _password = TextEditingController(text: DemoAccounts.password);
  final _fullName = TextEditingController(text: 'PHI Officer');
  final _mohArea = TextEditingController(text: 'Colombo MOH');

  bool _busy = false;
  bool _showCustomProfile = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _mohArea.dispose();
    super.dispose();
  }

  Future<void> _submit({bool forceOffline = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final emailVal = _email.text.trim().isNotEmpty ? _email.text.trim() : DemoAccounts.email;
    final nameVal = _fullName.text.trim().isNotEmpty ? _fullName.text.trim() : 'PHI Officer';
    final areaVal = _mohArea.text.trim().isNotEmpty ? _mohArea.text.trim() : 'Colombo MOH';

    try {
      if (forceOffline) {
        await ref.read(apiProvider).loginOffline(
          email: emailVal,
          fullName: nameVal,
          mohArea: areaVal,
        );
      } else {
        await ref.read(apiProvider).login(
          emailVal,
          _password.text,
          fullName: nameVal,
          mohArea: areaVal,
        );
      }

      try {
        await ref.read(syncServiceProvider).syncNow();
      } catch (_) {}

      ref.invalidate(sessionProvider);
    } catch (error) {
      // Guaranteed offline fallback so PHI is never blocked
      await ref.read(apiProvider).loginOffline(
        email: emailVal,
        fullName: nameVal,
        mohArea: areaVal,
      );
      ref.invalidate(sessionProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.health_and_safety, color: Colors.green.shade800, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PHI Smart Inspector',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Offline Field Management System',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 18, color: Colors.blue.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '100% Offline-First: කිසිදු Server එකක් හෝ අන්තර්ජාලයක් අවශ්‍ය නොවේ.',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email / Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => setState(() => _showCustomProfile = !_showCustomProfile),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'නිලධාරියාගේ නම සහ MOH ප්‍රදේශය වෙනස් කරන්න',
                            style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            _showCustomProfile ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.indigo.shade700,
                          ),
                        ],
                      ),
                    ),
                    if (_showCustomProfile) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _fullName,
                        decoration: const InputDecoration(
                          labelText: 'PHI නිලධාරියාගේ නම (Full Name)',
                          hintText: 'e.g. K. M. D. N. Shyavinda',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _mohArea,
                        decoration: const InputDecoration(
                          labelText: 'MOH ප්‍රදේශය (MOH Area)',
                          hintText: 'e.g. Colombo MOH / Kaduwela MOH',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _submit(forceOffline: false),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.login),
                      label: const Text('ඇතුළු වන්න (Sign In)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _submit(forceOffline: true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.offline_bolt_outlined, size: 18),
                      label: const Text('Offline Mode (ස්වාධීනව භාවිතය)', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
