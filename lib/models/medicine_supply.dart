/// MedicineSupply model that matches the v2 backend schema.
class MedicineSupply {
  final String? id;
  final dynamic patientId; // Can be String ID or Map
  final dynamic medicineId; // Can be String ID or Map
  final dynamic givenByStaff; // Can be String ID or Map
  final DateTime givenAt;
  final int qtyGiven;
  final String? status;
  final String? staffNote;
  final String? prescribedBy;
  final String? doctorPrescription;
  final int? supplyDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicineSupply({
    this.id,
    required this.patientId,
    required this.medicineId,
    required this.givenByStaff,
    required this.givenAt,
    required this.qtyGiven,
    this.status = 'given',
    this.staffNote,
    this.prescribedBy,
    this.doctorPrescription,
    this.supplyDays,
    this.createdAt,
    this.updatedAt,
  });

  /// Create MedicineSupply from JSON (API response).
  factory MedicineSupply.fromJson(Map<String, dynamic> json) {
    return MedicineSupply(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      patientId: json['patientId'],
      medicineId: json['medicineId'],
      givenByStaff: json['givenByStaff'],
      givenAt: json['givenAt'] != null 
          ? DateTime.tryParse(json['givenAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      qtyGiven: (json['qtyGiven'] is num)
          ? (json['qtyGiven'] as num).toInt()
          : int.tryParse(json['qtyGiven']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString(),
      staffNote: json['staffNote']?.toString(),
      prescribedBy: json['prescribedBy']?.toString(),
      doctorPrescription: json['doctorPrescription']?.toString(),
      supplyDays: (json['supplyDays'] is num)
          ? (json['supplyDays'] as num).toInt()
          : int.tryParse(json['supplyDays']?.toString() ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Convert MedicineSupply to JSON for API requests.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'patientId': _getId(patientId),
      'medicineId': _getId(medicineId),
      'givenByStaff': _getId(givenByStaff),
      'givenAt': givenAt.toIso8601String(),
      'qtyGiven': qtyGiven,
    };
    
    if (status != null) map['status'] = status;
    if (staffNote != null) map['staffNote'] = staffNote;
    if (prescribedBy != null) map['prescribedBy'] = prescribedBy;
    if (doctorPrescription != null) map['doctorPrescription'] = doctorPrescription;
    if (supplyDays != null) map['supplyDays'] = supplyDays;
    
    return map;
  }
  
  static String? _getId(dynamic field) {
    if (field == null) return null;
    if (field is String) return field;
    if (field is Map && field['_id'] != null) return field['_id'].toString();
    if (field is Map && field['id'] != null) return field['id'].toString();
    return field.toString();
  }

  /// Helper methods to safely get populated fields
  String get patientName {
    if (patientId is Map) return patientId['name']?.toString() ?? 'Unknown';
    return 'Unknown';
  }

  String get medicineName {
    if (medicineId is Map) return medicineId['name']?.toString() ?? 'Unknown';
    return 'Unknown';
  }

  String get staffName {
    if (givenByStaff is Map) return givenByStaff['name']?.toString() ?? 'Unknown';
    return 'Unknown';
  }

  MedicineSupply copyWith({
    String? id,
    dynamic patientId,
    dynamic medicineId,
    dynamic givenByStaff,
    DateTime? givenAt,
    int? qtyGiven,
    String? status,
    String? staffNote,
    String? prescribedBy,
    String? doctorPrescription,
    int? supplyDays,
  }) {
    return MedicineSupply(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      medicineId: medicineId ?? this.medicineId,
      givenByStaff: givenByStaff ?? this.givenByStaff,
      givenAt: givenAt ?? this.givenAt,
      qtyGiven: qtyGiven ?? this.qtyGiven,
      status: status ?? this.status,
      staffNote: staffNote ?? this.staffNote,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      doctorPrescription: doctorPrescription ?? this.doctorPrescription,
      supplyDays: supplyDays ?? this.supplyDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
