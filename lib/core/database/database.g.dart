// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LibraryFoldersTable extends LibraryFolders
    with TableInfo<$LibraryFoldersTable, LibraryFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryFoldersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, label, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $LibraryFoldersTable createAlias(String alias) {
    return $LibraryFoldersTable(attachedDatabase, alias);
  }
}

class LibraryFolder extends DataClass implements Insertable<LibraryFolder> {
  /// Auto-incrementing primary key.
  final int id;

  /// Absolute path to the folder (e.g. `/mnt/media/movies`).
  final String path;

  /// Optional user-friendly label (e.g. "NAS Movies").
  final String? label;

  /// When this folder was first added.
  final DateTime addedAt;
  const LibraryFolder({
    required this.id,
    required this.path,
    this.label,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  LibraryFoldersCompanion toCompanion(bool nullToAbsent) {
    return LibraryFoldersCompanion(
      id: Value(id),
      path: Value(path),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      addedAt: Value(addedAt),
    );
  }

  factory LibraryFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryFolder(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      label: serializer.fromJson<String?>(json['label']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'label': serializer.toJson<String?>(label),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LibraryFolder copyWith({
    int? id,
    String? path,
    Value<String?> label = const Value.absent(),
    DateTime? addedAt,
  }) => LibraryFolder(
    id: id ?? this.id,
    path: path ?? this.path,
    label: label.present ? label.value : this.label,
    addedAt: addedAt ?? this.addedAt,
  );
  LibraryFolder copyWithCompanion(LibraryFoldersCompanion data) {
    return LibraryFolder(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      label: data.label.present ? data.label.value : this.label,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryFolder(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, label, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryFolder &&
          other.id == this.id &&
          other.path == this.path &&
          other.label == this.label &&
          other.addedAt == this.addedAt);
}

class LibraryFoldersCompanion extends UpdateCompanion<LibraryFolder> {
  final Value<int> id;
  final Value<String> path;
  final Value<String?> label;
  final Value<DateTime> addedAt;
  const LibraryFoldersCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.label = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  LibraryFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.label = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : path = Value(path);
  static Insertable<LibraryFolder> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? label,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (label != null) 'label': label,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  LibraryFoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<String?>? label,
    Value<DateTime>? addedAt,
  }) {
    return LibraryFoldersCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      label: label ?? this.label,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryFoldersCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $MediaFilesTable extends MediaFiles
    with TableInfo<$MediaFilesTable, MediaFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaFilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileExtensionMeta = const VerificationMeta(
    'fileExtension',
  );
  @override
  late final GeneratedColumn<String> fileExtension = GeneratedColumn<String>(
    'file_extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<BigInt> fileSizeBytes = GeneratedColumn<BigInt>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libraryFolderIdMeta = const VerificationMeta(
    'libraryFolderId',
  );
  @override
  late final GeneratedColumn<int> libraryFolderId = GeneratedColumn<int>(
    'library_folder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_folders (id)',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMillisMeta = const VerificationMeta(
    'durationMillis',
  );
  @override
  late final GeneratedColumn<int> durationMillis = GeneratedColumn<int>(
    'duration_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMillisMeta = const VerificationMeta(
    'positionMillis',
  );
  @override
  late final GeneratedColumn<int> positionMillis = GeneratedColumn<int>(
    'position_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta(
    'lastWatchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>(
        'last_watched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbTitleMeta = const VerificationMeta(
    'tmdbTitle',
  );
  @override
  late final GeneratedColumn<String> tmdbTitle = GeneratedColumn<String>(
    'tmdb_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voteAverageMeta = const VerificationMeta(
    'voteAverage',
  );
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
    'vote_average',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalLanguageMeta = const VerificationMeta(
    'originalLanguage',
  );
  @override
  late final GeneratedColumn<String> originalLanguage = GeneratedColumn<String>(
    'original_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    fileName,
    fileExtension,
    fileSizeBytes,
    libraryFolderId,
    addedAt,
    lastModified,
    durationMillis,
    positionMillis,
    lastWatchedAt,
    tmdbId,
    mediaType,
    tmdbTitle,
    overview,
    posterPath,
    backdropPath,
    releaseYear,
    voteAverage,
    genres,
    originalLanguage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_extension')) {
      context.handle(
        _fileExtensionMeta,
        fileExtension.isAcceptableOrUnknown(
          data['file_extension']!,
          _fileExtensionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileExtensionMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('library_folder_id')) {
      context.handle(
        _libraryFolderIdMeta,
        libraryFolderId.isAcceptableOrUnknown(
          data['library_folder_id']!,
          _libraryFolderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryFolderIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    if (data.containsKey('duration_millis')) {
      context.handle(
        _durationMillisMeta,
        durationMillis.isAcceptableOrUnknown(
          data['duration_millis']!,
          _durationMillisMeta,
        ),
      );
    }
    if (data.containsKey('position_millis')) {
      context.handle(
        _positionMillisMeta,
        positionMillis.isAcceptableOrUnknown(
          data['position_millis']!,
          _positionMillisMeta,
        ),
      );
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(
          data['last_watched_at']!,
          _lastWatchedAtMeta,
        ),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('tmdb_title')) {
      context.handle(
        _tmdbTitleMeta,
        tmdbTitle.isAcceptableOrUnknown(data['tmdb_title']!, _tmdbTitleMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('vote_average')) {
      context.handle(
        _voteAverageMeta,
        voteAverage.isAcceptableOrUnknown(
          data['vote_average']!,
          _voteAverageMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('original_language')) {
      context.handle(
        _originalLanguageMeta,
        originalLanguage.isAcceptableOrUnknown(
          data['original_language']!,
          _originalLanguageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_extension'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      libraryFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}library_folder_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      durationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_millis'],
      ),
      positionMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_millis'],
      ),
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched_at'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      ),
      tmdbTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tmdb_title'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      voteAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vote_average'],
      ),
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      ),
      originalLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_language'],
      ),
    );
  }

  @override
  $MediaFilesTable createAlias(String alias) {
    return $MediaFilesTable(attachedDatabase, alias);
  }
}

class MediaFile extends DataClass implements Insertable<MediaFile> {
  /// Auto-incrementing primary key.
  final int id;

  /// Full absolute path to the file.
  final String filePath;

  /// Basename without extension (used as display title until TMDB metadata).
  final String fileName;

  /// File extension without the dot (e.g. `mkv`, `mp4`).
  final String fileExtension;

  /// File size in bytes.
  final BigInt fileSizeBytes;

  /// Foreign key to the parent library folder.
  final int libraryFolderId;

  /// When this file was first discovered by the scanner.
  final DateTime addedAt;

  /// Last-modified time from the filesystem.
  final DateTime lastModified;

  /// Total duration of the media in milliseconds (Phase 3).
  final int? durationMillis;

  /// Last watched position in milliseconds (Phase 3).
  final int? positionMillis;

  /// Timestamp of the last time the user watched this file.
  /// Updated on every pause/stop so the Continue Watching section can
  /// determine the most recently watched episode within a TV series.
  final DateTime? lastWatchedAt;

  /// TMDB ID for this media. Non-null means metadata has been matched.
  final int? tmdbId;

  /// Resolved media type: 'movie', 'tv', 'anime', or 'uncategorized'.
  final String? mediaType;

  /// TMDB display title (falls back to [fileName] in the UI).
  final String? tmdbTitle;

  /// Plot synopsis from TMDB.
  final String? overview;

  /// TMDB poster path (e.g. `/abc123.jpg`). Combine with base URL to get full URL.
  final String? posterPath;

  /// TMDB backdrop path. Combine with base URL to get full URL.
  final String? backdropPath;

  /// Release year extracted from TMDB release_date / first_air_date.
  final int? releaseYear;

  /// TMDB vote average (0.0–10.0).
  final double? voteAverage;

  /// Comma-separated genre names (e.g. "Action,Sci-Fi,Drama").
  final String? genres;

  /// Original language code from TMDB (e.g. "en", "ja").
  final String? originalLanguage;
  const MediaFile({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.libraryFolderId,
    required this.addedAt,
    required this.lastModified,
    this.durationMillis,
    this.positionMillis,
    this.lastWatchedAt,
    this.tmdbId,
    this.mediaType,
    this.tmdbTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseYear,
    this.voteAverage,
    this.genres,
    this.originalLanguage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['file_extension'] = Variable<String>(fileExtension);
    map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes);
    map['library_folder_id'] = Variable<int>(libraryFolderId);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['last_modified'] = Variable<DateTime>(lastModified);
    if (!nullToAbsent || durationMillis != null) {
      map['duration_millis'] = Variable<int>(durationMillis);
    }
    if (!nullToAbsent || positionMillis != null) {
      map['position_millis'] = Variable<int>(positionMillis);
    }
    if (!nullToAbsent || lastWatchedAt != null) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    if (!nullToAbsent || mediaType != null) {
      map['media_type'] = Variable<String>(mediaType);
    }
    if (!nullToAbsent || tmdbTitle != null) {
      map['tmdb_title'] = Variable<String>(tmdbTitle);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || voteAverage != null) {
      map['vote_average'] = Variable<double>(voteAverage);
    }
    if (!nullToAbsent || genres != null) {
      map['genres'] = Variable<String>(genres);
    }
    if (!nullToAbsent || originalLanguage != null) {
      map['original_language'] = Variable<String>(originalLanguage);
    }
    return map;
  }

  MediaFilesCompanion toCompanion(bool nullToAbsent) {
    return MediaFilesCompanion(
      id: Value(id),
      filePath: Value(filePath),
      fileName: Value(fileName),
      fileExtension: Value(fileExtension),
      fileSizeBytes: Value(fileSizeBytes),
      libraryFolderId: Value(libraryFolderId),
      addedAt: Value(addedAt),
      lastModified: Value(lastModified),
      durationMillis: durationMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMillis),
      positionMillis: positionMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(positionMillis),
      lastWatchedAt: lastWatchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWatchedAt),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      mediaType: mediaType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaType),
      tmdbTitle: tmdbTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbTitle),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      voteAverage: voteAverage == null && nullToAbsent
          ? const Value.absent()
          : Value(voteAverage),
      genres: genres == null && nullToAbsent
          ? const Value.absent()
          : Value(genres),
      originalLanguage: originalLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(originalLanguage),
    );
  }

  factory MediaFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFile(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileExtension: serializer.fromJson<String>(json['fileExtension']),
      fileSizeBytes: serializer.fromJson<BigInt>(json['fileSizeBytes']),
      libraryFolderId: serializer.fromJson<int>(json['libraryFolderId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      durationMillis: serializer.fromJson<int?>(json['durationMillis']),
      positionMillis: serializer.fromJson<int?>(json['positionMillis']),
      lastWatchedAt: serializer.fromJson<DateTime?>(json['lastWatchedAt']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      mediaType: serializer.fromJson<String?>(json['mediaType']),
      tmdbTitle: serializer.fromJson<String?>(json['tmdbTitle']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      voteAverage: serializer.fromJson<double?>(json['voteAverage']),
      genres: serializer.fromJson<String?>(json['genres']),
      originalLanguage: serializer.fromJson<String?>(json['originalLanguage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'fileExtension': serializer.toJson<String>(fileExtension),
      'fileSizeBytes': serializer.toJson<BigInt>(fileSizeBytes),
      'libraryFolderId': serializer.toJson<int>(libraryFolderId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'durationMillis': serializer.toJson<int?>(durationMillis),
      'positionMillis': serializer.toJson<int?>(positionMillis),
      'lastWatchedAt': serializer.toJson<DateTime?>(lastWatchedAt),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'mediaType': serializer.toJson<String?>(mediaType),
      'tmdbTitle': serializer.toJson<String?>(tmdbTitle),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'voteAverage': serializer.toJson<double?>(voteAverage),
      'genres': serializer.toJson<String?>(genres),
      'originalLanguage': serializer.toJson<String?>(originalLanguage),
    };
  }

  MediaFile copyWith({
    int? id,
    String? filePath,
    String? fileName,
    String? fileExtension,
    BigInt? fileSizeBytes,
    int? libraryFolderId,
    DateTime? addedAt,
    DateTime? lastModified,
    Value<int?> durationMillis = const Value.absent(),
    Value<int?> positionMillis = const Value.absent(),
    Value<DateTime?> lastWatchedAt = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    Value<String?> mediaType = const Value.absent(),
    Value<String?> tmdbTitle = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    Value<double?> voteAverage = const Value.absent(),
    Value<String?> genres = const Value.absent(),
    Value<String?> originalLanguage = const Value.absent(),
  }) => MediaFile(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    fileName: fileName ?? this.fileName,
    fileExtension: fileExtension ?? this.fileExtension,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    libraryFolderId: libraryFolderId ?? this.libraryFolderId,
    addedAt: addedAt ?? this.addedAt,
    lastModified: lastModified ?? this.lastModified,
    durationMillis: durationMillis.present
        ? durationMillis.value
        : this.durationMillis,
    positionMillis: positionMillis.present
        ? positionMillis.value
        : this.positionMillis,
    lastWatchedAt: lastWatchedAt.present
        ? lastWatchedAt.value
        : this.lastWatchedAt,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    mediaType: mediaType.present ? mediaType.value : this.mediaType,
    tmdbTitle: tmdbTitle.present ? tmdbTitle.value : this.tmdbTitle,
    overview: overview.present ? overview.value : this.overview,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    voteAverage: voteAverage.present ? voteAverage.value : this.voteAverage,
    genres: genres.present ? genres.value : this.genres,
    originalLanguage: originalLanguage.present
        ? originalLanguage.value
        : this.originalLanguage,
  );
  MediaFile copyWithCompanion(MediaFilesCompanion data) {
    return MediaFile(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileExtension: data.fileExtension.present
          ? data.fileExtension.value
          : this.fileExtension,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      libraryFolderId: data.libraryFolderId.present
          ? data.libraryFolderId.value
          : this.libraryFolderId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      durationMillis: data.durationMillis.present
          ? data.durationMillis.value
          : this.durationMillis,
      positionMillis: data.positionMillis.present
          ? data.positionMillis.value
          : this.positionMillis,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      tmdbTitle: data.tmdbTitle.present ? data.tmdbTitle.value : this.tmdbTitle,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      voteAverage: data.voteAverage.present
          ? data.voteAverage.value
          : this.voteAverage,
      genres: data.genres.present ? data.genres.value : this.genres,
      originalLanguage: data.originalLanguage.present
          ? data.originalLanguage.value
          : this.originalLanguage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaFile(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('libraryFolderId: $libraryFolderId, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('positionMillis: $positionMillis, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('tmdbTitle: $tmdbTitle, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('genres: $genres, ')
          ..write('originalLanguage: $originalLanguage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    filePath,
    fileName,
    fileExtension,
    fileSizeBytes,
    libraryFolderId,
    addedAt,
    lastModified,
    durationMillis,
    positionMillis,
    lastWatchedAt,
    tmdbId,
    mediaType,
    tmdbTitle,
    overview,
    posterPath,
    backdropPath,
    releaseYear,
    voteAverage,
    genres,
    originalLanguage,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFile &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.fileExtension == this.fileExtension &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.libraryFolderId == this.libraryFolderId &&
          other.addedAt == this.addedAt &&
          other.lastModified == this.lastModified &&
          other.durationMillis == this.durationMillis &&
          other.positionMillis == this.positionMillis &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.tmdbId == this.tmdbId &&
          other.mediaType == this.mediaType &&
          other.tmdbTitle == this.tmdbTitle &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.releaseYear == this.releaseYear &&
          other.voteAverage == this.voteAverage &&
          other.genres == this.genres &&
          other.originalLanguage == this.originalLanguage);
}

class MediaFilesCompanion extends UpdateCompanion<MediaFile> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<String> fileExtension;
  final Value<BigInt> fileSizeBytes;
  final Value<int> libraryFolderId;
  final Value<DateTime> addedAt;
  final Value<DateTime> lastModified;
  final Value<int?> durationMillis;
  final Value<int?> positionMillis;
  final Value<DateTime?> lastWatchedAt;
  final Value<int?> tmdbId;
  final Value<String?> mediaType;
  final Value<String?> tmdbTitle;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<int?> releaseYear;
  final Value<double?> voteAverage;
  final Value<String?> genres;
  final Value<String?> originalLanguage;
  const MediaFilesCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.libraryFolderId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.positionMillis = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.tmdbTitle = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.genres = const Value.absent(),
    this.originalLanguage = const Value.absent(),
  });
  MediaFilesCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    required String fileName,
    required String fileExtension,
    required BigInt fileSizeBytes,
    required int libraryFolderId,
    this.addedAt = const Value.absent(),
    required DateTime lastModified,
    this.durationMillis = const Value.absent(),
    this.positionMillis = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.tmdbTitle = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.genres = const Value.absent(),
    this.originalLanguage = const Value.absent(),
  }) : filePath = Value(filePath),
       fileName = Value(fileName),
       fileExtension = Value(fileExtension),
       fileSizeBytes = Value(fileSizeBytes),
       libraryFolderId = Value(libraryFolderId),
       lastModified = Value(lastModified);
  static Insertable<MediaFile> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? fileExtension,
    Expression<BigInt>? fileSizeBytes,
    Expression<int>? libraryFolderId,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastModified,
    Expression<int>? durationMillis,
    Expression<int>? positionMillis,
    Expression<DateTime>? lastWatchedAt,
    Expression<int>? tmdbId,
    Expression<String>? mediaType,
    Expression<String>? tmdbTitle,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<int>? releaseYear,
    Expression<double>? voteAverage,
    Expression<String>? genres,
    Expression<String>? originalLanguage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (fileExtension != null) 'file_extension': fileExtension,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (libraryFolderId != null) 'library_folder_id': libraryFolderId,
      if (addedAt != null) 'added_at': addedAt,
      if (lastModified != null) 'last_modified': lastModified,
      if (durationMillis != null) 'duration_millis': durationMillis,
      if (positionMillis != null) 'position_millis': positionMillis,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (mediaType != null) 'media_type': mediaType,
      if (tmdbTitle != null) 'tmdb_title': tmdbTitle,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (releaseYear != null) 'release_year': releaseYear,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (genres != null) 'genres': genres,
      if (originalLanguage != null) 'original_language': originalLanguage,
    });
  }

  MediaFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? filePath,
    Value<String>? fileName,
    Value<String>? fileExtension,
    Value<BigInt>? fileSizeBytes,
    Value<int>? libraryFolderId,
    Value<DateTime>? addedAt,
    Value<DateTime>? lastModified,
    Value<int?>? durationMillis,
    Value<int?>? positionMillis,
    Value<DateTime?>? lastWatchedAt,
    Value<int?>? tmdbId,
    Value<String?>? mediaType,
    Value<String?>? tmdbTitle,
    Value<String?>? overview,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<int?>? releaseYear,
    Value<double?>? voteAverage,
    Value<String?>? genres,
    Value<String?>? originalLanguage,
  }) {
    return MediaFilesCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      libraryFolderId: libraryFolderId ?? this.libraryFolderId,
      addedAt: addedAt ?? this.addedAt,
      lastModified: lastModified ?? this.lastModified,
      durationMillis: durationMillis ?? this.durationMillis,
      positionMillis: positionMillis ?? this.positionMillis,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      tmdbTitle: tmdbTitle ?? this.tmdbTitle,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseYear: releaseYear ?? this.releaseYear,
      voteAverage: voteAverage ?? this.voteAverage,
      genres: genres ?? this.genres,
      originalLanguage: originalLanguage ?? this.originalLanguage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileExtension.present) {
      map['file_extension'] = Variable<String>(fileExtension.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes.value);
    }
    if (libraryFolderId.present) {
      map['library_folder_id'] = Variable<int>(libraryFolderId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (durationMillis.present) {
      map['duration_millis'] = Variable<int>(durationMillis.value);
    }
    if (positionMillis.present) {
      map['position_millis'] = Variable<int>(positionMillis.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (tmdbTitle.present) {
      map['tmdb_title'] = Variable<String>(tmdbTitle.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (originalLanguage.present) {
      map['original_language'] = Variable<String>(originalLanguage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaFilesCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('libraryFolderId: $libraryFolderId, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastModified: $lastModified, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('positionMillis: $positionMillis, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('tmdbTitle: $tmdbTitle, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('genres: $genres, ')
          ..write('originalLanguage: $originalLanguage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LibraryFoldersTable libraryFolders = $LibraryFoldersTable(this);
  late final $MediaFilesTable mediaFiles = $MediaFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryFolders,
    mediaFiles,
  ];
}

typedef $$LibraryFoldersTableCreateCompanionBuilder =
    LibraryFoldersCompanion Function({
      Value<int> id,
      required String path,
      Value<String?> label,
      Value<DateTime> addedAt,
    });
typedef $$LibraryFoldersTableUpdateCompanionBuilder =
    LibraryFoldersCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<String?> label,
      Value<DateTime> addedAt,
    });

final class $$LibraryFoldersTableReferences
    extends BaseReferences<_$AppDatabase, $LibraryFoldersTable, LibraryFolder> {
  $$LibraryFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$MediaFilesTable, List<MediaFile>>
  _mediaFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaFiles,
    aliasName: $_aliasNameGenerator(
      db.libraryFolders.id,
      db.mediaFiles.libraryFolderId,
    ),
  );

  $$MediaFilesTableProcessedTableManager get mediaFilesRefs {
    final manager = $$MediaFilesTableTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.libraryFolderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryFoldersTable> {
  $$LibraryFoldersTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaFilesRefs(
    Expression<bool> Function($$MediaFilesTableFilterComposer f) f,
  ) {
    final $$MediaFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.libraryFolderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryFoldersTable> {
  $$LibraryFoldersTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryFoldersTable> {
  $$LibraryFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  Expression<T> mediaFilesRefs<T extends Object>(
    Expression<T> Function($$MediaFilesTableAnnotationComposer a) f,
  ) {
    final $$MediaFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.libraryFolderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryFoldersTable,
          LibraryFolder,
          $$LibraryFoldersTableFilterComposer,
          $$LibraryFoldersTableOrderingComposer,
          $$LibraryFoldersTableAnnotationComposer,
          $$LibraryFoldersTableCreateCompanionBuilder,
          $$LibraryFoldersTableUpdateCompanionBuilder,
          (LibraryFolder, $$LibraryFoldersTableReferences),
          LibraryFolder,
          PrefetchHooks Function({bool mediaFilesRefs})
        > {
  $$LibraryFoldersTableTableManager(
    _$AppDatabase db,
    $LibraryFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => LibraryFoldersCompanion(
                id: id,
                path: path,
                label: label,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                Value<String?> label = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => LibraryFoldersCompanion.insert(
                id: id,
                path: path,
                label: label,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LibraryFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mediaFilesRefs) db.mediaFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mediaFilesRefs)
                    await $_getPrefetchedData<
                      LibraryFolder,
                      $LibraryFoldersTable,
                      MediaFile
                    >(
                      currentTable: table,
                      referencedTable: $$LibraryFoldersTableReferences
                          ._mediaFilesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LibraryFoldersTableReferences(
                            db,
                            table,
                            p0,
                          ).mediaFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.libraryFolderId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LibraryFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryFoldersTable,
      LibraryFolder,
      $$LibraryFoldersTableFilterComposer,
      $$LibraryFoldersTableOrderingComposer,
      $$LibraryFoldersTableAnnotationComposer,
      $$LibraryFoldersTableCreateCompanionBuilder,
      $$LibraryFoldersTableUpdateCompanionBuilder,
      (LibraryFolder, $$LibraryFoldersTableReferences),
      LibraryFolder,
      PrefetchHooks Function({bool mediaFilesRefs})
    >;
typedef $$MediaFilesTableCreateCompanionBuilder =
    MediaFilesCompanion Function({
      Value<int> id,
      required String filePath,
      required String fileName,
      required String fileExtension,
      required BigInt fileSizeBytes,
      required int libraryFolderId,
      Value<DateTime> addedAt,
      required DateTime lastModified,
      Value<int?> durationMillis,
      Value<int?> positionMillis,
      Value<DateTime?> lastWatchedAt,
      Value<int?> tmdbId,
      Value<String?> mediaType,
      Value<String?> tmdbTitle,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<int?> releaseYear,
      Value<double?> voteAverage,
      Value<String?> genres,
      Value<String?> originalLanguage,
    });
typedef $$MediaFilesTableUpdateCompanionBuilder =
    MediaFilesCompanion Function({
      Value<int> id,
      Value<String> filePath,
      Value<String> fileName,
      Value<String> fileExtension,
      Value<BigInt> fileSizeBytes,
      Value<int> libraryFolderId,
      Value<DateTime> addedAt,
      Value<DateTime> lastModified,
      Value<int?> durationMillis,
      Value<int?> positionMillis,
      Value<DateTime?> lastWatchedAt,
      Value<int?> tmdbId,
      Value<String?> mediaType,
      Value<String?> tmdbTitle,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<int?> releaseYear,
      Value<double?> voteAverage,
      Value<String?> genres,
      Value<String?> originalLanguage,
    });

final class $$MediaFilesTableReferences
    extends BaseReferences<_$AppDatabase, $MediaFilesTable, MediaFile> {
  $$MediaFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryFoldersTable _libraryFolderIdTable(_$AppDatabase db) =>
      db.libraryFolders.createAlias(
        $_aliasNameGenerator(
          db.mediaFiles.libraryFolderId,
          db.libraryFolders.id,
        ),
      );

  $$LibraryFoldersTableProcessedTableManager get libraryFolderId {
    final $_column = $_itemColumn<int>('library_folder_id')!;

    final manager = $$LibraryFoldersTableTableManager(
      $_db,
      $_db.libraryFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryFolderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaFilesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMillis => $composableBuilder(
    column: $table.positionMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tmdbTitle => $composableBuilder(
    column: $table.tmdbTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalLanguage => $composableBuilder(
    column: $table.originalLanguage,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryFoldersTableFilterComposer get libraryFolderId {
    final $$LibraryFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryFolderId,
      referencedTable: $db.libraryFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryFoldersTableFilterComposer(
            $db: $db,
            $table: $db.libraryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMillis => $composableBuilder(
    column: $table.positionMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tmdbTitle => $composableBuilder(
    column: $table.tmdbTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalLanguage => $composableBuilder(
    column: $table.originalLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryFoldersTableOrderingComposer get libraryFolderId {
    final $$LibraryFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryFolderId,
      referencedTable: $db.libraryFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.libraryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaFilesTable> {
  $$MediaFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMillis => $composableBuilder(
    column: $table.positionMillis,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get tmdbTitle =>
      $composableBuilder(column: $table.tmdbTitle, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get originalLanguage => $composableBuilder(
    column: $table.originalLanguage,
    builder: (column) => column,
  );

  $$LibraryFoldersTableAnnotationComposer get libraryFolderId {
    final $$LibraryFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryFolderId,
      referencedTable: $db.libraryFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaFilesTable,
          MediaFile,
          $$MediaFilesTableFilterComposer,
          $$MediaFilesTableOrderingComposer,
          $$MediaFilesTableAnnotationComposer,
          $$MediaFilesTableCreateCompanionBuilder,
          $$MediaFilesTableUpdateCompanionBuilder,
          (MediaFile, $$MediaFilesTableReferences),
          MediaFile,
          PrefetchHooks Function({bool libraryFolderId})
        > {
  $$MediaFilesTableTableManager(_$AppDatabase db, $MediaFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<BigInt> fileSizeBytes = const Value.absent(),
                Value<int> libraryFolderId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<int?> durationMillis = const Value.absent(),
                Value<int?> positionMillis = const Value.absent(),
                Value<DateTime?> lastWatchedAt = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String?> mediaType = const Value.absent(),
                Value<String?> tmdbTitle = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<double?> voteAverage = const Value.absent(),
                Value<String?> genres = const Value.absent(),
                Value<String?> originalLanguage = const Value.absent(),
              }) => MediaFilesCompanion(
                id: id,
                filePath: filePath,
                fileName: fileName,
                fileExtension: fileExtension,
                fileSizeBytes: fileSizeBytes,
                libraryFolderId: libraryFolderId,
                addedAt: addedAt,
                lastModified: lastModified,
                durationMillis: durationMillis,
                positionMillis: positionMillis,
                lastWatchedAt: lastWatchedAt,
                tmdbId: tmdbId,
                mediaType: mediaType,
                tmdbTitle: tmdbTitle,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseYear: releaseYear,
                voteAverage: voteAverage,
                genres: genres,
                originalLanguage: originalLanguage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String filePath,
                required String fileName,
                required String fileExtension,
                required BigInt fileSizeBytes,
                required int libraryFolderId,
                Value<DateTime> addedAt = const Value.absent(),
                required DateTime lastModified,
                Value<int?> durationMillis = const Value.absent(),
                Value<int?> positionMillis = const Value.absent(),
                Value<DateTime?> lastWatchedAt = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String?> mediaType = const Value.absent(),
                Value<String?> tmdbTitle = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<double?> voteAverage = const Value.absent(),
                Value<String?> genres = const Value.absent(),
                Value<String?> originalLanguage = const Value.absent(),
              }) => MediaFilesCompanion.insert(
                id: id,
                filePath: filePath,
                fileName: fileName,
                fileExtension: fileExtension,
                fileSizeBytes: fileSizeBytes,
                libraryFolderId: libraryFolderId,
                addedAt: addedAt,
                lastModified: lastModified,
                durationMillis: durationMillis,
                positionMillis: positionMillis,
                lastWatchedAt: lastWatchedAt,
                tmdbId: tmdbId,
                mediaType: mediaType,
                tmdbTitle: tmdbTitle,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseYear: releaseYear,
                voteAverage: voteAverage,
                genres: genres,
                originalLanguage: originalLanguage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({libraryFolderId = false}) {
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
                    if (libraryFolderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.libraryFolderId,
                                referencedTable: $$MediaFilesTableReferences
                                    ._libraryFolderIdTable(db),
                                referencedColumn: $$MediaFilesTableReferences
                                    ._libraryFolderIdTable(db)
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

typedef $$MediaFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaFilesTable,
      MediaFile,
      $$MediaFilesTableFilterComposer,
      $$MediaFilesTableOrderingComposer,
      $$MediaFilesTableAnnotationComposer,
      $$MediaFilesTableCreateCompanionBuilder,
      $$MediaFilesTableUpdateCompanionBuilder,
      (MediaFile, $$MediaFilesTableReferences),
      MediaFile,
      PrefetchHooks Function({bool libraryFolderId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LibraryFoldersTableTableManager get libraryFolders =>
      $$LibraryFoldersTableTableManager(_db, _db.libraryFolders);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db, _db.mediaFiles);
}
