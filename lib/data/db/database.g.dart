// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ComputersTable extends Computers
    with TableInfo<$ComputersTable, ComputerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComputersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostIdMeta = const VerificationMeta('hostId');
  @override
  late final GeneratedColumn<String> hostId = GeneratedColumn<String>(
    'host_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bindMeta = const VerificationMeta('bind');
  @override
  late final GeneratedColumn<String> bind = GeneratedColumn<String>(
    'bind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _computerNameMeta = const VerificationMeta(
    'computerName',
  );
  @override
  late final GeneratedColumn<String> computerName = GeneratedColumn<String>(
    'computer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osMeta = const VerificationMeta('os');
  @override
  late final GeneratedColumn<String> os = GeneratedColumn<String>(
    'os',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lookMeta = const VerificationMeta('look');
  @override
  late final GeneratedColumn<String> look = GeneratedColumn<String>(
    'look',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('orange'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('owner'),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
    'muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<int> lastReadAt = GeneratedColumn<int>(
    'last_read_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hostId,
    bind,
    computerName,
    person,
    language,
    os,
    look,
    role,
    pinned,
    muted,
    sortOrder,
    lastReadAt,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'computers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComputerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('host_id')) {
      context.handle(
        _hostIdMeta,
        hostId.isAcceptableOrUnknown(data['host_id']!, _hostIdMeta),
      );
    }
    if (data.containsKey('bind')) {
      context.handle(
        _bindMeta,
        bind.isAcceptableOrUnknown(data['bind']!, _bindMeta),
      );
    }
    if (data.containsKey('computer_name')) {
      context.handle(
        _computerNameMeta,
        computerName.isAcceptableOrUnknown(
          data['computer_name']!,
          _computerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_computerNameMeta);
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    } else if (isInserting) {
      context.missing(_personMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('os')) {
      context.handle(_osMeta, os.isAcceptableOrUnknown(data['os']!, _osMeta));
    }
    if (data.containsKey('look')) {
      context.handle(
        _lookMeta,
        look.isAcceptableOrUnknown(data['look']!, _lookMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('muted')) {
      context.handle(
        _mutedMeta,
        muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComputerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComputerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hostId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_id'],
      ),
      bind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bind'],
      ),
      computerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}computer_name'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      os: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os'],
      ),
      look: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}look'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      muted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}muted'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_at'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $ComputersTable createAlias(String alias) {
    return $ComputersTable(attachedDatabase, alias);
  }
}

class ComputerRow extends DataClass implements Insertable<ComputerRow> {
  final String id;
  final String? hostId;

  /// The relay pairing this phone holds; outbox rows are bound to it.
  final String? bind;
  final String computerName;
  final String person;
  final String? language;
  final String? os;
  final String look;

  /// `owner` or `helper`.
  final String role;
  final bool pinned;
  final bool muted;
  final int sortOrder;

  /// Items newer than this are unread (epoch ms).
  final int lastReadAt;
  final int addedAt;
  const ComputerRow({
    required this.id,
    this.hostId,
    this.bind,
    required this.computerName,
    required this.person,
    this.language,
    this.os,
    required this.look,
    required this.role,
    required this.pinned,
    required this.muted,
    required this.sortOrder,
    required this.lastReadAt,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || hostId != null) {
      map['host_id'] = Variable<String>(hostId);
    }
    if (!nullToAbsent || bind != null) {
      map['bind'] = Variable<String>(bind);
    }
    map['computer_name'] = Variable<String>(computerName);
    map['person'] = Variable<String>(person);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || os != null) {
      map['os'] = Variable<String>(os);
    }
    map['look'] = Variable<String>(look);
    map['role'] = Variable<String>(role);
    map['pinned'] = Variable<bool>(pinned);
    map['muted'] = Variable<bool>(muted);
    map['sort_order'] = Variable<int>(sortOrder);
    map['last_read_at'] = Variable<int>(lastReadAt);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  ComputersCompanion toCompanion(bool nullToAbsent) {
    return ComputersCompanion(
      id: Value(id),
      hostId: hostId == null && nullToAbsent
          ? const Value.absent()
          : Value(hostId),
      bind: bind == null && nullToAbsent ? const Value.absent() : Value(bind),
      computerName: Value(computerName),
      person: Value(person),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      os: os == null && nullToAbsent ? const Value.absent() : Value(os),
      look: Value(look),
      role: Value(role),
      pinned: Value(pinned),
      muted: Value(muted),
      sortOrder: Value(sortOrder),
      lastReadAt: Value(lastReadAt),
      addedAt: Value(addedAt),
    );
  }

  factory ComputerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComputerRow(
      id: serializer.fromJson<String>(json['id']),
      hostId: serializer.fromJson<String?>(json['hostId']),
      bind: serializer.fromJson<String?>(json['bind']),
      computerName: serializer.fromJson<String>(json['computerName']),
      person: serializer.fromJson<String>(json['person']),
      language: serializer.fromJson<String?>(json['language']),
      os: serializer.fromJson<String?>(json['os']),
      look: serializer.fromJson<String>(json['look']),
      role: serializer.fromJson<String>(json['role']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      muted: serializer.fromJson<bool>(json['muted']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastReadAt: serializer.fromJson<int>(json['lastReadAt']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hostId': serializer.toJson<String?>(hostId),
      'bind': serializer.toJson<String?>(bind),
      'computerName': serializer.toJson<String>(computerName),
      'person': serializer.toJson<String>(person),
      'language': serializer.toJson<String?>(language),
      'os': serializer.toJson<String?>(os),
      'look': serializer.toJson<String>(look),
      'role': serializer.toJson<String>(role),
      'pinned': serializer.toJson<bool>(pinned),
      'muted': serializer.toJson<bool>(muted),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastReadAt': serializer.toJson<int>(lastReadAt),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  ComputerRow copyWith({
    String? id,
    Value<String?> hostId = const Value.absent(),
    Value<String?> bind = const Value.absent(),
    String? computerName,
    String? person,
    Value<String?> language = const Value.absent(),
    Value<String?> os = const Value.absent(),
    String? look,
    String? role,
    bool? pinned,
    bool? muted,
    int? sortOrder,
    int? lastReadAt,
    int? addedAt,
  }) => ComputerRow(
    id: id ?? this.id,
    hostId: hostId.present ? hostId.value : this.hostId,
    bind: bind.present ? bind.value : this.bind,
    computerName: computerName ?? this.computerName,
    person: person ?? this.person,
    language: language.present ? language.value : this.language,
    os: os.present ? os.value : this.os,
    look: look ?? this.look,
    role: role ?? this.role,
    pinned: pinned ?? this.pinned,
    muted: muted ?? this.muted,
    sortOrder: sortOrder ?? this.sortOrder,
    lastReadAt: lastReadAt ?? this.lastReadAt,
    addedAt: addedAt ?? this.addedAt,
  );
  ComputerRow copyWithCompanion(ComputersCompanion data) {
    return ComputerRow(
      id: data.id.present ? data.id.value : this.id,
      hostId: data.hostId.present ? data.hostId.value : this.hostId,
      bind: data.bind.present ? data.bind.value : this.bind,
      computerName: data.computerName.present
          ? data.computerName.value
          : this.computerName,
      person: data.person.present ? data.person.value : this.person,
      language: data.language.present ? data.language.value : this.language,
      os: data.os.present ? data.os.value : this.os,
      look: data.look.present ? data.look.value : this.look,
      role: data.role.present ? data.role.value : this.role,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      muted: data.muted.present ? data.muted.value : this.muted,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComputerRow(')
          ..write('id: $id, ')
          ..write('hostId: $hostId, ')
          ..write('bind: $bind, ')
          ..write('computerName: $computerName, ')
          ..write('person: $person, ')
          ..write('language: $language, ')
          ..write('os: $os, ')
          ..write('look: $look, ')
          ..write('role: $role, ')
          ..write('pinned: $pinned, ')
          ..write('muted: $muted, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hostId,
    bind,
    computerName,
    person,
    language,
    os,
    look,
    role,
    pinned,
    muted,
    sortOrder,
    lastReadAt,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComputerRow &&
          other.id == this.id &&
          other.hostId == this.hostId &&
          other.bind == this.bind &&
          other.computerName == this.computerName &&
          other.person == this.person &&
          other.language == this.language &&
          other.os == this.os &&
          other.look == this.look &&
          other.role == this.role &&
          other.pinned == this.pinned &&
          other.muted == this.muted &&
          other.sortOrder == this.sortOrder &&
          other.lastReadAt == this.lastReadAt &&
          other.addedAt == this.addedAt);
}

class ComputersCompanion extends UpdateCompanion<ComputerRow> {
  final Value<String> id;
  final Value<String?> hostId;
  final Value<String?> bind;
  final Value<String> computerName;
  final Value<String> person;
  final Value<String?> language;
  final Value<String?> os;
  final Value<String> look;
  final Value<String> role;
  final Value<bool> pinned;
  final Value<bool> muted;
  final Value<int> sortOrder;
  final Value<int> lastReadAt;
  final Value<int> addedAt;
  final Value<int> rowid;
  const ComputersCompanion({
    this.id = const Value.absent(),
    this.hostId = const Value.absent(),
    this.bind = const Value.absent(),
    this.computerName = const Value.absent(),
    this.person = const Value.absent(),
    this.language = const Value.absent(),
    this.os = const Value.absent(),
    this.look = const Value.absent(),
    this.role = const Value.absent(),
    this.pinned = const Value.absent(),
    this.muted = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComputersCompanion.insert({
    required String id,
    this.hostId = const Value.absent(),
    this.bind = const Value.absent(),
    required String computerName,
    required String person,
    this.language = const Value.absent(),
    this.os = const Value.absent(),
    this.look = const Value.absent(),
    this.role = const Value.absent(),
    this.pinned = const Value.absent(),
    this.muted = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       computerName = Value(computerName),
       person = Value(person),
       addedAt = Value(addedAt);
  static Insertable<ComputerRow> custom({
    Expression<String>? id,
    Expression<String>? hostId,
    Expression<String>? bind,
    Expression<String>? computerName,
    Expression<String>? person,
    Expression<String>? language,
    Expression<String>? os,
    Expression<String>? look,
    Expression<String>? role,
    Expression<bool>? pinned,
    Expression<bool>? muted,
    Expression<int>? sortOrder,
    Expression<int>? lastReadAt,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hostId != null) 'host_id': hostId,
      if (bind != null) 'bind': bind,
      if (computerName != null) 'computer_name': computerName,
      if (person != null) 'person': person,
      if (language != null) 'language': language,
      if (os != null) 'os': os,
      if (look != null) 'look': look,
      if (role != null) 'role': role,
      if (pinned != null) 'pinned': pinned,
      if (muted != null) 'muted': muted,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComputersCompanion copyWith({
    Value<String>? id,
    Value<String?>? hostId,
    Value<String?>? bind,
    Value<String>? computerName,
    Value<String>? person,
    Value<String?>? language,
    Value<String?>? os,
    Value<String>? look,
    Value<String>? role,
    Value<bool>? pinned,
    Value<bool>? muted,
    Value<int>? sortOrder,
    Value<int>? lastReadAt,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return ComputersCompanion(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      bind: bind ?? this.bind,
      computerName: computerName ?? this.computerName,
      person: person ?? this.person,
      language: language ?? this.language,
      os: os ?? this.os,
      look: look ?? this.look,
      role: role ?? this.role,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      sortOrder: sortOrder ?? this.sortOrder,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hostId.present) {
      map['host_id'] = Variable<String>(hostId.value);
    }
    if (bind.present) {
      map['bind'] = Variable<String>(bind.value);
    }
    if (computerName.present) {
      map['computer_name'] = Variable<String>(computerName.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (os.present) {
      map['os'] = Variable<String>(os.value);
    }
    if (look.present) {
      map['look'] = Variable<String>(look.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<int>(lastReadAt.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComputersCompanion(')
          ..write('id: $id, ')
          ..write('hostId: $hostId, ')
          ..write('bind: $bind, ')
          ..write('computerName: $computerName, ')
          ..write('person: $person, ')
          ..write('language: $language, ')
          ..write('os: $os, ')
          ..write('look: $look, ')
          ..write('role: $role, ')
          ..write('pinned: $pinned, ')
          ..write('muted: $muted, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, RecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _computerIdMeta = const VerificationMeta(
    'computerId',
  );
  @override
  late final GeneratedColumn<String> computerId = GeneratedColumn<String>(
    'computer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shotMeta = const VerificationMeta('shot');
  @override
  late final GeneratedColumn<String> shot = GeneratedColumn<String>(
    'shot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metaMeta = const VerificationMeta('meta');
  @override
  late final GeneratedColumn<String> meta = GeneratedColumn<String>(
    'meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    computerId,
    kind,
    recordId,
    at,
    sortOrder,
    json,
    shot,
    meta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('computer_id')) {
      context.handle(
        _computerIdMeta,
        computerId.isAcceptableOrUnknown(data['computer_id']!, _computerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_computerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('shot')) {
      context.handle(
        _shotMeta,
        shot.isAcceptableOrUnknown(data['shot']!, _shotMeta),
      );
    }
    if (data.containsKey('meta')) {
      context.handle(
        _metaMeta,
        meta.isAcceptableOrUnknown(data['meta']!, _metaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {computerId, kind, recordId},
  ];
  @override
  RecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      computerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}computer_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      shot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shot'],
      ),
      meta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta'],
      ),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }
}

class RecordRow extends DataClass implements Insertable<RecordRow> {
  /// Insert sequence; ties on `at` keep arrival order.
  final int seq;
  final String computerId;
  final String kind;
  final String recordId;
  final int at;
  final int sortOrder;
  final String json;
  final String? shot;
  final String? meta;
  const RecordRow({
    required this.seq,
    required this.computerId,
    required this.kind,
    required this.recordId,
    required this.at,
    required this.sortOrder,
    required this.json,
    this.shot,
    this.meta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['computer_id'] = Variable<String>(computerId);
    map['kind'] = Variable<String>(kind);
    map['record_id'] = Variable<String>(recordId);
    map['at'] = Variable<int>(at);
    map['sort_order'] = Variable<int>(sortOrder);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || shot != null) {
      map['shot'] = Variable<String>(shot);
    }
    if (!nullToAbsent || meta != null) {
      map['meta'] = Variable<String>(meta);
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      seq: Value(seq),
      computerId: Value(computerId),
      kind: Value(kind),
      recordId: Value(recordId),
      at: Value(at),
      sortOrder: Value(sortOrder),
      json: Value(json),
      shot: shot == null && nullToAbsent ? const Value.absent() : Value(shot),
      meta: meta == null && nullToAbsent ? const Value.absent() : Value(meta),
    );
  }

  factory RecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordRow(
      seq: serializer.fromJson<int>(json['seq']),
      computerId: serializer.fromJson<String>(json['computerId']),
      kind: serializer.fromJson<String>(json['kind']),
      recordId: serializer.fromJson<String>(json['recordId']),
      at: serializer.fromJson<int>(json['at']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      json: serializer.fromJson<String>(json['json']),
      shot: serializer.fromJson<String?>(json['shot']),
      meta: serializer.fromJson<String?>(json['meta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'computerId': serializer.toJson<String>(computerId),
      'kind': serializer.toJson<String>(kind),
      'recordId': serializer.toJson<String>(recordId),
      'at': serializer.toJson<int>(at),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'json': serializer.toJson<String>(json),
      'shot': serializer.toJson<String?>(shot),
      'meta': serializer.toJson<String?>(meta),
    };
  }

  RecordRow copyWith({
    int? seq,
    String? computerId,
    String? kind,
    String? recordId,
    int? at,
    int? sortOrder,
    String? json,
    Value<String?> shot = const Value.absent(),
    Value<String?> meta = const Value.absent(),
  }) => RecordRow(
    seq: seq ?? this.seq,
    computerId: computerId ?? this.computerId,
    kind: kind ?? this.kind,
    recordId: recordId ?? this.recordId,
    at: at ?? this.at,
    sortOrder: sortOrder ?? this.sortOrder,
    json: json ?? this.json,
    shot: shot.present ? shot.value : this.shot,
    meta: meta.present ? meta.value : this.meta,
  );
  RecordRow copyWithCompanion(RecordsCompanion data) {
    return RecordRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      computerId: data.computerId.present
          ? data.computerId.value
          : this.computerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      at: data.at.present ? data.at.value : this.at,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      json: data.json.present ? data.json.value : this.json,
      shot: data.shot.present ? data.shot.value : this.shot,
      meta: data.meta.present ? data.meta.value : this.meta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordRow(')
          ..write('seq: $seq, ')
          ..write('computerId: $computerId, ')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('at: $at, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('json: $json, ')
          ..write('shot: $shot, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    computerId,
    kind,
    recordId,
    at,
    sortOrder,
    json,
    shot,
    meta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordRow &&
          other.seq == this.seq &&
          other.computerId == this.computerId &&
          other.kind == this.kind &&
          other.recordId == this.recordId &&
          other.at == this.at &&
          other.sortOrder == this.sortOrder &&
          other.json == this.json &&
          other.shot == this.shot &&
          other.meta == this.meta);
}

class RecordsCompanion extends UpdateCompanion<RecordRow> {
  final Value<int> seq;
  final Value<String> computerId;
  final Value<String> kind;
  final Value<String> recordId;
  final Value<int> at;
  final Value<int> sortOrder;
  final Value<String> json;
  final Value<String?> shot;
  final Value<String?> meta;
  const RecordsCompanion({
    this.seq = const Value.absent(),
    this.computerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.recordId = const Value.absent(),
    this.at = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.json = const Value.absent(),
    this.shot = const Value.absent(),
    this.meta = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.seq = const Value.absent(),
    required String computerId,
    required String kind,
    required String recordId,
    required int at,
    required int sortOrder,
    required String json,
    this.shot = const Value.absent(),
    this.meta = const Value.absent(),
  }) : computerId = Value(computerId),
       kind = Value(kind),
       recordId = Value(recordId),
       at = Value(at),
       sortOrder = Value(sortOrder),
       json = Value(json);
  static Insertable<RecordRow> custom({
    Expression<int>? seq,
    Expression<String>? computerId,
    Expression<String>? kind,
    Expression<String>? recordId,
    Expression<int>? at,
    Expression<int>? sortOrder,
    Expression<String>? json,
    Expression<String>? shot,
    Expression<String>? meta,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (computerId != null) 'computer_id': computerId,
      if (kind != null) 'kind': kind,
      if (recordId != null) 'record_id': recordId,
      if (at != null) 'at': at,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (json != null) 'json': json,
      if (shot != null) 'shot': shot,
      if (meta != null) 'meta': meta,
    });
  }

  RecordsCompanion copyWith({
    Value<int>? seq,
    Value<String>? computerId,
    Value<String>? kind,
    Value<String>? recordId,
    Value<int>? at,
    Value<int>? sortOrder,
    Value<String>? json,
    Value<String?>? shot,
    Value<String?>? meta,
  }) {
    return RecordsCompanion(
      seq: seq ?? this.seq,
      computerId: computerId ?? this.computerId,
      kind: kind ?? this.kind,
      recordId: recordId ?? this.recordId,
      at: at ?? this.at,
      sortOrder: sortOrder ?? this.sortOrder,
      json: json ?? this.json,
      shot: shot ?? this.shot,
      meta: meta ?? this.meta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (computerId.present) {
      map['computer_id'] = Variable<String>(computerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (shot.present) {
      map['shot'] = Variable<String>(shot.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(meta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('seq: $seq, ')
          ..write('computerId: $computerId, ')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('at: $at, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('json: $json, ')
          ..write('shot: $shot, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxDbRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computerIdMeta = const VerificationMeta(
    'computerId',
  );
  @override
  late final GeneratedColumn<String> computerId = GeneratedColumn<String>(
    'computer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bindMeta = const VerificationMeta('bind');
  @override
  late final GeneratedColumn<String> bind = GeneratedColumn<String>(
    'bind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryOfMeta = const VerificationMeta(
    'retryOf',
  );
  @override
  late final GeneratedColumn<String> retryOf = GeneratedColumn<String>(
    'retry_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    computerId,
    bind,
    kind,
    payload,
    state,
    requestId,
    taskId,
    error,
    errorMessage,
    retryOf,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxDbRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('computer_id')) {
      context.handle(
        _computerIdMeta,
        computerId.isAcceptableOrUnknown(data['computer_id']!, _computerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_computerIdMeta);
    }
    if (data.containsKey('bind')) {
      context.handle(
        _bindMeta,
        bind.isAcceptableOrUnknown(data['bind']!, _bindMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_of')) {
      context.handle(
        _retryOfMeta,
        retryOf.isAcceptableOrUnknown(data['retry_of']!, _retryOfMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxDbRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxDbRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      computerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}computer_id'],
      )!,
      bind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bind'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retry_of'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxDbRow extends DataClass implements Insertable<OutboxDbRow> {
  final String id;
  final String computerId;
  final String? bind;
  final String kind;
  final String payload;
  final String state;
  final String? requestId;
  final String? taskId;
  final String? error;
  final String? errorMessage;
  final String? retryOf;
  final int createdAt;
  final int updatedAt;
  const OutboxDbRow({
    required this.id,
    required this.computerId,
    this.bind,
    required this.kind,
    required this.payload,
    required this.state,
    this.requestId,
    this.taskId,
    this.error,
    this.errorMessage,
    this.retryOf,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['computer_id'] = Variable<String>(computerId);
    if (!nullToAbsent || bind != null) {
      map['bind'] = Variable<String>(bind);
    }
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || retryOf != null) {
      map['retry_of'] = Variable<String>(retryOf);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      computerId: Value(computerId),
      bind: bind == null && nullToAbsent ? const Value.absent() : Value(bind),
      kind: Value(kind),
      payload: Value(payload),
      state: Value(state),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryOf: retryOf == null && nullToAbsent
          ? const Value.absent()
          : Value(retryOf),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxDbRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxDbRow(
      id: serializer.fromJson<String>(json['id']),
      computerId: serializer.fromJson<String>(json['computerId']),
      bind: serializer.fromJson<String?>(json['bind']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      state: serializer.fromJson<String>(json['state']),
      requestId: serializer.fromJson<String?>(json['requestId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      error: serializer.fromJson<String?>(json['error']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryOf: serializer.fromJson<String?>(json['retryOf']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'computerId': serializer.toJson<String>(computerId),
      'bind': serializer.toJson<String?>(bind),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'state': serializer.toJson<String>(state),
      'requestId': serializer.toJson<String?>(requestId),
      'taskId': serializer.toJson<String?>(taskId),
      'error': serializer.toJson<String?>(error),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryOf': serializer.toJson<String?>(retryOf),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OutboxDbRow copyWith({
    String? id,
    String? computerId,
    Value<String?> bind = const Value.absent(),
    String? kind,
    String? payload,
    String? state,
    Value<String?> requestId = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> retryOf = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => OutboxDbRow(
    id: id ?? this.id,
    computerId: computerId ?? this.computerId,
    bind: bind.present ? bind.value : this.bind,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    state: state ?? this.state,
    requestId: requestId.present ? requestId.value : this.requestId,
    taskId: taskId.present ? taskId.value : this.taskId,
    error: error.present ? error.value : this.error,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryOf: retryOf.present ? retryOf.value : this.retryOf,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OutboxDbRow copyWithCompanion(OutboxCompanion data) {
    return OutboxDbRow(
      id: data.id.present ? data.id.value : this.id,
      computerId: data.computerId.present
          ? data.computerId.value
          : this.computerId,
      bind: data.bind.present ? data.bind.value : this.bind,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      state: data.state.present ? data.state.value : this.state,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      error: data.error.present ? data.error.value : this.error,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryOf: data.retryOf.present ? data.retryOf.value : this.retryOf,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxDbRow(')
          ..write('id: $id, ')
          ..write('computerId: $computerId, ')
          ..write('bind: $bind, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('state: $state, ')
          ..write('requestId: $requestId, ')
          ..write('taskId: $taskId, ')
          ..write('error: $error, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryOf: $retryOf, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    computerId,
    bind,
    kind,
    payload,
    state,
    requestId,
    taskId,
    error,
    errorMessage,
    retryOf,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxDbRow &&
          other.id == this.id &&
          other.computerId == this.computerId &&
          other.bind == this.bind &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.state == this.state &&
          other.requestId == this.requestId &&
          other.taskId == this.taskId &&
          other.error == this.error &&
          other.errorMessage == this.errorMessage &&
          other.retryOf == this.retryOf &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxDbRow> {
  final Value<String> id;
  final Value<String> computerId;
  final Value<String?> bind;
  final Value<String> kind;
  final Value<String> payload;
  final Value<String> state;
  final Value<String?> requestId;
  final Value<String?> taskId;
  final Value<String?> error;
  final Value<String?> errorMessage;
  final Value<String?> retryOf;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.computerId = const Value.absent(),
    this.bind = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.state = const Value.absent(),
    this.requestId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.error = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryOf = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required String computerId,
    this.bind = const Value.absent(),
    required String kind,
    required String payload,
    required String state,
    this.requestId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.error = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryOf = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       computerId = Value(computerId),
       kind = Value(kind),
       payload = Value(payload),
       state = Value(state),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OutboxDbRow> custom({
    Expression<String>? id,
    Expression<String>? computerId,
    Expression<String>? bind,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<String>? state,
    Expression<String>? requestId,
    Expression<String>? taskId,
    Expression<String>? error,
    Expression<String>? errorMessage,
    Expression<String>? retryOf,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (computerId != null) 'computer_id': computerId,
      if (bind != null) 'bind': bind,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (state != null) 'state': state,
      if (requestId != null) 'request_id': requestId,
      if (taskId != null) 'task_id': taskId,
      if (error != null) 'error': error,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryOf != null) 'retry_of': retryOf,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? computerId,
    Value<String?>? bind,
    Value<String>? kind,
    Value<String>? payload,
    Value<String>? state,
    Value<String?>? requestId,
    Value<String?>? taskId,
    Value<String?>? error,
    Value<String?>? errorMessage,
    Value<String?>? retryOf,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      computerId: computerId ?? this.computerId,
      bind: bind ?? this.bind,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      state: state ?? this.state,
      requestId: requestId ?? this.requestId,
      taskId: taskId ?? this.taskId,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
      retryOf: retryOf ?? this.retryOf,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (computerId.present) {
      map['computer_id'] = Variable<String>(computerId.value);
    }
    if (bind.present) {
      map['bind'] = Variable<String>(bind.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryOf.present) {
      map['retry_of'] = Variable<String>(retryOf.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('computerId: $computerId, ')
          ..write('bind: $bind, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('state: $state, ')
          ..write('requestId: $requestId, ')
          ..write('taskId: $taskId, ')
          ..write('error: $error, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryOf: $retryOf, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _computerIdMeta = const VerificationMeta(
    'computerId',
  );
  @override
  late final GeneratedColumn<String> computerId = GeneratedColumn<String>(
    'computer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logCursorMeta = const VerificationMeta(
    'logCursor',
  );
  @override
  late final GeneratedColumn<int> logCursor = GeneratedColumn<int>(
    'log_cursor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logMayBeIncompleteMeta =
      const VerificationMeta('logMayBeIncomplete');
  @override
  late final GeneratedColumn<bool> logMayBeIncomplete = GeneratedColumn<bool>(
    'log_may_be_incomplete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("log_may_be_incomplete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _myHelperIdMeta = const VerificationMeta(
    'myHelperId',
  );
  @override
  late final GeneratedColumn<String> myHelperId = GeneratedColumn<String>(
    'my_helper_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusJsonMeta = const VerificationMeta(
    'statusJson',
  );
  @override
  late final GeneratedColumn<String> statusJson = GeneratedColumn<String>(
    'status_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _policyJsonMeta = const VerificationMeta(
    'policyJson',
  );
  @override
  late final GeneratedColumn<String> policyJson = GeneratedColumn<String>(
    'policy_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<bool> removed = GeneratedColumn<bool>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    computerId,
    logCursor,
    logMayBeIncomplete,
    myHelperId,
    statusJson,
    policyJson,
    lastSeenAt,
    removed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('computer_id')) {
      context.handle(
        _computerIdMeta,
        computerId.isAcceptableOrUnknown(data['computer_id']!, _computerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_computerIdMeta);
    }
    if (data.containsKey('log_cursor')) {
      context.handle(
        _logCursorMeta,
        logCursor.isAcceptableOrUnknown(data['log_cursor']!, _logCursorMeta),
      );
    }
    if (data.containsKey('log_may_be_incomplete')) {
      context.handle(
        _logMayBeIncompleteMeta,
        logMayBeIncomplete.isAcceptableOrUnknown(
          data['log_may_be_incomplete']!,
          _logMayBeIncompleteMeta,
        ),
      );
    }
    if (data.containsKey('my_helper_id')) {
      context.handle(
        _myHelperIdMeta,
        myHelperId.isAcceptableOrUnknown(
          data['my_helper_id']!,
          _myHelperIdMeta,
        ),
      );
    }
    if (data.containsKey('status_json')) {
      context.handle(
        _statusJsonMeta,
        statusJson.isAcceptableOrUnknown(data['status_json']!, _statusJsonMeta),
      );
    }
    if (data.containsKey('policy_json')) {
      context.handle(
        _policyJsonMeta,
        policyJson.isAcceptableOrUnknown(data['policy_json']!, _policyJsonMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {computerId};
  @override
  SyncRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRow(
      computerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}computer_id'],
      )!,
      logCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}log_cursor'],
      ),
      logMayBeIncomplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}log_may_be_incomplete'],
      )!,
      myHelperId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}my_helper_id'],
      ),
      statusJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_json'],
      ),
      policyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy_json'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      ),
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed'],
      )!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncRow extends DataClass implements Insertable<SyncRow> {
  final String computerId;
  final int? logCursor;
  final bool logMayBeIncomplete;
  final String? myHelperId;
  final String? statusJson;
  final String? policyJson;
  final int? lastSeenAt;
  final bool removed;
  const SyncRow({
    required this.computerId,
    this.logCursor,
    required this.logMayBeIncomplete,
    this.myHelperId,
    this.statusJson,
    this.policyJson,
    this.lastSeenAt,
    required this.removed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['computer_id'] = Variable<String>(computerId);
    if (!nullToAbsent || logCursor != null) {
      map['log_cursor'] = Variable<int>(logCursor);
    }
    map['log_may_be_incomplete'] = Variable<bool>(logMayBeIncomplete);
    if (!nullToAbsent || myHelperId != null) {
      map['my_helper_id'] = Variable<String>(myHelperId);
    }
    if (!nullToAbsent || statusJson != null) {
      map['status_json'] = Variable<String>(statusJson);
    }
    if (!nullToAbsent || policyJson != null) {
      map['policy_json'] = Variable<String>(policyJson);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<int>(lastSeenAt);
    }
    map['removed'] = Variable<bool>(removed);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      computerId: Value(computerId),
      logCursor: logCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(logCursor),
      logMayBeIncomplete: Value(logMayBeIncomplete),
      myHelperId: myHelperId == null && nullToAbsent
          ? const Value.absent()
          : Value(myHelperId),
      statusJson: statusJson == null && nullToAbsent
          ? const Value.absent()
          : Value(statusJson),
      policyJson: policyJson == null && nullToAbsent
          ? const Value.absent()
          : Value(policyJson),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      removed: Value(removed),
    );
  }

  factory SyncRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRow(
      computerId: serializer.fromJson<String>(json['computerId']),
      logCursor: serializer.fromJson<int?>(json['logCursor']),
      logMayBeIncomplete: serializer.fromJson<bool>(json['logMayBeIncomplete']),
      myHelperId: serializer.fromJson<String?>(json['myHelperId']),
      statusJson: serializer.fromJson<String?>(json['statusJson']),
      policyJson: serializer.fromJson<String?>(json['policyJson']),
      lastSeenAt: serializer.fromJson<int?>(json['lastSeenAt']),
      removed: serializer.fromJson<bool>(json['removed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'computerId': serializer.toJson<String>(computerId),
      'logCursor': serializer.toJson<int?>(logCursor),
      'logMayBeIncomplete': serializer.toJson<bool>(logMayBeIncomplete),
      'myHelperId': serializer.toJson<String?>(myHelperId),
      'statusJson': serializer.toJson<String?>(statusJson),
      'policyJson': serializer.toJson<String?>(policyJson),
      'lastSeenAt': serializer.toJson<int?>(lastSeenAt),
      'removed': serializer.toJson<bool>(removed),
    };
  }

  SyncRow copyWith({
    String? computerId,
    Value<int?> logCursor = const Value.absent(),
    bool? logMayBeIncomplete,
    Value<String?> myHelperId = const Value.absent(),
    Value<String?> statusJson = const Value.absent(),
    Value<String?> policyJson = const Value.absent(),
    Value<int?> lastSeenAt = const Value.absent(),
    bool? removed,
  }) => SyncRow(
    computerId: computerId ?? this.computerId,
    logCursor: logCursor.present ? logCursor.value : this.logCursor,
    logMayBeIncomplete: logMayBeIncomplete ?? this.logMayBeIncomplete,
    myHelperId: myHelperId.present ? myHelperId.value : this.myHelperId,
    statusJson: statusJson.present ? statusJson.value : this.statusJson,
    policyJson: policyJson.present ? policyJson.value : this.policyJson,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    removed: removed ?? this.removed,
  );
  SyncRow copyWithCompanion(SyncStatesCompanion data) {
    return SyncRow(
      computerId: data.computerId.present
          ? data.computerId.value
          : this.computerId,
      logCursor: data.logCursor.present ? data.logCursor.value : this.logCursor,
      logMayBeIncomplete: data.logMayBeIncomplete.present
          ? data.logMayBeIncomplete.value
          : this.logMayBeIncomplete,
      myHelperId: data.myHelperId.present
          ? data.myHelperId.value
          : this.myHelperId,
      statusJson: data.statusJson.present
          ? data.statusJson.value
          : this.statusJson,
      policyJson: data.policyJson.present
          ? data.policyJson.value
          : this.policyJson,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      removed: data.removed.present ? data.removed.value : this.removed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRow(')
          ..write('computerId: $computerId, ')
          ..write('logCursor: $logCursor, ')
          ..write('logMayBeIncomplete: $logMayBeIncomplete, ')
          ..write('myHelperId: $myHelperId, ')
          ..write('statusJson: $statusJson, ')
          ..write('policyJson: $policyJson, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    computerId,
    logCursor,
    logMayBeIncomplete,
    myHelperId,
    statusJson,
    policyJson,
    lastSeenAt,
    removed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRow &&
          other.computerId == this.computerId &&
          other.logCursor == this.logCursor &&
          other.logMayBeIncomplete == this.logMayBeIncomplete &&
          other.myHelperId == this.myHelperId &&
          other.statusJson == this.statusJson &&
          other.policyJson == this.policyJson &&
          other.lastSeenAt == this.lastSeenAt &&
          other.removed == this.removed);
}

class SyncStatesCompanion extends UpdateCompanion<SyncRow> {
  final Value<String> computerId;
  final Value<int?> logCursor;
  final Value<bool> logMayBeIncomplete;
  final Value<String?> myHelperId;
  final Value<String?> statusJson;
  final Value<String?> policyJson;
  final Value<int?> lastSeenAt;
  final Value<bool> removed;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.computerId = const Value.absent(),
    this.logCursor = const Value.absent(),
    this.logMayBeIncomplete = const Value.absent(),
    this.myHelperId = const Value.absent(),
    this.statusJson = const Value.absent(),
    this.policyJson = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.removed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String computerId,
    this.logCursor = const Value.absent(),
    this.logMayBeIncomplete = const Value.absent(),
    this.myHelperId = const Value.absent(),
    this.statusJson = const Value.absent(),
    this.policyJson = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.removed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : computerId = Value(computerId);
  static Insertable<SyncRow> custom({
    Expression<String>? computerId,
    Expression<int>? logCursor,
    Expression<bool>? logMayBeIncomplete,
    Expression<String>? myHelperId,
    Expression<String>? statusJson,
    Expression<String>? policyJson,
    Expression<int>? lastSeenAt,
    Expression<bool>? removed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (computerId != null) 'computer_id': computerId,
      if (logCursor != null) 'log_cursor': logCursor,
      if (logMayBeIncomplete != null)
        'log_may_be_incomplete': logMayBeIncomplete,
      if (myHelperId != null) 'my_helper_id': myHelperId,
      if (statusJson != null) 'status_json': statusJson,
      if (policyJson != null) 'policy_json': policyJson,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (removed != null) 'removed': removed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? computerId,
    Value<int?>? logCursor,
    Value<bool>? logMayBeIncomplete,
    Value<String?>? myHelperId,
    Value<String?>? statusJson,
    Value<String?>? policyJson,
    Value<int?>? lastSeenAt,
    Value<bool>? removed,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      computerId: computerId ?? this.computerId,
      logCursor: logCursor ?? this.logCursor,
      logMayBeIncomplete: logMayBeIncomplete ?? this.logMayBeIncomplete,
      myHelperId: myHelperId ?? this.myHelperId,
      statusJson: statusJson ?? this.statusJson,
      policyJson: policyJson ?? this.policyJson,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      removed: removed ?? this.removed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (computerId.present) {
      map['computer_id'] = Variable<String>(computerId.value);
    }
    if (logCursor.present) {
      map['log_cursor'] = Variable<int>(logCursor.value);
    }
    if (logMayBeIncomplete.present) {
      map['log_may_be_incomplete'] = Variable<bool>(logMayBeIncomplete.value);
    }
    if (myHelperId.present) {
      map['my_helper_id'] = Variable<String>(myHelperId.value);
    }
    if (statusJson.present) {
      map['status_json'] = Variable<String>(statusJson.value);
    }
    if (policyJson.present) {
      map['policy_json'] = Variable<String>(policyJson.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (removed.present) {
      map['removed'] = Variable<bool>(removed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('computerId: $computerId, ')
          ..write('logCursor: $logCursor, ')
          ..write('logMayBeIncomplete: $logMayBeIncomplete, ')
          ..write('myHelperId: $myHelperId, ')
          ..write('statusJson: $statusJson, ')
          ..write('policyJson: $policyJson, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('removed: $removed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OctoDatabase extends GeneratedDatabase {
  _$OctoDatabase(QueryExecutor e) : super(e);
  $OctoDatabaseManager get managers => $OctoDatabaseManager(this);
  late final $ComputersTable computers = $ComputersTable(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    computers,
    records,
    outbox,
    syncStates,
  ];
}

typedef $$ComputersTableCreateCompanionBuilder = ComputersCompanion Function({
  required String id,
  Value<String?> hostId,
  Value<String?> bind,
  required String computerName,
  required String person,
  Value<String?> language,
  Value<String?> os,
  Value<String> look,
  Value<String> role,
  Value<bool> pinned,
  Value<bool> muted,
  Value<int> sortOrder,
  Value<int> lastReadAt,
  required int addedAt,
  Value<int> rowid,
});
typedef $$ComputersTableUpdateCompanionBuilder = ComputersCompanion Function({
  Value<String> id,
  Value<String?> hostId,
  Value<String?> bind,
  Value<String> computerName,
  Value<String> person,
  Value<String?> language,
  Value<String?> os,
  Value<String> look,
  Value<String> role,
  Value<bool> pinned,
  Value<bool> muted,
  Value<int> sortOrder,
  Value<int> lastReadAt,
  Value<int> addedAt,
  Value<int> rowid,
});

class $$ComputersTableFilterComposer
    extends Composer<_$OctoDatabase, $ComputersTable> {
  $$ComputersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostId => $composableBuilder(
    column: $table.hostId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bind => $composableBuilder(
    column: $table.bind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get computerName => $composableBuilder(
    column: $table.computerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get os => $composableBuilder(
    column: $table.os,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get look => $composableBuilder(
    column: $table.look,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComputersTableOrderingComposer
    extends Composer<_$OctoDatabase, $ComputersTable> {
  $$ComputersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostId => $composableBuilder(
    column: $table.hostId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bind => $composableBuilder(
    column: $table.bind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get computerName => $composableBuilder(
    column: $table.computerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get os => $composableBuilder(
    column: $table.os,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get look => $composableBuilder(
    column: $table.look,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComputersTableAnnotationComposer
    extends Composer<_$OctoDatabase, $ComputersTable> {
  $$ComputersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hostId =>
      $composableBuilder(column: $table.hostId, builder: (column) => column);

  GeneratedColumn<String> get bind =>
      $composableBuilder(column: $table.bind, builder: (column) => column);

  GeneratedColumn<String> get computerName => $composableBuilder(
    column: $table.computerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get os =>
      $composableBuilder(column: $table.os, builder: (column) => column);

  GeneratedColumn<String> get look =>
      $composableBuilder(column: $table.look, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$ComputersTableTableManager
    extends
        RootTableManager<
          _$OctoDatabase,
          $ComputersTable,
          ComputerRow,
          $$ComputersTableFilterComposer,
          $$ComputersTableOrderingComposer,
          $$ComputersTableAnnotationComposer,
          $$ComputersTableCreateCompanionBuilder,
          $$ComputersTableUpdateCompanionBuilder,
          (
            ComputerRow,
            BaseReferences<_$OctoDatabase, $ComputersTable, ComputerRow>,
          ),
          ComputerRow,
          PrefetchHooks Function()
        > {
  $$ComputersTableTableManager(_$OctoDatabase db, $ComputersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComputersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComputersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComputersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> hostId = const Value.absent(),
                Value<String?> bind = const Value.absent(),
                Value<String> computerName = const Value.absent(),
                Value<String> person = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<String> look = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> lastReadAt = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComputersCompanion(
                id: id,
                hostId: hostId,
                bind: bind,
                computerName: computerName,
                person: person,
                language: language,
                os: os,
                look: look,
                role: role,
                pinned: pinned,
                muted: muted,
                sortOrder: sortOrder,
                lastReadAt: lastReadAt,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> hostId = const Value.absent(),
                Value<String?> bind = const Value.absent(),
                required String computerName,
                required String person,
                Value<String?> language = const Value.absent(),
                Value<String?> os = const Value.absent(),
                Value<String> look = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> lastReadAt = const Value.absent(),
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => ComputersCompanion.insert(
                id: id,
                hostId: hostId,
                bind: bind,
                computerName: computerName,
                person: person,
                language: language,
                os: os,
                look: look,
                role: role,
                pinned: pinned,
                muted: muted,
                sortOrder: sortOrder,
                lastReadAt: lastReadAt,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ComputersTable, ComputerRow>(table),
                  BaseReferences<_$OctoDatabase, $ComputersTable, ComputerRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComputersTableProcessedTableManager =
    ProcessedTableManager<
      _$OctoDatabase,
      $ComputersTable,
      ComputerRow,
      $$ComputersTableFilterComposer,
      $$ComputersTableOrderingComposer,
      $$ComputersTableAnnotationComposer,
      $$ComputersTableCreateCompanionBuilder,
      $$ComputersTableUpdateCompanionBuilder,
      (
        ComputerRow,
        BaseReferences<_$OctoDatabase, $ComputersTable, ComputerRow>,
      ),
      ComputerRow,
      PrefetchHooks Function()
    >;
typedef $$RecordsTableCreateCompanionBuilder = RecordsCompanion Function({
  Value<int> seq,
  required String computerId,
  required String kind,
  required String recordId,
  required int at,
  required int sortOrder,
  required String json,
  Value<String?> shot,
  Value<String?> meta,
});
typedef $$RecordsTableUpdateCompanionBuilder = RecordsCompanion Function({
  Value<int> seq,
  Value<String> computerId,
  Value<String> kind,
  Value<String> recordId,
  Value<int> at,
  Value<int> sortOrder,
  Value<String> json,
  Value<String?> shot,
  Value<String?> meta,
});

class $$RecordsTableFilterComposer
    extends Composer<_$OctoDatabase, $RecordsTable> {
  $$RecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shot => $composableBuilder(
    column: $table.shot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordsTableOrderingComposer
    extends Composer<_$OctoDatabase, $RecordsTable> {
  $$RecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shot => $composableBuilder(
    column: $table.shot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$OctoDatabase, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get shot =>
      $composableBuilder(column: $table.shot, builder: (column) => column);

  GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);
}

class $$RecordsTableTableManager
    extends
        RootTableManager<
          _$OctoDatabase,
          $RecordsTable,
          RecordRow,
          $$RecordsTableFilterComposer,
          $$RecordsTableOrderingComposer,
          $$RecordsTableAnnotationComposer,
          $$RecordsTableCreateCompanionBuilder,
          $$RecordsTableUpdateCompanionBuilder,
          (RecordRow, BaseReferences<_$OctoDatabase, $RecordsTable, RecordRow>),
          RecordRow,
          PrefetchHooks Function()
        > {
  $$RecordsTableTableManager(_$OctoDatabase db, $RecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> computerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> shot = const Value.absent(),
                Value<String?> meta = const Value.absent(),
              }) => RecordsCompanion(
                seq: seq,
                computerId: computerId,
                kind: kind,
                recordId: recordId,
                at: at,
                sortOrder: sortOrder,
                json: json,
                shot: shot,
                meta: meta,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String computerId,
                required String kind,
                required String recordId,
                required int at,
                required int sortOrder,
                required String json,
                Value<String?> shot = const Value.absent(),
                Value<String?> meta = const Value.absent(),
              }) => RecordsCompanion.insert(
                seq: seq,
                computerId: computerId,
                kind: kind,
                recordId: recordId,
                at: at,
                sortOrder: sortOrder,
                json: json,
                shot: shot,
                meta: meta,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordsTable, RecordRow>(table),
                  BaseReferences<_$OctoDatabase, $RecordsTable, RecordRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$OctoDatabase,
      $RecordsTable,
      RecordRow,
      $$RecordsTableFilterComposer,
      $$RecordsTableOrderingComposer,
      $$RecordsTableAnnotationComposer,
      $$RecordsTableCreateCompanionBuilder,
      $$RecordsTableUpdateCompanionBuilder,
      (RecordRow, BaseReferences<_$OctoDatabase, $RecordsTable, RecordRow>),
      RecordRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String id,
  required String computerId,
  Value<String?> bind,
  required String kind,
  required String payload,
  required String state,
  Value<String?> requestId,
  Value<String?> taskId,
  Value<String?> error,
  Value<String?> errorMessage,
  Value<String?> retryOf,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> id,
  Value<String> computerId,
  Value<String?> bind,
  Value<String> kind,
  Value<String> payload,
  Value<String> state,
  Value<String?> requestId,
  Value<String?> taskId,
  Value<String?> error,
  Value<String?> errorMessage,
  Value<String?> retryOf,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$OctoDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bind => $composableBuilder(
    column: $table.bind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retryOf => $composableBuilder(
    column: $table.retryOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$OctoDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bind => $composableBuilder(
    column: $table.bind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retryOf => $composableBuilder(
    column: $table.retryOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$OctoDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bind =>
      $composableBuilder(column: $table.bind, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get retryOf =>
      $composableBuilder(column: $table.retryOf, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$OctoDatabase,
          $OutboxTable,
          OutboxDbRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxDbRow,
            BaseReferences<_$OctoDatabase, $OutboxTable, OutboxDbRow>,
          ),
          OutboxDbRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$OctoDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> computerId = const Value.absent(),
                Value<String?> bind = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> retryOf = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                computerId: computerId,
                bind: bind,
                kind: kind,
                payload: payload,
                state: state,
                requestId: requestId,
                taskId: taskId,
                error: error,
                errorMessage: errorMessage,
                retryOf: retryOf,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String computerId,
                Value<String?> bind = const Value.absent(),
                required String kind,
                required String payload,
                required String state,
                Value<String?> requestId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> retryOf = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                computerId: computerId,
                bind: bind,
                kind: kind,
                payload: payload,
                state: state,
                requestId: requestId,
                taskId: taskId,
                error: error,
                errorMessage: errorMessage,
                retryOf: retryOf,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxDbRow>(table),
                  BaseReferences<_$OctoDatabase, $OutboxTable, OutboxDbRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$OctoDatabase,
      $OutboxTable,
      OutboxDbRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxDbRow, BaseReferences<_$OctoDatabase, $OutboxTable, OutboxDbRow>),
      OutboxDbRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder = SyncStatesCompanion Function({
  required String computerId,
  Value<int?> logCursor,
  Value<bool> logMayBeIncomplete,
  Value<String?> myHelperId,
  Value<String?> statusJson,
  Value<String?> policyJson,
  Value<int?> lastSeenAt,
  Value<bool> removed,
  Value<int> rowid,
});
typedef $$SyncStatesTableUpdateCompanionBuilder = SyncStatesCompanion Function({
  Value<String> computerId,
  Value<int?> logCursor,
  Value<bool> logMayBeIncomplete,
  Value<String?> myHelperId,
  Value<String?> statusJson,
  Value<String?> policyJson,
  Value<int?> lastSeenAt,
  Value<bool> removed,
  Value<int> rowid,
});

class $$SyncStatesTableFilterComposer
    extends Composer<_$OctoDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get logCursor => $composableBuilder(
    column: $table.logCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get logMayBeIncomplete => $composableBuilder(
    column: $table.logMayBeIncomplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get myHelperId => $composableBuilder(
    column: $table.myHelperId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusJson => $composableBuilder(
    column: $table.statusJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get policyJson => $composableBuilder(
    column: $table.policyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$OctoDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get logCursor => $composableBuilder(
    column: $table.logCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get logMayBeIncomplete => $composableBuilder(
    column: $table.logMayBeIncomplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get myHelperId => $composableBuilder(
    column: $table.myHelperId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusJson => $composableBuilder(
    column: $table.statusJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policyJson => $composableBuilder(
    column: $table.policyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$OctoDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get computerId => $composableBuilder(
    column: $table.computerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get logCursor =>
      $composableBuilder(column: $table.logCursor, builder: (column) => column);

  GeneratedColumn<bool> get logMayBeIncomplete => $composableBuilder(
    column: $table.logMayBeIncomplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get myHelperId => $composableBuilder(
    column: $table.myHelperId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusJson => $composableBuilder(
    column: $table.statusJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get policyJson => $composableBuilder(
    column: $table.policyJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get removed =>
      $composableBuilder(column: $table.removed, builder: (column) => column);
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$OctoDatabase,
          $SyncStatesTable,
          SyncRow,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (SyncRow, BaseReferences<_$OctoDatabase, $SyncStatesTable, SyncRow>),
          SyncRow,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$OctoDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> computerId = const Value.absent(),
                Value<int?> logCursor = const Value.absent(),
                Value<bool> logMayBeIncomplete = const Value.absent(),
                Value<String?> myHelperId = const Value.absent(),
                Value<String?> statusJson = const Value.absent(),
                Value<String?> policyJson = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<bool> removed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                computerId: computerId,
                logCursor: logCursor,
                logMayBeIncomplete: logMayBeIncomplete,
                myHelperId: myHelperId,
                statusJson: statusJson,
                policyJson: policyJson,
                lastSeenAt: lastSeenAt,
                removed: removed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String computerId,
                Value<int?> logCursor = const Value.absent(),
                Value<bool> logMayBeIncomplete = const Value.absent(),
                Value<String?> myHelperId = const Value.absent(),
                Value<String?> statusJson = const Value.absent(),
                Value<String?> policyJson = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<bool> removed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                computerId: computerId,
                logCursor: logCursor,
                logMayBeIncomplete: logMayBeIncomplete,
                myHelperId: myHelperId,
                statusJson: statusJson,
                policyJson: policyJson,
                lastSeenAt: lastSeenAt,
                removed: removed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStatesTable, SyncRow>(table),
                  BaseReferences<_$OctoDatabase, $SyncStatesTable, SyncRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$OctoDatabase,
      $SyncStatesTable,
      SyncRow,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (SyncRow, BaseReferences<_$OctoDatabase, $SyncStatesTable, SyncRow>),
      SyncRow,
      PrefetchHooks Function()
    >;

class $OctoDatabaseManager {
  final _$OctoDatabase _db;
  $OctoDatabaseManager(this._db);
  $$ComputersTableTableManager get computers =>
      $$ComputersTableTableManager(_db, _db.computers);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
}
