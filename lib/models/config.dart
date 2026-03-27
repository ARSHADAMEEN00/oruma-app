final RegExp _naturalSortPattern = RegExp(r'\d+|\D+');

int compareNaturally(String a, String b) {
  final aParts = _naturalSortPattern
      .allMatches(a)
      .map((m) => m.group(0)!)
      .toList();
  final bParts = _naturalSortPattern
      .allMatches(b)
      .map((m) => m.group(0)!)
      .toList();
  final partsToCompare =
      aParts.length < bParts.length ? aParts.length : bParts.length;

  for (var i = 0; i < partsToCompare; i++) {
    final aPart = aParts[i];
    final bPart = bParts[i];
    final aNumber = int.tryParse(aPart);
    final bNumber = int.tryParse(bPart);

    if (aNumber != null && bNumber != null) {
      final numberCompare = aNumber.compareTo(bNumber);
      if (numberCompare != 0) {
        return numberCompare;
      }

      final digitLengthCompare = aPart.length.compareTo(bPart.length);
      if (digitLengthCompare != 0) {
        return digitLengthCompare;
      }

      continue;
    }

    final textCompare = aPart.toLowerCase().compareTo(bPart.toLowerCase());
    if (textCompare != 0) {
      return textCompare;
    }
  }

  final lengthCompare = aParts.length.compareTo(bParts.length);
  if (lengthCompare != 0) {
    return lengthCompare;
  }

  return a.toLowerCase().compareTo(b.toLowerCase());
}

int compareWardTitles(String a, String b) {
  return compareNaturally(a.trim(), b.trim());
}

int compareWardConfigs(WardConfig a, WardConfig b) {
  final villageCompare =
      compareNaturally(a.village.trim(), b.village.trim());
  if (villageCompare != 0) {
    return villageCompare;
  }

  return compareWardTitles(a.title, b.title);
}

List<WardConfig> sortWardConfigs(Iterable<WardConfig> wards) {
  final sorted = wards.toList()..sort(compareWardConfigs);
  return sorted;
}

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
