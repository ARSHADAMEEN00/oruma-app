class EquipmentSupply {
  final String? id;
  final String equipmentId;
  final String equipmentUniqueId;
  final String equipmentName;
  final String patientName;
  final String patientPhone;
  final String? patientAddress;
  final String? careOf;
  final String? receiverName;
  final String? receiverPhone;
  final DateTime supplyDate;
  final DateTime? returnDate;
  final DateTime? actualReturnDate;
  final String status; // 'active', 'returned', 'lost'
  final String? notes;
  final String? returnNote;
  final String? createdBy;
  final DateTime? createdAt;

  const EquipmentSupply({
    this.id,
    required this.equipmentId,
    required this.equipmentUniqueId,
    required this.equipmentName,
    required this.patientName,
    required this.patientPhone,
    this.patientAddress,
    this.careOf,
    this.receiverName,
    this.receiverPhone,
    required this.supplyDate,
    this.returnDate,
    this.actualReturnDate,
    this.status = 'active',
    this.notes,
    this.returnNote,
    this.createdBy,
    this.createdAt,
  });

  factory EquipmentSupply.fromJson(Map<String, dynamic> json) {
    return EquipmentSupply(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      equipmentId: json['equipmentId']?.toString() ?? '',
      equipmentUniqueId: json['equipmentUniqueId']?.toString() ?? '',
      equipmentName: json['equipmentName']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      patientPhone: json['patientPhone']?.toString() ?? '',
      patientAddress: json['patientAddress']?.toString(),
      careOf: json['careOf']?.toString(),
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),
      supplyDate:
          DateTime.tryParse(json['supplyDate']?.toString() ?? '') ??
          DateTime.now(),
      returnDate: json['returnDate'] != null
          ? DateTime.tryParse(json['returnDate'].toString())
          : null,
      actualReturnDate: json['actualReturnDate'] != null
          ? DateTime.tryParse(json['actualReturnDate'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      returnNote: json['returnNote']?.toString(),
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['name']?.toString()
          : json['createdBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipmentId': equipmentId,
      'equipmentUniqueId': equipmentUniqueId,
      'equipmentName': equipmentName,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientAddress': patientAddress,
      'careOf': careOf,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'supplyDate': supplyDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'actualReturnDate': actualReturnDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'returnNote': returnNote,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
