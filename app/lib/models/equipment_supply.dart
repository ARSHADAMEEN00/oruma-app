class EquipmentSupply {
  final String? id;
  final String equipmentId;
  final String equipmentUniqueId;
  final String equipmentName;
  final String patientName;
  final String patientPhone;
  final String? patientAddress;
  final DateTime supplyDate;
  final DateTime? returnDate;
  final DateTime? actualReturnDate;
  final String status; // 'active', 'returned', 'lost'
  final String? notes;
  final String? createdBy;

  const EquipmentSupply({
    this.id,
    required this.equipmentId,
    required this.equipmentUniqueId,
    required this.equipmentName,
    required this.patientName,
    required this.patientPhone,
    this.patientAddress,
    required this.supplyDate,
    this.returnDate,
    this.actualReturnDate,
    this.status = 'active',
    this.notes,
    this.createdBy,
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
      supplyDate: DateTime.tryParse(json['supplyDate']?.toString() ?? '') ?? DateTime.now(),
      returnDate: json['returnDate'] != null 
          ? DateTime.tryParse(json['returnDate'].toString()) 
          : null,
      actualReturnDate: json['actualReturnDate'] != null 
          ? DateTime.tryParse(json['actualReturnDate'].toString()) 
          : null,
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['name']?.toString()
          : json['createdBy']?.toString(),
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
      'supplyDate': supplyDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}
