/// Reads a value from JSON map, checking both camelCase and snake_case keys.
/// [camelKey] is the preferred camelCase key; snake_case is derived automatically.
T? getJson<T>(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey] as T?;
  final snakeKey = camelToSnake(camelKey);
  if (json.containsKey(snakeKey)) return json[snakeKey] as T?;
  return null;
}

T getJsonOrDefault<T>(Map<String, dynamic> json, String camelKey, T defaultValue) {
  final val = getJson<T>(json, camelKey);
  return val ?? defaultValue;
}

String camelToSnake(String key) {
  return key.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

/// Converts snake_case keys to camelCase in a map.
Map<String, dynamic> normalizeSnakeKeys(Map<String, dynamic> json) {
  final result = <String, dynamic>{};
  for (final entry in json.entries) {
    result[snakeToCamel(entry.key)] = entry.value;
  }
  return result;
}

String snakeToCamel(String key) {
  final parts = key.split('_');
  if (parts.length == 1) return key;
  return parts[0] + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// Recursively converts snake_case keys in lists/maps to camelCase.
dynamic normalizeResponse(dynamic data) {
  if (data is List) {
    return data.map((e) => normalizeResponse(e)).toList();
  }
  if (data is Map<String, dynamic>) {
    final normalized = normalizeSnakeKeys(data);
    for (final key in normalized.keys.toList()) {
      normalized[key] = normalizeResponse(normalized[key]);
    }
    return normalized;
  }
  return data;
}
