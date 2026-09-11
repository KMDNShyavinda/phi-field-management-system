import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'phi_offline.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    await _seedDengueIfEmpty(_db!);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT,
        full_name TEXT,
        role TEXT,
        moh_area TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE premises (
        id TEXT PRIMARY KEY,
        name TEXT,
        address TEXT,
        owner_name TEXT,
        owner_phone TEXT,
        qr_code TEXT UNIQUE,
        latitude REAL,
        longitude REAL,
        risk TEXT,
        moh_area TEXT,
        compliance_score INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE checklist_templates (
        id TEXT PRIMARY KEY,
        name TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        template_id TEXT,
        code TEXT,
        title TEXT,
        description TEXT,
        sort_order INTEGER,
        legal_hint TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE scheduled_visits (
        id TEXT PRIMARY KEY,
        premise_id TEXT,
        officer_id TEXT,
        visit_date TEXT,
        reason TEXT,
        status TEXT,
        inspection_id TEXT,
        notes TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE inspections (
        id TEXT PRIMARY KEY,
        premise_id TEXT,
        officer_id TEXT,
        template_id TEXT,
        status TEXT,
        started_at TEXT,
        completed_at TEXT,
        start_lat REAL,
        start_lng REAL,
        submit_lat REAL,
        submit_lng REAL,
        gps_status TEXT,
        follow_up_date TEXT,
        notes TEXT,
        pdf_path TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE inspection_answers (
        id TEXT PRIMARY KEY,
        inspection_id TEXT,
        item_id TEXT,
        result TEXT,
        notes TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE evidence_photos (
        id TEXT PRIMARY KEY,
        inspection_id TEXT,
        item_id TEXT,
        sha256 TEXT,
        captured_at TEXT,
        latitude REAL,
        longitude REAL,
        storage_path TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE violations (
        id TEXT PRIMARY KEY,
        inspection_id TEXT,
        item_id TEXT,
        notice_type TEXT,
        legal_provision TEXT,
        deadline TEXT,
        accepted INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE signatures (
        id TEXT PRIMARY KEY,
        inspection_id TEXT,
        signer_role TEXT,
        signer_name TEXT,
        image_path TEXT,
        image_b64 TEXT,
        signed_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_outbox (
        id TEXT PRIMARY KEY,
        op_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_uploads (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        local_path TEXT NOT NULL,
        photo_id TEXT,
        inspection_id TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE complaints (
        id TEXT PRIMARY KEY,
        tracking_no TEXT,
        premise_id TEXT,
        officer_id TEXT,
        title TEXT,
        description TEXT,
        priority TEXT,
        status TEXT,
        received_date TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await _createDengueTable(db);
  }

  Future<void> _createDengueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dengue_cases (
        id TEXT PRIMARY KEY,
        patient_name TEXT,
        address TEXT,
        reported_date TEXT,
        latitude REAL,
        longitude REAL,
        risk_level TEXT,
        status TEXT,
        action_taken TEXT,
        notes TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _seedDengueIfEmpty(Database db) async {
    await _createDengueTable(db);
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM dengue_cases');
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    if (count == 0) {
      final now = DateTime.now().toIso8601String();
      await db.insert('dengue_cases', {
        'id': 'D-2401',
        'patient_name': 'Kamal Gunaratne',
        'address': 'No 45, Temple Road, Colombo 10',
        'reported_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
        'latitude': 6.9275,
        'longitude': 79.8615,
        'risk_level': 'high',
        'status': 'active',
        'action_taken': 'Warning notice issued',
        'notes': 'High larval density in gutters. 100m radius inspection in progress.',
        'updated_at': now,
      });
      await db.insert('dengue_cases', {
        'id': 'D-2402',
        'patient_name': 'S. K. Perera',
        'address': '12/B, Galle Road, Kollupitiya',
        'reported_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
        'latitude': 6.9030,
        'longitude': 79.8545,
        'risk_level': 'critical',
        'status': 'active',
        'action_taken': 'Fogging scheduled',
        'notes': 'Positive NS1 antigen. Commercial premises nearby require immediate check.',
        'updated_at': now,
      });
      await db.insert('dengue_cases', {
        'id': 'D-2403',
        'patient_name': 'Nimali Silva',
        'address': '88, Ward Place, Colombo 07',
        'reported_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String().substring(0, 10),
        'latitude': 6.9125,
        'longitude': 79.8620,
        'risk_level': 'medium',
        'status': 'investigated',
        'action_taken': 'Larvicide applied',
        'notes': 'Premises inspected. Discarded containers safely disposed.',
        'updated_at': now,
      });
      await db.insert('dengue_cases', {
        'id': 'D-2404',
        'patient_name': 'M. Farook',
        'address': '15, Central Road, Colombo 13',
        'reported_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String().substring(0, 10),
        'latitude': 6.9380,
        'longitude': 79.8520,
        'risk_level': 'low',
        'status': 'cleared',
        'action_taken': 'Premise cleared & fogged',
        'notes': 'Area clear. Second inspection completed without larvae.',
        'updated_at': now,
      });
    }
  }

  Future<void> upsert(String table, Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> all(String table, {String? where, List<Object?>? args, String? orderBy}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: args, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> premiseByQr(String raw) async {
    final db = await database;
    final code = raw.trim();
    final rows = await db.query(
      'premises',
      where: 'qr_code = ? OR id = ?',
      whereArgs: [code, _idFromQr(code)],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  String _idFromQr(String code) {
    const prefix = 'phi://premise/';
    if (code.startsWith(prefix)) return code.substring(prefix.length);
    return code;
  }

  Future<String?> meta(String key) async {
    final db = await database;
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    await upsert('sync_meta', {'key': key, 'value': value});
  }

  Future<void> enqueue(String id, String opType, Map<String, dynamic> payload) async {
    await upsert('sync_outbox', {
      'id': id,
      'op_type': opType,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> outbox() async {
    return all('sync_outbox', orderBy: 'created_at ASC');
  }

  Future<void> removeOutbox(String id) async {
    final db = await database;
    await db.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addPendingUpload({
    required String id,
    required String kind,
    required String localPath,
    required String inspectionId,
    String? photoId,
  }) async {
    await upsert('pending_uploads', {
      'id': id,
      'kind': kind,
      'local_path': localPath,
      'photo_id': photoId,
      'inspection_id': inspectionId,
    });
  }

  Future<List<Map<String, dynamic>>> pendingUploads() => all('pending_uploads');

  Future<void> removePendingUpload(String id) async {
    final db = await database;
    await db.delete('pending_uploads', where: 'id = ?', whereArgs: [id]);
  }
}
