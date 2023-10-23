import "dart:typed_data";

import "package:ext/ext.dart";
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

String _nonnullStringFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsText(columnIndex) ?? _throwValueNull();

int? _intFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsInt(columnIndex);

int _nonnullIntFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsInt(columnIndex) ?? _throwValueNull();

double? _doubleFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsDouble(columnIndex);

double _nonnullDoubleFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsDouble(columnIndex) ?? _throwValueNull();

bool? _boolFactory(Row row, int columnIndex) {
  final value = row.readColumnByIndexAsInt(columnIndex);
  if (value == null) {
    return null;
  }
  return value != 0;
}

bool _nonnullBoolFactory(Row row, int columnIndex) =>
    _boolFactory(row, columnIndex) ?? _throwValueNull();

DateTime? _dateFactory(Row row, int columnIndex) {
  final value = row.readColumnByIndexAsInt(columnIndex);
  if (value == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(value);
}

DateTime _nonnullDateFactory(Row row, int columnIndex) =>
    _dateFactory(row, columnIndex) ?? _throwValueNull();

Uint8List? _blobFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsBlob(columnIndex);

Uint8List _nonnullBlobFactory(Row row, int columnIndex) =>
    row.readColumnByIndexAsBlob(columnIndex) ?? _throwValueNull();

ObjectFactory<T> findObjectFactory<T>() {
  late final ObjectFactory<Object?> value;
  final type = typeOf<T>();
  if (type == typeOf<int>()) {
    value = _nonnullIntFactory;
  } else if (type == typeOf<int?>()) {
    value = _intFactory;
  } else if (type == typeOf<String>()) {
    value = _nonnullStringFactory;
  } else if (type == typeOf<String?>()) {
    value = _stringFactory;
  } else if (type == typeOf<double>()) {
    value = _nonnullDoubleFactory;
  } else if (type == typeOf<double?>()) {
    value = _doubleFactory;
  } else if (type == typeOf<bool>()) {
    value = _nonnullBoolFactory;
  } else if (type == typeOf<bool?>()) {
    value = _boolFactory;
  } else if (type == typeOf<DateTime>()) {
    value = _nonnullDateFactory;
  } else if (type == typeOf<DateTime?>()) {
    value = _dateFactory;
  } else if (type == typeOf<Uint8List>()) {
    value = _nonnullBlobFactory;
  } else if (type == typeOf<Uint8List?>()) {
    value = _blobFactory;
  } else {
    throw UnsupportedError("Unsupported type $type to read data from sqlite");
  }

  return value as ObjectFactory<T>;
}

Never _throwValueNull() => throw _SQLValueNullException();

class _SQLValueNullException implements Exception {
  const _SQLValueNullException();
}
