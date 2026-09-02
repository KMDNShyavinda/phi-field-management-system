import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/legal_rules.dart';
import '../../domain/models.dart';
import '../db/app_database.dart';
import '../location/gps.dart';
import 'report_pdf.dart';

class InspectionRepository {
  InspectionRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<String> startInspection({
    required Premise premise,
    required SessionUser officer,
    String? visitId,
  }) async {
    final templates = await _db.all('checklist_templates', orderBy: 'name');
    if (templates.isEmpty) {
      throw StateError('Checklist has not been synced yet. Connect once after login.');
    }
    final templateId = templates.first['id'] as String;
    final gps = await captureGps();
    final now = DateTime.now().toUtc().toIso8601String();
    final id = _uuid.v4();
    final row = {
      'id': id,
      'premise_id': premise.id,
      'officer_id': officer.id,
      'template_id': templateId,
      'status': 'draft',
      'started_at': now,
      'completed_at': null,
      'start_lat': gps.lat,
      'start_lng': gps.lng,
      'submit_lat': null,
      'submit_lng': null,
      'gps_status': gps.status,
      'follow_up_date': null,
      'notes': null,
      'pdf_path': null,
      'updated_at': now,
    };
    await _db.upsert('inspections', row);
    await _db.enqueue(_uuid.v4(), 'upsert_inspection', row);
    if (visitId != null) {
      final visit = await _db.getById('scheduled_visits', visitId);
      if (visit != null) {
        final updated = {
          ...visit,
          'status': 'in_progress',
          'inspection_id': id,
          'updated_at': now,
        };
        await _db.upsert('scheduled_visits', updated);
        await _db.enqueue(_uuid.v4(), 'upsert_visit', updated);
      }
    }
    return id;
  }

  Future<void> saveAnswer({
    required String inspectionId,
    required String itemId,
    required String result,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await _db.all(
      'inspection_answers',
      where: 'inspection_id = ? AND item_id = ?',
      args: [inspectionId, itemId],
    );
    final id = existing.isEmpty ? _uuid.v4() : existing.first['id'] as String;
    final row = {
      'id': id,
      'inspection_id': inspectionId,
      'item_id': itemId,
      'result': result,
      'notes': notes,
      'updated_at': now,
    };
    await _db.upsert('inspection_answers', row);
    await _db.enqueue(_uuid.v4(), 'upsert_answer', row);
  }

  Future<void> attachPhoto({
    required String inspectionId,
    required String itemId,
    required File source,
  }) async {
    final gps = await captureGps();
    final bytes = await source.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final id = _uuid.v4();
    final dir = await getApplicationDocumentsDirectory();
    final photos = Directory(p.join(dir.path, 'photos'));
    await photos.create(recursive: true);
    final dest = File(p.join(photos.path, '$id.jpg'));
    await dest.writeAsBytes(bytes, flush: true);
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'id': id,
      'inspection_id': inspectionId,
      'item_id': itemId,
      'sha256': hash,
      'captured_at': now,
      'latitude': gps.lat,
      'longitude': gps.lng,
      'storage_path': dest.path,
      'updated_at': now,
    };
    await _db.upsert('evidence_photos', row);
    await _db.enqueue(_uuid.v4(), 'upsert_photo_meta', row);
    await _db.addPendingUpload(
      id: _uuid.v4(),
      kind: 'photo',
      localPath: dest.path,
      inspectionId: inspectionId,
      photoId: id,
    );
  }

  Future<List<Map<String, dynamic>>> suggestedViolations(String inspectionId) async {
    final answers = await _db.all('inspection_answers', where: 'inspection_id = ?', args: [inspectionId]);
    final items = {for (final item in await _db.all('checklist_items')) item['id']: item};
    final out = <Map<String, dynamic>>[];
    for (final answer in answers) {
      if (answer['result'] != 'fail') continue;
      final item = items[answer['item_id']] as Map<String, dynamic>?;
      if (item == null) continue;
      final suggestion = suggestNotice(item['code'] as String);
      final deadline = DateTime.now().toUtc().add(Duration(days: suggestion.days));
      out.add({
        'item_id': item['id'],
        'item_title': item['title'],
        'item_code': item['code'],
        'notice_type': suggestion.noticeType,
        'legal_provision': suggestion.provision,
        'deadline': deadline.toIso8601String().substring(0, 10),
        'accepted': 1,
      });
    }
    return out;
  }

  Future<void> saveViolations(String inspectionId, List<Map<String, dynamic>> violations) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (final violation in violations) {
      final row = {
        'id': _uuid.v4(),
        'inspection_id': inspectionId,
        'item_id': violation['item_id'],
        'notice_type': violation['notice_type'],
        'legal_provision': violation['legal_provision'],
        'deadline': violation['deadline'],
        'accepted': violation['accepted'] == true || violation['accepted'] == 1 ? 1 : 0,
        'updated_at': now,
      };
      await _db.upsert('violations', row);
      await _db.enqueue(_uuid.v4(), 'upsert_violation', {
        ...row,
        'accepted': row['accepted'] == 1,
      });
    }
  }

  Future<void> saveSignature({
    required String inspectionId,
    required String role,
    required String name,
    required Uint8List pngBytes,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(dir.path, 'signatures'));
    await destDir.create(recursive: true);
    final dest = File(p.join(destDir.path, '$inspectionId-$role.png'));
    await dest.writeAsBytes(pngBytes, flush: true);
    final existing = await _db.all(
      'signatures',
      where: 'inspection_id = ? AND signer_role = ?',
      args: [inspectionId, role],
    );
    final id = existing.isEmpty ? _uuid.v4() : existing.first['id'] as String;
    final row = {
      'id': id,
      'inspection_id': inspectionId,
      'signer_role': role,
      'signer_name': name,
      'image_path': dest.path,
      'image_b64': base64Encode(pngBytes),
      'signed_at': now,
      'updated_at': now,
    };
    await _db.upsert('signatures', row);
    await _db.enqueue(_uuid.v4(), 'upsert_signature', row);
  }

  Future<File> completeInspection({
    required String inspectionId,
    required String visitId,
    required Premise premise,
    required SessionUser officer,
  }) async {
    final gps = await captureGps();
    final now = DateTime.now().toUtc();
    final inspection = await _db.getById('inspections', inspectionId);
    if (inspection == null) {
      throw StateError('Inspection missing');
    }
    final violations = await _db.all('violations', where: 'inspection_id = ?', args: [inspectionId]);
    String? followUp;
    if (violations.isNotEmpty) {
      followUp = violations
          .map((row) => row['deadline'] as String)
          .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    }
    final updated = {
      ...inspection,
      'status': 'completed',
      'completed_at': now.toIso8601String(),
      'submit_lat': gps.lat,
      'submit_lng': gps.lng,
      'gps_status': gps.status == 'unavailable' ? inspection['gps_status'] : gps.status,
      'follow_up_date': followUp,
      'updated_at': now.toIso8601String(),
    };

    final pdfFile = await buildInspectionPdf(
      db: _db,
      inspection: updated,
      premise: premise,
      officer: officer,
    );
    updated['pdf_path'] = pdfFile.path;
    await _db.upsert('inspections', updated);
    await _db.enqueue(_uuid.v4(), 'upsert_inspection', updated);
    await _db.addPendingUpload(
      id: _uuid.v4(),
      kind: 'report',
      localPath: pdfFile.path,
      inspectionId: inspectionId,
    );

    final visit = await _db.getById('scheduled_visits', visitId);
    if (visit != null) {
      final done = {
        ...visit,
        'status': 'completed',
        'inspection_id': inspectionId,
        'updated_at': now.toIso8601String(),
      };
      await _db.upsert('scheduled_visits', done);
      await _db.enqueue(_uuid.v4(), 'upsert_visit', done);
    }

    if (followUp != null) {
      final followId = _uuid.v4();
      final followVisit = {
        'id': followId,
        'premise_id': premise.id,
        'officer_id': officer.id,
        'visit_date': followUp,
        'reason': 'follow_up',
        'status': 'pending',
        'inspection_id': inspectionId,
        'notes': 'Auto-scheduled after improvement notice',
        'updated_at': now.toIso8601String(),
      };
      await _db.upsert('scheduled_visits', followVisit);
      await _db.enqueue(_uuid.v4(), 'upsert_visit', followVisit);
    }
    return pdfFile;
  }
}
