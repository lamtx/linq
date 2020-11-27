import "dart:typed_data";

import "package:sqlite/sqlite.dart";

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
  ObjectFactory<Object?> value;
  switch (T) {
    case int:
      value = _intFactory;
      break;
    case String:
      value = _stringFactory;
      break;
    case double:
      value = _doubleFactory;
      break;
    case bool:
      value = _boolFactory;
      break;
    case DateTime:
      value = _dateFactory;
      break;
    case Uint8List:
      value = _blobFactory;
      break;
    default:
      throw UnsupportedError("Unsupported type $T to read data from sqlite");
  }

  return value as ObjectFactory<T>;
}
