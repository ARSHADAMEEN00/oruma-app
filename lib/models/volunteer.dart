import 'package:oruma_app/models/config.dart';

class Volunteer {
  final String? id;
  final String village;
  final String ward;
  final String place;
  final String name;
  final String phone;
  final dynamic createdBy;
  final dynamic updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Volunteer({
    this.id,
    required this.village,
    required this.ward,
    required this.place,
    required this.name,
    required this.phone,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      village: json['village']?.toString() ?? '',
      ward: normalizeWardNumberValue(json['ward']),
      place: json['place']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'village': village,
      'ward': normalizeWardNumberValue(ward),
      'place': place,
      'name': name,
      'phone': phone,
    };
  }

  Volunteer copyWith({
    String? id,
    String? village,
    String? ward,
    String? place,
    String? name,
    String? phone,
    dynamic createdBy,
    dynamic updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Volunteer(
      id: id ?? this.id,
      village: village ?? this.village,
      ward: ward ?? this.ward,
      place: place ?? this.place,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get wardLabel => ward.isEmpty ? 'Ward' : 'Ward $ward';

  String get locationLabel {
    return [
      if (place.trim().isNotEmpty) place.trim(),
      if (village.trim().isNotEmpty) village.trim(),
      if (ward.trim().isNotEmpty) wardLabel,
    ].join(' • ');
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return [
      name,
      phone,
      place,
      village,
      ward,
      wardLabel,
    ].join(' ').toLowerCase().contains(normalized);
  }
}
