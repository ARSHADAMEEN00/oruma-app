class Config {
  final String? id;
  final List<String> villages;
  final List<String> diseases;
  final List<String> plans;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Config({
    this.id,
    required this.villages,
    required this.diseases,
    required this.plans,
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
