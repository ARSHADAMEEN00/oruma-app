/// Patient model that matches the backend schema.
class Patient {
  final String? id;
  final String name;
  final String relation;
  final String gender;
  final String address;
  final String phone;
  final String? phone2;
  final int age;
  final String place;
  final String village;
  final List<String> disease;
  final String plan;
  final String? locationLink;
  final String? registerId;
  final DateTime? registrationDate; // User-controlled registration date
  final bool isDead;
  final DateTime? dateOfDeath;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Patient({
    this.id,
    required this.name,
    required this.relation,
    required this.gender,
    required this.address,
    this.phone = '',
    this.phone2,
    required this.age,
    required this.place,
    required this.village,
    this.disease = const [],
    required this.plan,
    this.locationLink,
    this.registerId,
    this.registrationDate,
    this.isDead = false,
    this.dateOfDeath,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Patient from JSON (API response).
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      phone2: json['phone2']?.toString(),
      age: (json['age'] is int)
          ? json['age'] as int
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      place: json['place']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      disease: json['disease'] is List
          ? List<String>.from(json['disease'])
          : json['disease'] != null
          ? [json['disease'].toString()]
          : [],
      plan: json['plan']?.toString() ?? '',
      locationLink: json['locationLink']?.toString(),
      registerId: json['registerId']?.toString(),
      registrationDate: json['registrationDate'] != null
          ? DateTime.tryParse(json['registrationDate'].toString())
          : null,
      isDead: json['isDead'] == true,
      dateOfDeath: json['dateOfDeath'] != null
          ? DateTime.tryParse(json['dateOfDeath'].toString())
          : null,
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

  /// Convert Patient to JSON for API requests.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'gender': gender,
      'address': address,
      'phone': phone,
      'phone2': phone2,
      'age': age,
      'place': place,
      'village': village,
      'disease': disease,
      'plan': plan,
      'locationLink': locationLink,
      'registerId': registerId,
      'registrationDate': registrationDate?.toIso8601String(),
      'isDead': isDead,
      'dateOfDeath': dateOfDeath?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Patient copyWith({
    String? id,
    String? name,
    String? relation,
    String? gender,
    String? address,
    String? phone,
    String? phone2,
    int? age,
    String? place,
    String? village,
    List<String>? disease,
    String? plan,
    String? locationLink,
    String? registerId,
    DateTime? registrationDate,
    bool? isDead,
    DateTime? dateOfDeath,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      age: age ?? this.age,
      place: place ?? this.place,
      village: village ?? this.village,
      disease: disease ?? this.disease,
      plan: plan ?? this.plan,
      locationLink: locationLink ?? this.locationLink,
      registerId: registerId ?? this.registerId,
      registrationDate: registrationDate ?? this.registrationDate,
      isDead: isDead ?? this.isDead,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'Patient(id: $id, name: $name, village: $village, disease: $disease)';
  }
}

class PatientCounts {
  final int allCount;
  final int deadCount;
  final int aliveCount;

  PatientCounts({
    required this.allCount,
    required this.deadCount,
    required this.aliveCount,
  });

  factory PatientCounts.fromJson(Map<String, dynamic> json) {
    return PatientCounts(
      allCount: json['allCount'] as int? ?? 0,
      deadCount: json['deadCount'] as int? ?? 0,
      aliveCount: json['aliveCount'] as int? ?? 0,
    );
  }
}

class PatientListResponse {
  final List<Patient> patients;
  final PatientCounts counts;

  PatientListResponse({
    required this.patients,
    required this.counts,
  });

  factory PatientListResponse.fromJson(Map<String, dynamic> json) {
    return PatientListResponse(
      patients: (json['patients'] as List<dynamic>?)
              ?.map((e) => Patient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      counts: PatientCounts.fromJson(
          json['counts'] as Map<String, dynamic>? ?? {}),
    );
  }
}
