import '../models/medicine_stock_entry.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'app_cache.dart';

class MedicineStockService {
  MedicineStockService._();

  static const _prefix = 'medicine_stock_entries:';
  static const _keyHistory = 'medicine_stock_entries:history';
  static const _ttl = Duration(minutes: 5);

  static Future<List<MedicineStockEntry>> getHistory({String? search}) async {
    final trimmed = search?.trim();
    final hasSearch = trimmed != null && trimmed.isNotEmpty;
    if (hasSearch) {
      return _fetchHistory(search: trimmed);
    }

    return AppCache.get<List<MedicineStockEntry>>(
      _keyHistory,
      ttl: _ttl,
      loader: _fetchHistory,
    );
  }

  static Future<List<MedicineStockEntry>> _fetchHistory({
    String? search,
  }) async {
    var url = ApiConfig.v2MedicineStockEntriesEndpoint;
    if (search != null && search.trim().isNotEmpty) {
      url += '?search=${Uri.encodeQueryComponent(search.trim())}';
    }

    final result = await ApiService.get<List<dynamic>>(url);
    if (result.isSuccess && result.data != null) {
      return result.data!
          .map(
            (json) => MedicineStockEntry.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception(result.error ?? 'Failed to fetch medicine stock history');
  }

  static Future<List<MedicineStockEntry>> createBulkStockEntries(
    List<MedicineStockEntryDraft> entries,
  ) async {
    final result = await ApiService.post<Map<String, dynamic>>(
      '${ApiConfig.v2MedicineStockEntriesEndpoint}/bulk',
      body: {'entries': entries.map((entry) => entry.toJson()).toList()},
    );

    if (result.isSuccess && result.data != null) {
      AppCache.invalidatePrefix(_prefix);
      AppCache.invalidatePrefix('medicines:');

      final rawEntries = result.data!['entries'] as List<dynamic>? ?? const [];
      return rawEntries
          .map(
            (json) => MedicineStockEntry.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception(result.error ?? 'Failed to add medicine stock');
  }

  static void invalidateCache() {
    AppCache.invalidatePrefix(_prefix);
  }
}
