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
