import 'dart:async';

/// Lightweight in-memory patient store.
/// Replace with API/database integration when ready.
class PatientService {
  static final List<Patient> _patients = [];

  static Future<bool> createPatient(Patient patient) async {
    // Simulate async I/O.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _patients.add(patient);
    return true;
  }

  static List<Patient> allPatients() => List.unmodifiable(_patients);
}

class Patient {
  final String name;
  final String relation;
  final String gender;
  final String address;
  final int age;
  final String place;
  final String village;
  final String disease;
  final String plan;

  Patient({
    required this.name,
    required this.relation,
    required this.gender,
    required this.address,
    required this.age,
    required this.place,
    required this.village,
    required this.disease,
    required this.plan,
  });
}

