import 'package:oruma_app/models/config.dart';
import 'package:oruma_app/services/api_config.dart';
import 'package:oruma_app/services/api_service.dart';

/// Service for fetching application configuration data.
class ConfigService {
  static Future<Config> getConfig() async {
    final url = '${ApiConfig.baseUrl}/config';
    final result = await ApiService.get<Config>(
      url,
      fromJson: (json) => Config.fromJson(json),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw Exception(result.error ?? 'Failed to fetch configuration');
    }
  }

  /// Update configuration data.
  static Future<Config> updateConfig(Config config) async {
    final url = '${ApiConfig.baseUrl}/config';
    final result = await ApiService.put<Config>(
      url,
      body: config.toJson(),
      fromJson: (json) => Config.fromJson(json),
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw Exception(result.error ?? 'Failed to update configuration');
    }
  }
}
