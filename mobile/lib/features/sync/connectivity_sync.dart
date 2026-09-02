import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class ConnectivitySync extends ConsumerStatefulWidget {
  const ConnectivitySync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivitySync> createState() => _ConnectivitySyncState();
}

class _ConnectivitySyncState extends ConsumerState<ConnectivitySync> {
  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        ref.read(syncServiceProvider).syncNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
