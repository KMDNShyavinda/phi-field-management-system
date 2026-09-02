import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/sync/connectivity_sync.dart';
import 'providers.dart';

class PhiApp extends ConsumerWidget {
  const PhiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'PHI Smart Inspector',
      debugShowCheckedModeBanner: false,
      theme: PhiTheme.light(),
      builder: (context, child) => ConnectivitySync(child: child ?? const SizedBox.shrink()),
      home: session.when(
        data: (value) => value == null ? const LoginScreen() : const ScheduleScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => LoginScreen(errorMessage: error.toString()),
      ),
    );
  }
}
