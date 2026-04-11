/// JSON types for Luma `.luma` export files.
library;

const int lumaFormatVersion = 1;

/// Options controlling what is included in an export.
final class ExportOptions {
  const ExportOptions({
    required this.includePeriods,
    required this.includeSymptoms,
    required this.includeNotes,
    this.password,
  });

  factory ExportOptions.everything({String? password}) => ExportOptions(
        includePeriods: true,
        includeSymptoms: true,
        includeNotes: true,
        password: password,
      );

  factory ExportOptions.periodsOnly({String? password}) => ExportOptions(
        includePeriods: true,
        includeSymptoms: false,
        includeNotes: false,
        password: password,
      );

  final bool includePeriods;
  final bool includeSymptoms;
  final bool includeNotes;
  final String? password;
}

/// Top-level metadata for a Luma export file.
final class LumaExportMeta {
  const LumaExportMeta({
    required this.formatVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.encrypted,
    required this.contentTypes,
  });

  final int formatVersion;
  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final bool encrypted;
  final List<String> contentTypes;

  Map<String, dynamic> toJson() => {
        'format_version': formatVersion,
        'schema_version': schemaVersion,
        'app_version': appVersion,
        'exported_at': exportedAt.toUtc().toIso8601String(),
        'encrypted': encrypted,
        'content_types': contentTypes,
      };

  factory LumaExportMeta.fromJson(Map<String, dynamic> json) {
    void requireKey(String key) {
      if (!json.containsKey(key) || json[key] == null) {
        throw FormatException('LumaExportMeta missing required field: $key');
      }
    }

    requireKey('format_version');
    requireKey('schema_version');
    requireKey('app_version');
    requireKey('exported_at');
    requireKey('encrypted');
    requireKey('content_types');

    final exportedRaw = json['exported_at'];
    if (exportedRaw is! String) {
      throw FormatException(
        'LumaExportMeta.exported_at must be a String, got ${exportedRaw.runtimeType}',
      );
    }

    final contentRaw = json['content_types'];
    if (contentRaw is! List) {
      throw FormatException(
        'LumaExportMeta.content_types must be a List, got ${contentRaw.runtimeType}',
      );
    }

    return LumaExportMeta(
      formatVersion: _asInt(json['format_version'], 'format_version'),
      schemaVersion: _asInt(json['schema_version'], 'schema_version'),
      appVersion: json['app_version']!.toString(),
      exportedAt: DateTime.parse(exportedRaw).toUtc(),
      encrypted: json['encrypted'] == true,
      contentTypes: contentRaw.map((e) => e.toString()).toList(),
    );
  }
}

/// One exported period span (file-local [refId], not the DB primary key).
final class ExportedPeriod {
  const ExportedPeriod({
    required this.refId,
    required this.startUtc,
    this.endUtc,
  });

  final int refId;
  final String startUtc;
  final String? endUtc;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'ref_id': refId,
      'start_utc': startUtc,
    };
    if (endUtc != null) {
      map['end_utc'] = endUtc;
    }
    return map;
  }

  factory ExportedPeriod.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('ref_id') || json['ref_id'] == null) {
      throw FormatException('ExportedPeriod missing required field: ref_id');
    }
    if (!json.containsKey('start_utc') || json['start_utc'] == null) {
      throw FormatException('ExportedPeriod missing required field: start_utc');
    }
    return ExportedPeriod(
      refId: _asInt(json['ref_id'], 'ref_id'),
      startUtc: json['start_utc']!.toString(),
      endUtc: json['end_utc']?.toString(),
    );
  }
}

/// One exported day-entry row.
final class ExportedDayEntry {
  const ExportedDayEntry({
    required this.periodRefId,
    required this.dateUtc,
    this.flowIntensity,
    this.painScore,
    this.mood,
    this.notes,
    this.personalNotes,
    this.personalNotesIncludedInExport = false,
  });

  final int periodRefId;
  final String dateUtc;
  final int? flowIntensity;
  final int? painScore;
  final int? mood;
  final String? notes;
  final String? personalNotes;
  /// When false, import must not overwrite an existing `personal_notes` value
  /// (older backups omit the JSON key).
  final bool personalNotesIncludedInExport;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'period_ref_id': periodRefId,
      'date_utc': dateUtc,
    };
    if (flowIntensity != null) {
      map['flow_intensity'] = flowIntensity;
    }
    if (painScore != null) {
      map['pain_score'] = painScore;
    }
    if (mood != null) {
      map['mood'] = mood;
    }
    if (notes != null) {
      map['notes'] = notes;
    }
    if (personalNotes != null) {
      map['personal_notes'] = personalNotes;
    }
    return map;
  }

  factory ExportedDayEntry.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('period_ref_id') || json['period_ref_id'] == null) {
      throw FormatException(
        'ExportedDayEntry missing required field: period_ref_id',
      );
    }
    if (!json.containsKey('date_utc') || json['date_utc'] == null) {
      throw FormatException('ExportedDayEntry missing required field: date_utc');
    }
    final personalKeyPresent = json.containsKey('personal_notes');
    return ExportedDayEntry(
      periodRefId: _asInt(json['period_ref_id'], 'period_ref_id'),
      dateUtc: json['date_utc']!.toString(),
      flowIntensity: _optionalInt(json['flow_intensity']),
      painScore: _optionalInt(json['pain_score']),
      mood: _optionalInt(json['mood']),
      notes: json['notes']?.toString(),
      personalNotes: json['personal_notes']?.toString(),
      personalNotesIncludedInExport: personalKeyPresent,
    );
  }
}

/// Full export payload (unencrypted JSON shape).
final class LumaExportData {
  const LumaExportData({
    required this.meta,
    this.periods,
    this.dayEntries,
  });

  final LumaExportMeta meta;
  final List<ExportedPeriod>? periods;
  final List<ExportedDayEntry>? dayEntries;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (periods != null) {
      data['periods'] = periods!.map((e) => e.toJson()).toList();
    }
    if (dayEntries != null) {
      data['day_entries'] = dayEntries!.map((e) => e.toJson()).toList();
    }
    return {
      'meta': meta.toJson(),
      'data': data,
    };
  }

  factory LumaExportData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('meta') || json['meta'] is! Map) {
      throw FormatException('LumaExportData missing meta object');
    }
    if (!json.containsKey('data') || json['data'] is! Map) {
      throw FormatException('LumaExportData missing data object');
    }
    final meta = LumaExportMeta.fromJson(
      Map<String, dynamic>.from(json['meta']! as Map),
    );
    return LumaExportData.fromJsonData(
      meta,
      Map<String, dynamic>.from(json['data']! as Map),
    );
  }

  /// Parses the inner `data` object (values under the `data` key).
  factory LumaExportData.fromJsonData(
    LumaExportMeta meta,
    Map<String, dynamic> dataMap,
  ) {
    List<ExportedPeriod>? periodsList;
    if (dataMap.containsKey('periods')) {
      final raw = dataMap['periods'];
      if (raw is! List) {
        throw FormatException('data.periods must be a List');
      }
      periodsList = raw
          .map((e) => ExportedPeriod.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    List<ExportedDayEntry>? dayList;
    if (dataMap.containsKey('day_entries')) {
      final raw = dataMap['day_entries'];
      if (raw is! List) {
        throw FormatException('data.day_entries must be a List');
      }
      dayList = raw
          .map(
            (e) =>
                ExportedDayEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    return LumaExportData(
      meta: meta,
      periods: periodsList,
      dayEntries: dayList,
    );
  }
}

int _asInt(Object? value, String field) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('$field must be a number, got ${value.runtimeType}');
}

int? _optionalInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected int?, got ${value.runtimeType}');
}
