/// MedicineSupply model that matches the backend schema.
class MedicineSupply {
  final String? id;
  final String patientName;
  final String medicine;
  final int quantity;
  final String phone;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicineSupply({
    this.id,
    required this.patientName,
    required this.medicine,
    required this.quantity,
    required this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  /// Create MedicineSupply from JSON (API response).
  factory MedicineSupply.fromJson(Map<String, dynamic> json) {
    return MedicineSupply(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      patientName: json['patientName']?.toString() ?? '',
      medicine: json['medicine']?.toString() ?? '',
      quantity: (json['quantity'] is int)
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
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
      'patientName': patientName,
      'medicine': medicine,
      'quantity': quantity,
      'phone': phone,
    };
    if (address != null && address!.isNotEmpty) {
      map['address'] = address;
    }
    return map;
  }

  /// Create a copy with updated fields.
  MedicineSupply copyWith({
    String? id,
    String? patientName,
    String? medicine,
    int? quantity,
    String? phone,
    String? address,
  }) {
    return MedicineSupply(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'MedicineSupply(id: $id, patientName: $patientName, medicine: $medicine)';
  }
}
