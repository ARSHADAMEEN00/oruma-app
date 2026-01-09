/// HomeVisit model that matches the backend schema.
class HomeVisit {
  final String? id;
  final String patientName;
  final String address;
  final String visitDate; // ISO date string
  final String visitMode; // 'monthly', 'emergency', 'new'
  final String? team;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HomeVisit({
    this.id,
    required this.patientName,
    required this.address,
    required this.visitDate,
    this.visitMode = 'new',
    this.team,
    this.notes,
    this.createdBy,
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
      visitMode: json['visitMode']?.toString() ?? 'new',
      team: json['team']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['name']?.toString()
          : json['createdBy']?.toString(),
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
      'visitMode': visitMode,
    };
    if (team != null && team!.isNotEmpty) {
      map['team'] = team;
    }
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
    String? visitMode,
    String? team,
    String? notes,
  }) {
    return HomeVisit(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      address: address ?? this.address,
      visitDate: visitDate ?? this.visitDate,
      visitMode: visitMode ?? this.visitMode,
      team: team ?? this.team,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'HomeVisit(id: $id, patientName: $patientName, visitDate: $visitDate, visitMode: $visitMode, team: $team)';
  }
}
