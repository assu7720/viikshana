import 'package:hive_flutter/hive_flutter.dart';

const String _boxName = 'search_history';
const String _queriesKey = 'queries';
const int _maxQueries = 10;

Box<dynamic>? _searchHistoryBox;

/// Call from main() after Hive.initFlutter().
Future<void> initSearchHistoryBox() async {
  if (_searchHistoryBox != null && _searchHistoryBox!.isOpen) return;
  _searchHistoryBox = null;
  _searchHistoryBox = await Hive.openBox<dynamic>(_boxName);
}

/// Persists and retrieves search query history (max 10, most recent first).
class SearchHistoryRepository {
  Box<dynamic>? get _box => _searchHistoryBox;

  /// Returns up to [_maxQueries] recent queries, most recent first.
  List<String> getQueries() {
    final b = _box;
    if (b == null || !b.isOpen) return [];
    final raw = b.get(_queriesKey);
    if (raw is! List) return [];
    return raw
        .map((e) => e?.toString().trim())
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Appends [query] to history (move to front if already present), keeps max [_maxQueries].
  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final b = _box;
    if (b == null || !b.isOpen) return;
    List<String> list = getQueries();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > _maxQueries) list = list.sublist(0, _maxQueries);
    await b.put(_queriesKey, list);
  }

  /// Clears all search history.
  Future<void> clear() async {
    final b = _box;
    if (b == null || !b.isOpen) return;
    await b.put(_queriesKey, <String>[]);
  }
}
