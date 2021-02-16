import "dart:typed_data";

import "package:ext/ext.dart";
import 'package:linq/src/sqlite_type.dart';
import "package:sqlite/sqlite.dart";

SqliteType sqliteTypeOf<T>() {
  final type = typeOf<T>();
  if (type == typeOf<int>() || type == typeOf<int?>()) {
    return SqliteType.integer;
  } else if (type == typeOf<String>() || type == typeOf<String?>()) {
    return SqliteType.text;
  } else if (type == typeOf<double>() || type == typeOf<double?>()) {
    return SqliteType.real;
  } else if (type == typeOf<bool>() || type == typeOf<bool?>()) {
    return SqliteType.integer;
  } else if (type == typeOf<DateTime>() || type == typeOf<DateTime?>()) {
    return SqliteType.integer;
  } else if (type == typeOf<Uint8List>() || type == typeOf<Uint8List?>()) {
    return SqliteType.blob;
  } else {
    throw UnsupportedError("Unsupported type $type to read data from sqlite");
  }
}

Object? toSQLiteLiteral(Object? value) {
  assert(value == null ||
      value is bool ||
      value is num ||
      value is String ||
      value is DateTime ||
      value is Uint8List);

  if (value is bool) {
    return value ? 1 : 0;
  }
  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }
  return value;
}

typedef ObjectFactory<T> = T Function(Row row, int columnIndex);

String? _stringFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsText(columnIndex);

int? _intFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsInt(columnIndex);

double? _doubleFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsDouble(columnIndex);

bool? _boolFactory(Row row, int columnIndex) {
  final value = row.readColumnByIndexAsInt(columnIndex);
  if (value == null) {
    return null;
  }
  return value != 0;
}

DateTime? _dateFactory(Row row, int columnIndex) {
  final value = row.readColumnByIndexAsInt(columnIndex);
  if (value == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(value);
}

Uint8List? _blobFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsBlob(columnIndex);

ObjectFactory<T> findObjectFactory<T>() {
  late final ObjectFactory<Object?> value;
  final type = typeOf<T>();
  if (type == typeOf<int>() || type == typeOf<int?>()) {
    value = _intFactory;
  } else if (type == typeOf<String>() || type == typeOf<String?>()) {
    value = _stringFactory;
  } else if (type == typeOf<double>() || type == typeOf<double?>()) {
    value = _doubleFactory;
  } else if (type == typeOf<bool>() || type == typeOf<bool?>()) {
    value = _boolFactory;
  } else if (type == typeOf<DateTime>() || type == typeOf<DateTime?>()) {
    value = _dateFactory;
  } else if (type == typeOf<Uint8List>() || type == typeOf<Uint8List?>()) {
    value = _blobFactory;
  } else {
    throw UnsupportedError("Unsupported type $type to read data from sqlite");
  }

  return value as ObjectFactory<T>;
}
