import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../api/api_client.dart';
import '../db/app_database.dart';

class SyncService {
  SyncService(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;
  bool _running = false;

  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> syncNow() async {
    if (_running) return;
    if (!await isOnline()) return;
    _running = true;
    try {
      await _pushOutbox();
      await _uploadPending();
      await _pull();
    } finally {
      _running = false;
    }
  }

  Future<void> _pull() async {
    final since = await _db.meta('last_pulled_at');
    final payload = await _api.pull(since: since);
    await _upsertList('users', payload['users']);
    await _upsertList('premises', payload['premises']);
    await _upsertList('checklist_templates', payload['checklist_templates']);
    await _upsertList('checklist_items', payload['checklist_items']);
    await _upsertList('scheduled_visits', payload['scheduled_visits']);
    await _upsertList('inspections', payload['inspections']);
    await _upsertList('inspection_answers', payload['inspection_answers']);
    await _upsertList('evidence_photos', payload['evidence_photos']);
    await _upsertList('violations', payload['violations']);
    await _upsertList('signatures', payload['signatures']);
    final serverTime = payload['server_time'] as String? ?? DateTime.now().toUtc().toIso8601String();
    await _db.setMeta('last_pulled_at', serverTime);
  }

  Future<void> _upsertList(String table, dynamic rows) async {
    if (rows is! List) return;
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        await _db.upsert(table, _flatten(row));
      } else if (row is Map) {
        await _db.upsert(table, _flatten(Map<String, dynamic>.from(row)));
      }
    }
  }

  Map<String, dynamic> _flatten(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value is bool) return MapEntry(key, value ? 1 : 0);
      if (value is Map || value is List) return MapEntry(key, jsonEncode(value));
      return MapEntry(key, value);
    });
  }

  Future<void> _pushOutbox() async {
    final rows = await _db.outbox();
    if (rows.isEmpty) return;
    final ops = [
      for (final row in rows)
        {
          'type': row['op_type'],
          'payload': jsonDecode(row['payload'] as String),
        },
    ];
    final result = await _api.push(ops);
    if ((result['errors'] as List? ?? []).isEmpty) {
      for (final row in rows) {
        await _db.removeOutbox(row['id'] as String);
      }
    }
  }

  Future<void> _uploadPending() async {
    for (final row in await _db.pendingUploads()) {
      final file = File(row['local_path'] as String);
      if (!file.existsSync()) {
        await _db.removePendingUpload(row['id'] as String);
        continue;
      }
      if (row['kind'] == 'photo') {
        await _api.uploadPhoto(
          photoId: row['photo_id'] as String,
          inspectionId: row['inspection_id'] as String,
          file: file,
        );
      } else {
        await _api.uploadReport(inspectionId: row['inspection_id'] as String, file: file);
      }
      await _db.removePendingUpload(row['id'] as String);
    }
  }
}
