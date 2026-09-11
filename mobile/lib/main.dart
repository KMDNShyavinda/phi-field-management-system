import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

import 'package:phi_mobile/core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Init notifications
  final notifService = NotificationService();
  await notifService.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: const PhiApp(),
    ),
  );
}
