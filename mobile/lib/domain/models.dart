class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.mohArea,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String mohArea;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      mohArea: json['moh_area'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'moh_area': mohArea,
      };
}

class Premise {
  const Premise({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerName,
    required this.qrCode,
    required this.latitude,
    required this.longitude,
    required this.risk,
    required this.mohArea,
    required this.complianceScore,
    this.ownerPhone,
  });

  final String id;
  final String name;
  final String address;
  final String ownerName;
  final String? ownerPhone;
  final String qrCode;
  final double latitude;
  final double longitude;
  final String risk;
  final String mohArea;
  final int complianceScore;

  factory Premise.fromMap(Map<String, dynamic> map) {
    return Premise(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      ownerName: map['owner_name'] as String,
      ownerPhone: map['owner_phone'] as String?,
      qrCode: map['qr_code'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      risk: map['risk'] as String,
      mohArea: map['moh_area'] as String,
      complianceScore: map['compliance_score'] as int,
    );
  }
}

class ScheduledVisit {
  const ScheduledVisit({
    required this.id,
    required this.premiseId,
    required this.officerId,
    required this.visitDate,
    required this.reason,
    required this.status,
    this.inspectionId,
    this.notes,
  });

  final String id;
  final String premiseId;
  final String officerId;
  final String visitDate;
  final String reason;
  final String status;
  final String? inspectionId;
  final String? notes;

  factory ScheduledVisit.fromMap(Map<String, dynamic> map) {
    return ScheduledVisit(
      id: map['id'] as String,
      premiseId: map['premise_id'] as String,
      officerId: map['officer_id'] as String,
      visitDate: map['visit_date'] as String,
      reason: map['reason'] as String,
      status: map['status'] as String,
      inspectionId: map['inspection_id'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.templateId,
    required this.code,
    required this.title,
    required this.description,
    required this.sortOrder,
    this.legalHint,
  });

  final String id;
  final String templateId;
  final String code;
  final String title;
  final String description;
  final int sortOrder;
  final String? legalHint;

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      templateId: map['template_id'] as String,
      code: map['code'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      sortOrder: map['sort_order'] as int,
      legalHint: map['legal_hint'] as String?,
    );
  }
}

class InspectionRecord {
  const InspectionRecord({
    required this.id,
    required this.premiseId,
    required this.officerId,
    required this.templateId,
    required this.status,
    required this.startedAt,
    required this.gpsStatus,
    this.completedAt,
    this.startLat,
    this.startLng,
    this.submitLat,
    this.submitLng,
    this.followUpDate,
    this.notes,
    this.pdfPath,
  });

  final String id;
  final String premiseId;
  final String officerId;
  final String templateId;
  final String status;
  final String startedAt;
  final String? completedAt;
  final double? startLat;
  final double? startLng;
  final double? submitLat;
  final double? submitLng;
  final String gpsStatus;
  final String? followUpDate;
  final String? notes;
  final String? pdfPath;

  factory InspectionRecord.fromMap(Map<String, dynamic> map) {
    return InspectionRecord(
      id: map['id'] as String,
      premiseId: map['premise_id'] as String,
      officerId: map['officer_id'] as String,
      templateId: map['template_id'] as String,
      status: map['status'] as String,
      startedAt: map['started_at'] as String,
      completedAt: map['completed_at'] as String?,
      startLat: (map['start_lat'] as num?)?.toDouble(),
      startLng: (map['start_lng'] as num?)?.toDouble(),
      submitLat: (map['submit_lat'] as num?)?.toDouble(),
      submitLng: (map['submit_lng'] as num?)?.toDouble(),
      gpsStatus: map['gps_status'] as String? ?? 'unavailable',
      followUpDate: map['follow_up_date'] as String?,
      notes: map['notes'] as String?,
      pdfPath: map['pdf_path'] as String?,
    );
  }
}

class Complaint {
  const Complaint({
    required this.id,
    required this.trackingNo,
    this.premiseId,
    this.officerId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.receivedDate,
  });

  final String id;
  final String trackingNo;
  final String? premiseId;
  final String? officerId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String receivedDate;

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] as String,
      trackingNo: map['tracking_no'] as String,
      premiseId: map['premise_id'] as String?,
      officerId: map['officer_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String,
      priority: map['priority'] as String,
      status: map['status'] as String,
      receivedDate: map['received_date'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tracking_no': trackingNo,
      'premise_id': premiseId,
      'officer_id': officerId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'received_date': receivedDate,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

class DengueCase {
  const DengueCase({
    required this.id,
    required this.patientName,
    required this.address,
    required this.reportedDate,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
    required this.status,
    this.actionTaken,
    this.notes,
  });

  final String id;
  final String patientName;
  final String address;
  final String reportedDate;
  final double latitude;
  final double longitude;
  final String riskLevel; // 'low', 'medium', 'high', 'critical'
  final String status;    // 'active', 'investigated', 'cleared'
  final String? actionTaken;
  final String? notes;

  factory DengueCase.fromMap(Map<String, dynamic> map) {
    return DengueCase(
      id: map['id'] as String,
      patientName: map['patient_name'] as String,
      address: map['address'] as String,
      reportedDate: map['reported_date'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      riskLevel: map['risk_level'] as String? ?? 'high',
      status: map['status'] as String? ?? 'active',
      actionTaken: map['action_taken'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'address': address,
      'reported_date': reportedDate,
      'latitude': latitude,
      'longitude': longitude,
      'risk_level': riskLevel,
      'status': status,
      'action_taken': actionTaken,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

class FoodHandler {
  const FoodHandler({
    required this.id,
    required this.premiseId,
    required this.fullName,
    required this.nic,
    required this.role,
    required this.certificateNo,
    required this.issuedDate,
    required this.expiryDate,
    required this.status,
    this.notes,
  });

  final String id;
  final String premiseId;
  final String fullName;
  final String nic;
  final String role;
  final String certificateNo;
  final String issuedDate;
  final String expiryDate;
  final String status;
  final String? notes;

  factory FoodHandler.fromMap(Map<String, dynamic> map) {
    return FoodHandler(
      id: map['id'] as String,
      premiseId: map['premise_id'] as String,
      fullName: map['full_name'] as String,
      nic: map['nic'] as String? ?? '',
      role: map['role'] as String? ?? 'Food Handler',
      certificateNo: map['certificate_no'] as String? ?? '',
      issuedDate: map['issued_date'] as String? ?? '',
      expiryDate: map['expiry_date'] as String? ?? '',
      status: map['status'] as String? ?? 'valid',
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'premise_id': premiseId,
      'full_name': fullName,
      'nic': nic,
      'role': role,
      'certificate_no': certificateNo,
      'issued_date': issuedDate,
      'expiry_date': expiryDate,
      'status': status,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  int get daysUntilExpiry {
    try {
      final exp = DateTime.parse(expiryDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expDay = DateTime(exp.year, exp.month, exp.day);
      return expDay.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  String get calculatedStatus {
    final days = daysUntilExpiry;
    if (days < 0) return 'expired';
    if (days <= 30) return 'expiring_soon';
    return 'valid';
  }
}

class SampleRecord {
  const SampleRecord({
    required this.id,
    this.premiseId,
    required this.sampleType,
    required this.itemName,
    required this.sampleNo,
    required this.sampledDate,
    this.batchNo,
    required this.testType,
    required this.laboratory,
    required this.labResultStatus,
    this.resultDate,
    this.resultDetails,
    this.legalActionTaken,
    this.notes,
  });

  final String id;
  final String? premiseId;
  final String sampleType; // 'food' or 'water'
  final String itemName;
  final String sampleNo;
  final String sampledDate;
  final String? batchNo;
  final String testType;
  final String laboratory;
  final String labResultStatus; // 'pending', 'satisfactory', 'unsatisfactory'
  final String? resultDate;
  final String? resultDetails;
  final String? legalActionTaken;
  final String? notes;

  factory SampleRecord.fromMap(Map<String, dynamic> map) {
    return SampleRecord(
      id: map['id'] as String,
      premiseId: map['premise_id'] as String?,
      sampleType: map['sample_type'] as String? ?? 'food',
      itemName: map['item_name'] as String,
      sampleNo: map['sample_no'] as String? ?? '',
      sampledDate: map['sampled_date'] as String? ?? '',
      batchNo: map['batch_no'] as String?,
      testType: map['test_type'] as String? ?? '',
      laboratory: map['laboratory'] as String? ?? '',
      labResultStatus: map['lab_result_status'] as String? ?? 'pending',
      resultDate: map['result_date'] as String?,
      resultDetails: map['result_details'] as String?,
      legalActionTaken: map['legal_action_taken'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'premise_id': premiseId,
      'sample_type': sampleType,
      'item_name': itemName,
      'sample_no': sampleNo,
      'sampled_date': sampledDate,
      'batch_no': batchNo,
      'test_type': testType,
      'laboratory': laboratory,
      'lab_result_status': labResultStatus,
      'result_date': resultDate,
      'result_details': resultDetails,
      'legal_action_taken': legalActionTaken,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}



