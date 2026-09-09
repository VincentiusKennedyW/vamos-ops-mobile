import 'package:get/get.dart';

/// Session-only cache: never persists photos, tokens, or another user's records.
class OpsCache extends GetxService {
  final _entries = <String, ({Object value, DateTime time})>{};
  int epoch = 0;
  T? read<T>(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.time) > const Duration(minutes: 5)) {
      return null;
    }
    _entries[key] = entry;
    return entry.value is T ? entry.value as T : null;
  }

  void write(String key, Object value) {
    _entries.remove(key);
    _entries[key] = (value: value, time: DateTime.now());
    while (_entries.length > 24) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() {
    epoch++;
    _entries.clear();
  }
}

class CachedList<T> {
  CachedList(List<T> items, this.page, this.hasMore)
    : items = List.unmodifiable(items);
  final List<T> items;
  final int page;
  final bool hasMore;
}
