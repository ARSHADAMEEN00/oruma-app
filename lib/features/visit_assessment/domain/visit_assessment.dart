class VisitVitals {
  final int? pulse;
  final String pulseRhythm;
  final int? bpSystolic;
  final int? bpDiastolic;
  final String bpPosition;
  final int? respiratoryRate;
  final double? temperature;
  final String temperatureUnit;
  final String temperatureMethod;
  final int? spo2;
  final int? grbs;
  final String activityLevel;
  final String stability;

  const VisitVitals({
    this.pulse,
    this.pulseRhythm = 'R',
    this.bpSystolic,
    this.bpDiastolic,
    this.bpPosition = 'UL',
    this.respiratoryRate,
    this.temperature,
    this.temperatureUnit = 'C',
    this.temperatureMethod = 'O',
    this.spo2,
    this.grbs,
    this.activityLevel = 'III',
    this.stability = 'stable',
  });

  factory VisitVitals.fromJson(Map<String, dynamic>? json) {
    final value = json ?? const {};
    return VisitVitals(
      pulse: _toInt(value['pulse']),
      pulseRhythm: value['pulseRhythm']?.toString() ?? 'R',
      bpSystolic: _toInt(value['bpSystolic']),
      bpDiastolic: _toInt(value['bpDiastolic']),
      bpPosition: value['bpPosition']?.toString() ?? 'UL',
      respiratoryRate: _toInt(value['rr']),
      temperature: _toDouble(value['temp']),
      temperatureUnit: value['tempUnit']?.toString() ?? 'C',
      temperatureMethod: value['tempMethod']?.toString() ?? 'O',
      spo2: _toInt(value['spo2']),
      grbs: _toInt(value['grbs']),
      activityLevel: value['activityLevel']?.toString() ?? 'III',
      stability: value['stability']?.toString() ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() => {
    'pulse': pulse,
    'pulseRhythm': pulseRhythm,
    'bpSystolic': bpSystolic,
    'bpDiastolic': bpDiastolic,
    'bpPosition': bpPosition,
    'rr': respiratoryRate,
    'temp': temperature,
    'tempUnit': temperatureUnit,
    'tempMethod': temperatureMethod,
    'spo2': spo2,
    'grbs': grbs,
    'activityLevel': activityLevel,
    'stability': stability,
  };

  VisitVitals copyWith({
    int? pulse,
    bool clearPulse = false,
    String? pulseRhythm,
    int? bpSystolic,
    bool clearBpSystolic = false,
    int? bpDiastolic,
    bool clearBpDiastolic = false,
    String? bpPosition,
    int? respiratoryRate,
    bool clearRespiratoryRate = false,
    double? temperature,
    bool clearTemperature = false,
    String? temperatureUnit,
    String? temperatureMethod,
    int? spo2,
    bool clearSpo2 = false,
    int? grbs,
    bool clearGrbs = false,
    String? activityLevel,
    String? stability,
  }) {
    return VisitVitals(
      pulse: clearPulse ? null : pulse ?? this.pulse,
      pulseRhythm: pulseRhythm ?? this.pulseRhythm,
      bpSystolic: clearBpSystolic ? null : bpSystolic ?? this.bpSystolic,
      bpDiastolic: clearBpDiastolic ? null : bpDiastolic ?? this.bpDiastolic,
      bpPosition: bpPosition ?? this.bpPosition,
      respiratoryRate: clearRespiratoryRate
          ? null
          : respiratoryRate ?? this.respiratoryRate,
      temperature: clearTemperature ? null : temperature ?? this.temperature,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      temperatureMethod: temperatureMethod ?? this.temperatureMethod,
      spo2: clearSpo2 ? null : spo2 ?? this.spo2,
      grbs: clearGrbs ? null : grbs ?? this.grbs,
      activityLevel: activityLevel ?? this.activityLevel,
      stability: stability ?? this.stability,
    );
  }
}

class AssessmentMedicine {
  final String? id;
  final String? medicineId;
  final String medicineName;
  final String strength;
  final Set<String> routes;
  final String duration;
  final String remarks;

  const AssessmentMedicine({
    this.id,
    this.medicineId,
    required this.medicineName,
    this.strength = '',
    this.routes = const {'P'},
    this.duration = '',
    this.remarks = '',
  });

  factory AssessmentMedicine.fromJson(Map<String, dynamic> json) {
    final legacyRoutes = <String>[
      if (json['routeOral'] == true) 'P',
      if (json['routeGastro'] == true) 'G',
      if (json['routeSC'] == true) 'S',
      if (json['routeOther'] == true) 'O',
    ];
    return AssessmentMedicine(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      medicineId: _idValue(json['medicineId']),
      medicineName: json['medicineName']?.toString() ?? '',
      strength: json['strength']?.toString() ?? '',
      routes: json['routes'] is List
          ? (json['routes'] as List).map((item) => item.toString()).toSet()
          : legacyRoutes.toSet(),
      duration: json['duration']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'medicineId': medicineId,
    'medicineName': medicineName,
    'strength': strength,
    'routes': routes.toList(),
    'duration': duration,
    'remarks': remarks,
  };

  AssessmentMedicine copyWith({
    String? medicineId,
    String? medicineName,
    String? strength,
    Set<String>? routes,
    String? duration,
    String? remarks,
  }) {
    return AssessmentMedicine(
      id: id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      strength: strength ?? this.strength,
      routes: routes ?? this.routes,
      duration: duration ?? this.duration,
      remarks: remarks ?? this.remarks,
    );
  }
}

class ExamFinding {
  final String status;
  final String value;
  final String notes;
  final List<String> images;

  const ExamFinding({
    this.status = 'not_assessed',
    this.value = '',
    this.notes = '',
    this.images = const [],
  });

  factory ExamFinding.fromJson(dynamic json) {
    if (json is String) {
      return ExamFinding(
        status: json.trim().isEmpty ? 'not_assessed' : 'normal',
        notes: json,
      );
    }
    if (json is! Map) return const ExamFinding();
    return ExamFinding(
      status: json['status']?.toString() ?? 'not_assessed',
      value: json['value']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      images: (json['images'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'value': value,
    'notes': notes,
    'images': images,
  };

  ExamFinding copyWith({
    String? status,
    String? value,
    String? notes,
    List<String>? images,
  }) {
    return ExamFinding(
      status: status ?? this.status,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      images: images ?? this.images,
    );
  }
}

const assessmentExamKeys = <String>[
  'respiration',
  'foodWater',
  'urine',
  'defecation',
  'sleep',
  'hygiene',
  'outdoorAccess',
  'sexuality',
  'scalpHair',
  'skin',
  'eyeNoseMouth',
  'oral',
  'nails',
  'perineum',
  'pressureArea',
  'hiddenArea',
  'musclesJoints',
  'specialAttention',
];

Map<String, ExamFinding> emptyPhysicalExam() => {
  for (final key in assessmentExamKeys) key: const ExamFinding(),
};

class AssessmentCarePlan {
  final Set<String> visitPlans;
  final Set<String> services;

  const AssessmentCarePlan({
    this.visitPlans = const {'NHC'},
    this.services = const {},
  });

  factory AssessmentCarePlan.fromJson(Map<String, dynamic>? json) {
    final value = json ?? const {};
    final legacyVisitPlans = <String>{
      for (final option in ['DHC', 'NHC', 'GVHC', 'other'])
        if (value[option] == true) option,
    };
    final legacyServices = <String>{
      for (final option in [
        'healthEducation',
        'familyTraining',
        'physiotherapy',
        'dayCare',
        'socialSupport',
        'medicineSupport',
      ])
        if (value[option] == true) option,
    };
    return AssessmentCarePlan(
      visitPlans: value['visitPlans'] is List
          ? (value['visitPlans'] as List).map((item) => item.toString()).toSet()
          : legacyVisitPlans,
      services: value['services'] is List
          ? (value['services'] as List).map((item) => item.toString()).toSet()
          : legacyServices,
    );
  }

  Map<String, dynamic> toJson() => {
    'visitPlans': visitPlans.toList(),
    'services': services.toList(),
  };

  AssessmentCarePlan copyWith({
    Set<String>? visitPlans,
    Set<String>? services,
  }) {
    return AssessmentCarePlan(
      visitPlans: visitPlans ?? this.visitPlans,
      services: services ?? this.services,
    );
  }
}

class VisitAssessment {
  final String? id;
  final String homeVisitId;
  final String patientId;
  final String patientName;
  final String regNo;
  final DateTime visitDate;
  final String timeFrom;
  final String timeTo;
  final String team;
  final String visitType;
  final VisitVitals vitals;
  final List<AssessmentMedicine> medicines;
  final Map<String, ExamFinding> physicalExam;
  final String medicineRemarks;
  final String nursingDiagnosis;
  final String doctorConsultNotes;
  final String nursingManagementPlan;
  final String complementary;
  final AssessmentCarePlan carePlan;
  final String teamMeetingDiscussion;
  final String nurseName;
  final String? nurseId;
  final String signatureUrl;
  final bool confirmed;
  final String status;
  final bool isComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  VisitAssessment({
    this.id,
    required this.homeVisitId,
    required this.patientId,
    required this.patientName,
    required this.regNo,
    required this.visitDate,
    this.timeFrom = '',
    this.timeTo = '',
    this.team = 'Team Oruma',
    this.visitType = 'NHC',
    this.vitals = const VisitVitals(),
    this.medicines = const [],
    Map<String, ExamFinding>? physicalExam,
    this.medicineRemarks = '',
    this.nursingDiagnosis = '',
    this.doctorConsultNotes = '',
    this.nursingManagementPlan = '',
    this.complementary = 'Nil',
    this.carePlan = const AssessmentCarePlan(),
    this.teamMeetingDiscussion = '',
    this.nurseName = '',
    this.nurseId,
    this.signatureUrl = '',
    this.confirmed = false,
    this.status = 'draft',
    this.isComplete = false,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
  }) : physicalExam = physicalExam ?? emptyPhysicalExam();

  factory VisitAssessment.fromJson(Map<String, dynamic> json) {
    final examJson = json['physicalExam'] is Map<String, dynamic>
        ? json['physicalExam'] as Map<String, dynamic>
        : <String, dynamic>{};
    final patient = json['patientId'];
    return VisitAssessment(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      homeVisitId: _idValue(json['homeVisitId']) ?? '',
      patientId: _idValue(patient) ?? '',
      patientName: patient is Map
          ? patient['name']?.toString() ?? ''
          : json['patientName']?.toString() ?? '',
      regNo:
          json['regNo']?.toString() ??
          (patient is Map ? patient['registerId']?.toString() ?? '' : ''),
      visitDate:
          DateTime.tryParse(json['visitDate']?.toString() ?? '') ??
          DateTime.now(),
      timeFrom: json['timeFrom']?.toString() ?? '',
      timeTo: json['timeTo']?.toString() ?? '',
      team: json['team']?.toString() ?? 'Team Oruma',
      visitType: json['visitType']?.toString() ?? 'NHC',
      vitals: VisitVitals.fromJson(json['vitals'] as Map<String, dynamic>?),
      medicines: (json['medicines'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AssessmentMedicine.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      physicalExam: {
        for (final key in assessmentExamKeys)
          key: ExamFinding.fromJson(examJson[key]),
      },
      medicineRemarks: json['medicineRemarks']?.toString() ?? '',
      nursingDiagnosis: json['nursingDiagnosis']?.toString() ?? '',
      doctorConsultNotes: json['doctorConsultNotes']?.toString() ?? '',
      nursingManagementPlan: json['nursingManagementPlan']?.toString() ?? '',
      complementary: json['complementary']?.toString() ?? 'Nil',
      carePlan: AssessmentCarePlan.fromJson(
        json['carePlan'] as Map<String, dynamic>?,
      ),
      teamMeetingDiscussion: json['teamMeetingDiscussion']?.toString() ?? '',
      nurseName: json['nurseName']?.toString() ?? '',
      nurseId: _idValue(json['nurseId']),
      signatureUrl: json['signatureUrl']?.toString() ?? '',
      confirmed: json['confirmed'] == true,
      status:
          json['status']?.toString() ??
          (json['isComplete'] == true ? 'submitted' : 'draft'),
      isComplete: json['isComplete'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'homeVisitId': homeVisitId,
    'patientId': patientId,
    'patientName': patientName,
    'regNo': regNo,
    'visitDate': visitDate.toIso8601String(),
    'timeFrom': timeFrom,
    'timeTo': timeTo,
    'team': team,
    'visitType': visitType,
    'vitals': vitals.toJson(),
    'medicines': medicines.map((item) => item.toJson()).toList(),
    'physicalExam': {
      for (final entry in physicalExam.entries) entry.key: entry.value.toJson(),
    },
    'medicineRemarks': medicineRemarks,
    'nursingDiagnosis': nursingDiagnosis,
    'doctorConsultNotes': doctorConsultNotes,
    'nursingManagementPlan': nursingManagementPlan,
    'complementary': complementary,
    'carePlan': carePlan.toJson(),
    'teamMeetingDiscussion': teamMeetingDiscussion,
    'nurseName': nurseName,
    'nurseId': nurseId,
    'signatureUrl': signatureUrl,
    'confirmed': confirmed,
    'status': status,
    'isComplete': isComplete,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
  };

  VisitAssessment copyWith({
    String? id,
    String? patientName,
    String? regNo,
    DateTime? visitDate,
    String? timeFrom,
    String? timeTo,
    String? team,
    String? visitType,
    VisitVitals? vitals,
    List<AssessmentMedicine>? medicines,
    Map<String, ExamFinding>? physicalExam,
    String? medicineRemarks,
    String? nursingDiagnosis,
    String? doctorConsultNotes,
    String? nursingManagementPlan,
    String? complementary,
    AssessmentCarePlan? carePlan,
    String? teamMeetingDiscussion,
    String? nurseName,
    String? nurseId,
    String? signatureUrl,
    bool? confirmed,
    String? status,
    bool? isComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
  }) {
    return VisitAssessment(
      id: id ?? this.id,
      homeVisitId: homeVisitId,
      patientId: patientId,
      patientName: patientName ?? this.patientName,
      regNo: regNo ?? this.regNo,
      visitDate: visitDate ?? this.visitDate,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
      team: team ?? this.team,
      visitType: visitType ?? this.visitType,
      vitals: vitals ?? this.vitals,
      medicines: medicines ?? this.medicines,
      physicalExam: physicalExam ?? this.physicalExam,
      medicineRemarks: medicineRemarks ?? this.medicineRemarks,
      nursingDiagnosis: nursingDiagnosis ?? this.nursingDiagnosis,
      doctorConsultNotes: doctorConsultNotes ?? this.doctorConsultNotes,
      nursingManagementPlan:
          nursingManagementPlan ?? this.nursingManagementPlan,
      complementary: complementary ?? this.complementary,
      carePlan: carePlan ?? this.carePlan,
      teamMeetingDiscussion:
          teamMeetingDiscussion ?? this.teamMeetingDiscussion,
      nurseName: nurseName ?? this.nurseName,
      nurseId: nurseId ?? this.nurseId,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      confirmed: confirmed ?? this.confirmed,
      status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

String? _idValue(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString();
  }
  return value.toString();
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
