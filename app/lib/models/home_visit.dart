/// HomeVisit model that matches the backend schema.
class HomeVisit {
  final String? id;
  final String patientName;
  final String address;
  final String visitDate; // ISO date string
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HomeVisit({
    this.id,
    required this.patientName,
    required this.address,
    required this.visitDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Create HomeVisit from JSON (API response).
  factory HomeVisit.fromJson(Map<String, dynamic> json) {
    return HomeVisit(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      patientName: json['patientName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      visitDate: json['visitDate']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Convert HomeVisit to JSON for API requests.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'patientName': patientName,
      'address': address,
      'visitDate': visitDate,
    };
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }
    return map;
  }

  /// Create a copy with updated fields.
  HomeVisit copyWith({
    String? id,
    String? patientName,
    String? address,
    String? visitDate,
    String? notes,
  }) {
    return HomeVisit(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      address: address ?? this.address,
      visitDate: visitDate ?? this.visitDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'HomeVisit(id: $id, patientName: $patientName, visitDate: $visitDate)';
  }
}
