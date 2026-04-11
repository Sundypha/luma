// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptrack_database.dart';

// ignore_for_file: type=lint
class $PeriodsTable extends Periods with TableInfo<$PeriodsTable, Period> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startUtc = GeneratedColumn<DateTime>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<DateTime> endUtc = GeneratedColumn<DateTime>(
    'end_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, startUtc, endUtc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Period> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(
        _endUtcMeta,
        endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Period map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Period(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_utc'],
      )!,
      endUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_utc'],
      ),
    );
  }

  @override
  $PeriodsTable createAlias(String alias) {
    return $PeriodsTable(attachedDatabase, alias);
  }
}

class Period extends DataClass implements Insertable<Period> {
  final int id;
  final DateTime startUtc;
  final DateTime? endUtc;
  const Period({required this.id, required this.startUtc, this.endUtc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_utc'] = Variable<DateTime>(startUtc);
    if (!nullToAbsent || endUtc != null) {
      map['end_utc'] = Variable<DateTime>(endUtc);
    }
    return map;
  }

  PeriodsCompanion toCompanion(bool nullToAbsent) {
    return PeriodsCompanion(
      id: Value(id),
      startUtc: Value(startUtc),
      endUtc: endUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endUtc),
    );
  }

  factory Period.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Period(
      id: serializer.fromJson<int>(json['id']),
      startUtc: serializer.fromJson<DateTime>(json['startUtc']),
      endUtc: serializer.fromJson<DateTime?>(json['endUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startUtc': serializer.toJson<DateTime>(startUtc),
      'endUtc': serializer.toJson<DateTime?>(endUtc),
    };
  }

  Period copyWith({
    int? id,
    DateTime? startUtc,
    Value<DateTime?> endUtc = const Value.absent(),
  }) => Period(
    id: id ?? this.id,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc.present ? endUtc.value : this.endUtc,
  );
  Period copyWithCompanion(PeriodsCompanion data) {
    return Period(
      id: data.id.present ? data.id.value : this.id,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Period(')
          ..write('id: $id, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startUtc, endUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Period &&
          other.id == this.id &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc);
}

class PeriodsCompanion extends UpdateCompanion<Period> {
  final Value<int> id;
  final Value<DateTime> startUtc;
  final Value<DateTime?> endUtc;
  const PeriodsCompanion({
    this.id = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
  });
  PeriodsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startUtc,
    this.endUtc = const Value.absent(),
  }) : startUtc = Value(startUtc);
  static Insertable<Period> custom({
    Expression<int>? id,
    Expression<DateTime>? startUtc,
    Expression<DateTime>? endUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
    });
  }

  PeriodsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startUtc,
    Value<DateTime?>? endUtc,
  }) {
    return PeriodsCompanion(
      id: id ?? this.id,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<DateTime>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<DateTime>(endUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodsCompanion(')
          ..write('id: $id, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc')
          ..write(')'))
        .toString();
  }
}

class $DayEntriesTable extends DayEntries
    with TableInfo<$DayEntriesTable, DayEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _periodIdMeta = const VerificationMeta(
    'periodId',
  );
  @override
  late final GeneratedColumn<int> periodId = GeneratedColumn<int>(
    'period_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES periods (id)',
    ),
  );
  static const VerificationMeta _dateUtcMeta = const VerificationMeta(
    'dateUtc',
  );
  @override
  late final GeneratedColumn<DateTime> dateUtc = GeneratedColumn<DateTime>(
    'date_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flowIntensityMeta = const VerificationMeta(
    'flowIntensity',
  );
  @override
  late final GeneratedColumn<int> flowIntensity = GeneratedColumn<int>(
    'flow_intensity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _painScoreMeta = const VerificationMeta(
    'painScore',
  );
  @override
  late final GeneratedColumn<int> painScore = GeneratedColumn<int>(
    'pain_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personalNotesMeta = const VerificationMeta(
    'personalNotes',
  );
  @override
  late final GeneratedColumn<String> personalNotes = GeneratedColumn<String>(
    'personal_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    periodId,
    dateUtc,
    flowIntensity,
    painScore,
    mood,
    notes,
    personalNotes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('period_id')) {
      context.handle(
        _periodIdMeta,
        periodId.isAcceptableOrUnknown(data['period_id']!, _periodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_periodIdMeta);
    }
    if (data.containsKey('date_utc')) {
      context.handle(
        _dateUtcMeta,
        dateUtc.isAcceptableOrUnknown(data['date_utc']!, _dateUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_dateUtcMeta);
    }
    if (data.containsKey('flow_intensity')) {
      context.handle(
        _flowIntensityMeta,
        flowIntensity.isAcceptableOrUnknown(
          data['flow_intensity']!,
          _flowIntensityMeta,
        ),
      );
    }
    if (data.containsKey('pain_score')) {
      context.handle(
        _painScoreMeta,
        painScore.isAcceptableOrUnknown(data['pain_score']!, _painScoreMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('personal_notes')) {
      context.handle(
        _personalNotesMeta,
        personalNotes.isAcceptableOrUnknown(
          data['personal_notes']!,
          _personalNotesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {periodId, dateUtc},
  ];
  @override
  DayEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      periodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_id'],
      )!,
      dateUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_utc'],
      )!,
      flowIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flow_intensity'],
      ),
      painScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pain_score'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      personalNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personal_notes'],
      ),
    );
  }

  @override
  $DayEntriesTable createAlias(String alias) {
    return $DayEntriesTable(attachedDatabase, alias);
  }
}

class DayEntry extends DataClass implements Insertable<DayEntry> {
  final int id;
  final int periodId;
  final DateTime dateUtc;
  final int? flowIntensity;
  final int? painScore;
  final int? mood;
  final String? notes;
  final String? personalNotes;
  const DayEntry({
    required this.id,
    required this.periodId,
    required this.dateUtc,
    this.flowIntensity,
    this.painScore,
    this.mood,
    this.notes,
    this.personalNotes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['period_id'] = Variable<int>(periodId);
    map['date_utc'] = Variable<DateTime>(dateUtc);
    if (!nullToAbsent || flowIntensity != null) {
      map['flow_intensity'] = Variable<int>(flowIntensity);
    }
    if (!nullToAbsent || painScore != null) {
      map['pain_score'] = Variable<int>(painScore);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || personalNotes != null) {
      map['personal_notes'] = Variable<String>(personalNotes);
    }
    return map;
  }

  DayEntriesCompanion toCompanion(bool nullToAbsent) {
    return DayEntriesCompanion(
      id: Value(id),
      periodId: Value(periodId),
      dateUtc: Value(dateUtc),
      flowIntensity: flowIntensity == null && nullToAbsent
          ? const Value.absent()
          : Value(flowIntensity),
      painScore: painScore == null && nullToAbsent
          ? const Value.absent()
          : Value(painScore),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      personalNotes: personalNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(personalNotes),
    );
  }

  factory DayEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayEntry(
      id: serializer.fromJson<int>(json['id']),
      periodId: serializer.fromJson<int>(json['periodId']),
      dateUtc: serializer.fromJson<DateTime>(json['dateUtc']),
      flowIntensity: serializer.fromJson<int?>(json['flowIntensity']),
      painScore: serializer.fromJson<int?>(json['painScore']),
      mood: serializer.fromJson<int?>(json['mood']),
      notes: serializer.fromJson<String?>(json['notes']),
      personalNotes: serializer.fromJson<String?>(json['personalNotes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'periodId': serializer.toJson<int>(periodId),
      'dateUtc': serializer.toJson<DateTime>(dateUtc),
      'flowIntensity': serializer.toJson<int?>(flowIntensity),
      'painScore': serializer.toJson<int?>(painScore),
      'mood': serializer.toJson<int?>(mood),
      'notes': serializer.toJson<String?>(notes),
      'personalNotes': serializer.toJson<String?>(personalNotes),
    };
  }

  DayEntry copyWith({
    int? id,
    int? periodId,
    DateTime? dateUtc,
    Value<int?> flowIntensity = const Value.absent(),
    Value<int?> painScore = const Value.absent(),
    Value<int?> mood = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> personalNotes = const Value.absent(),
  }) => DayEntry(
    id: id ?? this.id,
    periodId: periodId ?? this.periodId,
    dateUtc: dateUtc ?? this.dateUtc,
    flowIntensity: flowIntensity.present
        ? flowIntensity.value
        : this.flowIntensity,
    painScore: painScore.present ? painScore.value : this.painScore,
    mood: mood.present ? mood.value : this.mood,
    notes: notes.present ? notes.value : this.notes,
    personalNotes: personalNotes.present
        ? personalNotes.value
        : this.personalNotes,
  );
  DayEntry copyWithCompanion(DayEntriesCompanion data) {
    return DayEntry(
      id: data.id.present ? data.id.value : this.id,
      periodId: data.periodId.present ? data.periodId.value : this.periodId,
      dateUtc: data.dateUtc.present ? data.dateUtc.value : this.dateUtc,
      flowIntensity: data.flowIntensity.present
          ? data.flowIntensity.value
          : this.flowIntensity,
      painScore: data.painScore.present ? data.painScore.value : this.painScore,
      mood: data.mood.present ? data.mood.value : this.mood,
      notes: data.notes.present ? data.notes.value : this.notes,
      personalNotes: data.personalNotes.present
          ? data.personalNotes.value
          : this.personalNotes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayEntry(')
          ..write('id: $id, ')
          ..write('periodId: $periodId, ')
          ..write('dateUtc: $dateUtc, ')
          ..write('flowIntensity: $flowIntensity, ')
          ..write('painScore: $painScore, ')
          ..write('mood: $mood, ')
          ..write('notes: $notes, ')
          ..write('personalNotes: $personalNotes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    periodId,
    dateUtc,
    flowIntensity,
    painScore,
    mood,
    notes,
    personalNotes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayEntry &&
          other.id == this.id &&
          other.periodId == this.periodId &&
          other.dateUtc == this.dateUtc &&
          other.flowIntensity == this.flowIntensity &&
          other.painScore == this.painScore &&
          other.mood == this.mood &&
          other.notes == this.notes &&
          other.personalNotes == this.personalNotes);
}

class DayEntriesCompanion extends UpdateCompanion<DayEntry> {
  final Value<int> id;
  final Value<int> periodId;
  final Value<DateTime> dateUtc;
  final Value<int?> flowIntensity;
  final Value<int?> painScore;
  final Value<int?> mood;
  final Value<String?> notes;
  final Value<String?> personalNotes;
  const DayEntriesCompanion({
    this.id = const Value.absent(),
    this.periodId = const Value.absent(),
    this.dateUtc = const Value.absent(),
    this.flowIntensity = const Value.absent(),
    this.painScore = const Value.absent(),
    this.mood = const Value.absent(),
    this.notes = const Value.absent(),
    this.personalNotes = const Value.absent(),
  });
  DayEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int periodId,
    required DateTime dateUtc,
    this.flowIntensity = const Value.absent(),
    this.painScore = const Value.absent(),
    this.mood = const Value.absent(),
    this.notes = const Value.absent(),
    this.personalNotes = const Value.absent(),
  }) : periodId = Value(periodId),
       dateUtc = Value(dateUtc);
  static Insertable<DayEntry> custom({
    Expression<int>? id,
    Expression<int>? periodId,
    Expression<DateTime>? dateUtc,
    Expression<int>? flowIntensity,
    Expression<int>? painScore,
    Expression<int>? mood,
    Expression<String>? notes,
    Expression<String>? personalNotes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (periodId != null) 'period_id': periodId,
      if (dateUtc != null) 'date_utc': dateUtc,
      if (flowIntensity != null) 'flow_intensity': flowIntensity,
      if (painScore != null) 'pain_score': painScore,
      if (mood != null) 'mood': mood,
      if (notes != null) 'notes': notes,
      if (personalNotes != null) 'personal_notes': personalNotes,
    });
  }

  DayEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? periodId,
    Value<DateTime>? dateUtc,
    Value<int?>? flowIntensity,
    Value<int?>? painScore,
    Value<int?>? mood,
    Value<String?>? notes,
    Value<String?>? personalNotes,
  }) {
    return DayEntriesCompanion(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      dateUtc: dateUtc ?? this.dateUtc,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      painScore: painScore ?? this.painScore,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      personalNotes: personalNotes ?? this.personalNotes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (periodId.present) {
      map['period_id'] = Variable<int>(periodId.value);
    }
    if (dateUtc.present) {
      map['date_utc'] = Variable<DateTime>(dateUtc.value);
    }
    if (flowIntensity.present) {
      map['flow_intensity'] = Variable<int>(flowIntensity.value);
    }
    if (painScore.present) {
      map['pain_score'] = Variable<int>(painScore.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (personalNotes.present) {
      map['personal_notes'] = Variable<String>(personalNotes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayEntriesCompanion(')
          ..write('id: $id, ')
          ..write('periodId: $periodId, ')
          ..write('dateUtc: $dateUtc, ')
          ..write('flowIntensity: $flowIntensity, ')
          ..write('painScore: $painScore, ')
          ..write('mood: $mood, ')
          ..write('notes: $notes, ')
          ..write('personalNotes: $personalNotes')
          ..write(')'))
        .toString();
  }
}

abstract class _$PtrackDatabase extends GeneratedDatabase {
  _$PtrackDatabase(QueryExecutor e) : super(e);
  $PtrackDatabaseManager get managers => $PtrackDatabaseManager(this);
  late final $PeriodsTable periods = $PeriodsTable(this);
  late final $DayEntriesTable dayEntries = $DayEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [periods, dayEntries];
}

typedef $$PeriodsTableCreateCompanionBuilder =
    PeriodsCompanion Function({
      Value<int> id,
      required DateTime startUtc,
      Value<DateTime?> endUtc,
    });
typedef $$PeriodsTableUpdateCompanionBuilder =
    PeriodsCompanion Function({
      Value<int> id,
      Value<DateTime> startUtc,
      Value<DateTime?> endUtc,
    });

final class $$PeriodsTableReferences
    extends BaseReferences<_$PtrackDatabase, $PeriodsTable, Period> {
  $$PeriodsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DayEntriesTable, List<DayEntry>>
  _dayEntriesRefsTable(_$PtrackDatabase db) => MultiTypedResultKey.fromTable(
    db.dayEntries,
    aliasName: $_aliasNameGenerator(db.periods.id, db.dayEntries.periodId),
  );

  $$DayEntriesTableProcessedTableManager get dayEntriesRefs {
    final manager = $$DayEntriesTableTableManager(
      $_db,
      $_db.dayEntries,
    ).filter((f) => f.periodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dayEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeriodsTableFilterComposer
    extends Composer<_$PtrackDatabase, $PeriodsTable> {
  $$PeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dayEntriesRefs(
    Expression<bool> Function($$DayEntriesTableFilterComposer f) f,
  ) {
    final $$DayEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.periodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeriodsTableOrderingComposer
    extends Composer<_$PtrackDatabase, $PeriodsTable> {
  $$PeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeriodsTableAnnotationComposer
    extends Composer<_$PtrackDatabase, $PeriodsTable> {
  $$PeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  Expression<T> dayEntriesRefs<T extends Object>(
    Expression<T> Function($$DayEntriesTableAnnotationComposer a) f,
  ) {
    final $$DayEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.periodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeriodsTableTableManager
    extends
        RootTableManager<
          _$PtrackDatabase,
          $PeriodsTable,
          Period,
          $$PeriodsTableFilterComposer,
          $$PeriodsTableOrderingComposer,
          $$PeriodsTableAnnotationComposer,
          $$PeriodsTableCreateCompanionBuilder,
          $$PeriodsTableUpdateCompanionBuilder,
          (Period, $$PeriodsTableReferences),
          Period,
          PrefetchHooks Function({bool dayEntriesRefs})
        > {
  $$PeriodsTableTableManager(_$PtrackDatabase db, $PeriodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startUtc = const Value.absent(),
                Value<DateTime?> endUtc = const Value.absent(),
              }) =>
                  PeriodsCompanion(id: id, startUtc: startUtc, endUtc: endUtc),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startUtc,
                Value<DateTime?> endUtc = const Value.absent(),
              }) => PeriodsCompanion.insert(
                id: id,
                startUtc: startUtc,
                endUtc: endUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PeriodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dayEntriesRefs) db.dayEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dayEntriesRefs)
                    await $_getPrefetchedData<Period, $PeriodsTable, DayEntry>(
                      currentTable: table,
                      referencedTable: $$PeriodsTableReferences
                          ._dayEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$PeriodsTableReferences(
                        db,
                        table,
                        p0,
                      ).dayEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.periodId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$PtrackDatabase,
      $PeriodsTable,
      Period,
      $$PeriodsTableFilterComposer,
      $$PeriodsTableOrderingComposer,
      $$PeriodsTableAnnotationComposer,
      $$PeriodsTableCreateCompanionBuilder,
      $$PeriodsTableUpdateCompanionBuilder,
      (Period, $$PeriodsTableReferences),
      Period,
      PrefetchHooks Function({bool dayEntriesRefs})
    >;
typedef $$DayEntriesTableCreateCompanionBuilder =
    DayEntriesCompanion Function({
      Value<int> id,
      required int periodId,
      required DateTime dateUtc,
      Value<int?> flowIntensity,
      Value<int?> painScore,
      Value<int?> mood,
      Value<String?> notes,
      Value<String?> personalNotes,
    });
typedef $$DayEntriesTableUpdateCompanionBuilder =
    DayEntriesCompanion Function({
      Value<int> id,
      Value<int> periodId,
      Value<DateTime> dateUtc,
      Value<int?> flowIntensity,
      Value<int?> painScore,
      Value<int?> mood,
      Value<String?> notes,
      Value<String?> personalNotes,
    });

final class $$DayEntriesTableReferences
    extends BaseReferences<_$PtrackDatabase, $DayEntriesTable, DayEntry> {
  $$DayEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeriodsTable _periodIdTable(_$PtrackDatabase db) => db.periods
      .createAlias($_aliasNameGenerator(db.dayEntries.periodId, db.periods.id));

  $$PeriodsTableProcessedTableManager get periodId {
    final $_column = $_itemColumn<int>('period_id')!;

    final manager = $$PeriodsTableTableManager(
      $_db,
      $_db.periods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_periodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DayEntriesTableFilterComposer
    extends Composer<_$PtrackDatabase, $DayEntriesTable> {
  $$DayEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateUtc => $composableBuilder(
    column: $table.dateUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flowIntensity => $composableBuilder(
    column: $table.flowIntensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get painScore => $composableBuilder(
    column: $table.painScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personalNotes => $composableBuilder(
    column: $table.personalNotes,
    builder: (column) => ColumnFilters(column),
  );

  $$PeriodsTableFilterComposer get periodId {
    final $$PeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.periodId,
      referencedTable: $db.periods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodsTableFilterComposer(
            $db: $db,
            $table: $db.periods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayEntriesTableOrderingComposer
    extends Composer<_$PtrackDatabase, $DayEntriesTable> {
  $$DayEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateUtc => $composableBuilder(
    column: $table.dateUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flowIntensity => $composableBuilder(
    column: $table.flowIntensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get painScore => $composableBuilder(
    column: $table.painScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personalNotes => $composableBuilder(
    column: $table.personalNotes,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeriodsTableOrderingComposer get periodId {
    final $$PeriodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.periodId,
      referencedTable: $db.periods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodsTableOrderingComposer(
            $db: $db,
            $table: $db.periods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayEntriesTableAnnotationComposer
    extends Composer<_$PtrackDatabase, $DayEntriesTable> {
  $$DayEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dateUtc =>
      $composableBuilder(column: $table.dateUtc, builder: (column) => column);

  GeneratedColumn<int> get flowIntensity => $composableBuilder(
    column: $table.flowIntensity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get painScore =>
      $composableBuilder(column: $table.painScore, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get personalNotes => $composableBuilder(
    column: $table.personalNotes,
    builder: (column) => column,
  );

  $$PeriodsTableAnnotationComposer get periodId {
    final $$PeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.periodId,
      referencedTable: $db.periods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.periods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayEntriesTableTableManager
    extends
        RootTableManager<
          _$PtrackDatabase,
          $DayEntriesTable,
          DayEntry,
          $$DayEntriesTableFilterComposer,
          $$DayEntriesTableOrderingComposer,
          $$DayEntriesTableAnnotationComposer,
          $$DayEntriesTableCreateCompanionBuilder,
          $$DayEntriesTableUpdateCompanionBuilder,
          (DayEntry, $$DayEntriesTableReferences),
          DayEntry,
          PrefetchHooks Function({bool periodId})
        > {
  $$DayEntriesTableTableManager(_$PtrackDatabase db, $DayEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> periodId = const Value.absent(),
                Value<DateTime> dateUtc = const Value.absent(),
                Value<int?> flowIntensity = const Value.absent(),
                Value<int?> painScore = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> personalNotes = const Value.absent(),
              }) => DayEntriesCompanion(
                id: id,
                periodId: periodId,
                dateUtc: dateUtc,
                flowIntensity: flowIntensity,
                painScore: painScore,
                mood: mood,
                notes: notes,
                personalNotes: personalNotes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int periodId,
                required DateTime dateUtc,
                Value<int?> flowIntensity = const Value.absent(),
                Value<int?> painScore = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> personalNotes = const Value.absent(),
              }) => DayEntriesCompanion.insert(
                id: id,
                periodId: periodId,
                dateUtc: dateUtc,
                flowIntensity: flowIntensity,
                painScore: painScore,
                mood: mood,
                notes: notes,
                personalNotes: personalNotes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DayEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({periodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (periodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.periodId,
                                referencedTable: $$DayEntriesTableReferences
                                    ._periodIdTable(db),
                                referencedColumn: $$DayEntriesTableReferences
                                    ._periodIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DayEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$PtrackDatabase,
      $DayEntriesTable,
      DayEntry,
      $$DayEntriesTableFilterComposer,
      $$DayEntriesTableOrderingComposer,
      $$DayEntriesTableAnnotationComposer,
      $$DayEntriesTableCreateCompanionBuilder,
      $$DayEntriesTableUpdateCompanionBuilder,
      (DayEntry, $$DayEntriesTableReferences),
      DayEntry,
      PrefetchHooks Function({bool periodId})
    >;

class $PtrackDatabaseManager {
  final _$PtrackDatabase _db;
  $PtrackDatabaseManager(this._db);
  $$PeriodsTableTableManager get periods =>
      $$PeriodsTableTableManager(_db, _db.periods);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db, _db.dayEntries);
}
