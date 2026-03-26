class WardConfig {
  final String title;
  final String village;

  WardConfig({required this.title, required this.village});

  factory WardConfig.fromJson(Map<String, dynamic> json) {
    return WardConfig(
      title: json['title'] as String? ?? '',
      village: json['village'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'village': village,
    };
  }
}

class Config {
  final String? id;
  final List<String> villages;
  final List<String> diseases;
  final List<String> plans;
  final List<WardConfig> wards;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Config({
    this.id,
    required this.villages,
    required this.diseases,
    required this.plans,
    required this.wards,
    this.createdAt,
    this.updatedAt,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      id: json['id'] as String?,
      villages: (json['villages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      diseases: (json['diseases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      plans: (json['plans'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      wards: (json['wards'] as List<dynamic>?)
              ?.map((e) => WardConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'villages': villages,
      'diseases': diseases,
      'plans': plans,
      'wards': wards.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
