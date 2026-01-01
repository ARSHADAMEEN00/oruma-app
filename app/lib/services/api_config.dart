import 'package:flutter/foundation.dart';

/// API Configuration for the Oruma app.
/// 
/// Contains the base URL and common headers for API requests.
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// Base URL for the API server.
  /// Uses localhost:3000 for web/desktop development.
  /// For mobile emulators, you may need to use:
  /// - Android Emulator: 10.0.2.2:3000
  /// - iOS Simulator: localhost:3000
  static String get baseUrl {
    if (kDebugMode) {
      if (kIsWeb) {
        return 'https://oruma-app.onrender.com/api';
      }
      // For Android emulator use 10.0.2.2, for iOS/Desktop use localhost
      return 'https://oruma-app.onrender.com/api';
    }
    return 'https://oruma-app.onrender.com/api';
  }

  /// Health check endpoint
  static String get healthUrl => kDebugMode 
    ? 'https://oruma-app.onrender.com/health'
    : 'https://oruma-app.onrender.com/health';

  /// API Endpoints
  static String get patientsEndpoint => '$baseUrl/patients';
  static String get homeVisitsEndpoint => '$baseUrl/home-visits';
  static String get equipmentEndpoint => '$baseUrl/equipment';
  static String get equipmentSuppliesEndpoint => '$baseUrl/equipment-supplies';
  static String get medicineSuppliesEndpoint => '$baseUrl/medicine-supplies';

  /// Default headers for API requests
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
}
