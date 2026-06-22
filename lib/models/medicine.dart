class MedicineUserSummary {
  final String? id;
  final String? name;
  final String? email;
  final String? role;

  const MedicineUserSummary({this.id, this.name, this.email, this.role});

  factory MedicineUserSummary.fromJson(Map<String, dynamic> json) {
    return MedicineUserSummary(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class Medicine {
  final String? id;
  final String code;
  final String? barcode;
  final String name;
  final List<String> brandNames;
  final String category;
  final String? formulation;
  final double? strength;
  final String? strengthUnit;
  final double qty;
  final String? qtyUnit;
  final DateTime? expiryDate;
  final String? batchNumber;
  final String? description;
  final List<String> photos;
  final bool isActive;
  final MedicineUserSummary? createdBy;
  final MedicineUserSummary? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Medicine({
    this.id,
    required this.code,
    this.barcode,
    required this.name,
    this.brandNames = const [],
    this.category = 'other',
    this.formulation,
    this.strength,
    this.strengthUnit,
    this.qty = 0,
    this.qtyUnit,
    this.expiryDate,
    this.batchNumber,
    this.description,
    this.photos = const [],
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      code: json['code']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      name: json['name']?.toString() ?? '',
      brandNames: (json['brandNames'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      category: json['category']?.toString() ?? 'other',
      formulation: json['formulation']?.toString(),
      strength: _toDouble(json['strength']),
      strengthUnit: json['strengthUnit']?.toString(),
      qty: _toDouble(json['qty']) ?? 0,
      qtyUnit: json['qtyUnit']?.toString(),
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.tryParse(json['expiryDate'].toString()),
      batchNumber: json['batchNumber']?.toString(),
      description: json['description']?.toString(),
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      isActive: json['isActive'] != false,
      createdBy: _userFromJson(json['createdBy']),
      updatedBy: _userFromJson(json['updatedBy']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'barcode': barcode,
      'name': name,
      'brandNames': brandNames,
      'category': category,
      'formulation': formulation,
      'strength': strength,
      'strengthUnit': strengthUnit,
      'qty': qty,
      'qtyUnit': qtyUnit,
      'expiryDate': expiryDate?.toIso8601String(),
      'batchNumber': batchNumber,
      'description': description,
      'photos': photos,
      'isActive': isActive,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static MedicineUserSummary? _userFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MedicineUserSummary.fromJson(value);
    }
    return null;
  }
}
