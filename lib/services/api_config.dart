import 'package:flutter/foundation.dart';

/// API Configuration for the Oruma app.
///
/// Contains the base URL and common headers for API requests.
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// Base URL for the API server.
  /// Uses localhost:5001 for web/desktop development.
  /// For mobile emulators, you may need to use:
  /// - Android Emulator: http://10.0.2.2:5001/api
  /// - iOS Simulator: http://localhost:5001/api
  static String get baseUrl {
    if (kDebugMode) {
      if (kIsWeb) {
        // Chrome: localhost resolves correctly
        return 'http://localhost:5001/api';
      }
      // Android emulator maps host localhost to 10.0.2.2
      return 'http://10.0.2.2:5001/api';
    }
    return 'https://api-erp-palliative.osperb.com/api';
  }

  /// Health check endpoint
  static String get healthUrl => kDebugMode
      ? 'http://localhost:5001/health'
      : 'https://api-erp-palliative.osperb.com/health';

  /// API Endpoints
  static String get patientsEndpoint => '$baseUrl/patients';
  static String get v2PatientsEndpoint => '$baseUrl/v2/patients';
  static String get v2MedicinesEndpoint => '$baseUrl/v2/medicines';
  static String get homeVisitsEndpoint => '$baseUrl/home-visits';
  static String get v2VisitAssessmentsEndpoint =>
      '$baseUrl/v2/visit-assessments';
  static String get equipmentEndpoint => '$baseUrl/equipment';
  static String get equipmentSuppliesEndpoint => '$baseUrl/equipment-supplies';
  static String get notificationsEndpoint => '$baseUrl/notifications';
  static String get billingPortalEndpoint => '$baseUrl/billing/me';
  static String get billingEnquiriesEndpoint => '$baseUrl/billing/enquiries';
  static String get medicineSuppliesEndpoint => '$baseUrl/medicine-supplies';
  static String get v2MedicineSuppliesEndpoint =>
      '$baseUrl/v2/medicine-supplies';
  static String get v2MedicineStockEntriesEndpoint =>
      '$baseUrl/v2/medicine-stock-entries';
  static String get v2SocialSupportEndpoint => '$baseUrl/v2/social-support';
  static String get v2VolunteersEndpoint => '$baseUrl/v2/volunteers';
  static String get meEndpoint => '$baseUrl/auth/me';
  static String get staffEndpoint => '$baseUrl/auth/staff';

  /// Default headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
}
