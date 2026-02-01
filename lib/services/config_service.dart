import 'package:oruma_app/models/config.dart';
import 'package:oruma_app/services/api_config.dart';
import 'package:oruma_app/services/api_service.dart';

/// Service for fetching application configuration data.
class ConfigService {
  /// Fetch configuration data from the API.
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
}
