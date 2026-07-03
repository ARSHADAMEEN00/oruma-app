import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';

import 'equipment_supply.dart';
import 'home_visit.dart';
import 'medicine_supply.dart';
import 'patient.dart';
import 'social_support.dart';

class PatientCreator {
  final String? id;
  final String name;
  final String? email;
  final String? role;

  const PatientCreator({this.id, required this.name, this.email, this.role});

  factory PatientCreator.fromJson(Map<String, dynamic> json) {
    return PatientCreator(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class PatientDetails {
  final Patient patient;
  final PatientCreator? creator;
  final List<HomeVisit> homeVisits;
  final List<EquipmentSupply> equipmentSupplies;
  final List<VisitAssessment> visitAssessments;
  final List<MedicineSupply> medicineSupplies;
  final List<SocialSupport> socialSupports;

  const PatientDetails({
    required this.patient,
    this.creator,
    this.homeVisits = const [],
    this.equipmentSupplies = const [],
    this.visitAssessments = const [],
    this.medicineSupplies = const [],
    this.socialSupports = const [],
  });

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      patient: Patient.fromJson(
        json['patient'] as Map<String, dynamic>? ?? const {},
      ),
      creator: json['creator'] is Map<String, dynamic>
          ? PatientCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      homeVisits: (json['homeVisits'] as List<dynamic>? ?? const [])
          .map((item) => HomeVisit.fromJson(item as Map<String, dynamic>))
          .toList(),
      equipmentSupplies:
          (json['equipmentSupplies'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    EquipmentSupply.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      visitAssessments: (json['visitAssessments'] as List<dynamic>? ?? const [])
          .map((item) => VisitAssessment.fromJson(item as Map<String, dynamic>))
          .toList(),
      medicineSupplies: (json['medicineSupplies'] as List<dynamic>? ?? const [])
          .map((item) => MedicineSupply.fromJson(item as Map<String, dynamic>))
          .toList(),
      socialSupports: (json['socialSupports'] as List<dynamic>? ?? const [])
          .map((item) => SocialSupport.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
