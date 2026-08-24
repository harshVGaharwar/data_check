import 'dart:convert';

enum TemplateConfigType {
  staticUserDefined, // 1 entry, DymanicId=0, TemplateType=1
  staticUnimailing, // 1 entry, DymanicId=0, TemplateType=2
  dynamicUnimailing, // one entry per output key, sequential DymanicIds, TemplateType=3
  dynamicUserDefined, // one entry per output key, sequential DymanicIds, TemplateType=4
}

/// Parses the jsonData array from Template Configuration checker tray API.
///
/// Detection rules — TemplateType is authoritative:
///   TemplateType=1 → staticUserDefined     TemplateType=3 → dynamicUnimailing
///   TemplateType=2 → staticUnimailing      TemplateType=4 → dynamicUserDefined
/// Falls back to configs.length > 1 (sequential DymanicIds) → dynamicUnimailing
/// for older payloads that carry no TemplateType.
class TemplateConfigurationResponseModel {
  final List<Map<String, dynamic>> configs;

  const TemplateConfigurationResponseModel({required this.configs});

  factory TemplateConfigurationResponseModel.fromJsonData(dynamic raw) {
    final entries = <Map<String, dynamic>>[];

    void addEntry(dynamic item) {
      if (item is Map<String, dynamic>) {
        entries.add(item);
      } else if (item is Map) {
        entries.add(item.map((k, v) => MapEntry(k.toString(), v)));
      }
    }

    if (raw is List) {
      for (final item in raw) {
        addEntry(item);
      }
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            addEntry(item);
          }
        } else {
          addEntry(decoded);
        }
      } catch (_) {}
    } else {
      addEntry(raw);
    }

    return TemplateConfigurationResponseModel(configs: entries);
  }

  bool get hasData => configs.isNotEmpty;

  /// Determine template config type from the configs list.
  TemplateConfigType get type {
    if (configs.isNotEmpty) {
      final t = configs.first['TemplateType'];
      final typeInt = t is int ? t : int.tryParse(t?.toString() ?? '') ?? 0;
      switch (typeInt) {
        case 1:
          return TemplateConfigType.staticUserDefined;
        case 2:
          return TemplateConfigType.staticUnimailing;
        case 3:
          return TemplateConfigType.dynamicUnimailing;
        case 4:
          return TemplateConfigType.dynamicUserDefined;
      }
    }
    // No usable TemplateType — infer from the number of output-key entries.
    if (configs.length > 1) return TemplateConfigType.dynamicUnimailing;
    return TemplateConfigType.staticUserDefined;
  }

  bool get isStatic =>
      type == TemplateConfigType.staticUserDefined ||
      type == TemplateConfigType.staticUnimailing;

  bool get isDynamic =>
      type == TemplateConfigType.dynamicUnimailing ||
      type == TemplateConfigType.dynamicUserDefined;

  /// For static (1 entry): returns as-is.
  /// For dynamic (N entries): merges Sources, JoinMappings, Edges,
  /// connectedSources and outputColumns from ALL entries so
  /// ConfigPreviewSheet.showFromRaw receives the complete picture.
  Map<String, dynamic>? toConfigMap() {
    if (configs.isEmpty) return null;
    if (configs.length == 1) return configs.first;

    final sources = <Map<String, dynamic>>[];
    final joins = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];
    final connected = <Map<String, dynamic>>[];
    final outputCols = <Map<String, dynamic>>[];

    void addAll(Map<String, dynamic> c, String key, List<Map<String, dynamic>> out) {
      final raw = c[key];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            out.add(item);
          } else if (item is Map) {
            out.add(item.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }
    }

    for (final c in configs) {
      addAll(c, 'Sources', sources);
      addAll(c, 'JoinMappings', joins);
      addAll(c, 'Edges', edges);
      addAll(c, 'connectedSources', connected);
      addAll(c, 'outputColumns', outputCols);
    }

    return {
      ...configs.first,
      'Sources': sources,
      'JoinMappings': joins,
      'Edges': edges,
      'connectedSources': connected,
      'outputColumns': outputCols,
    };
  }
}
