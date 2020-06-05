import "package:sqlite/sqlite.dart";

import "column.dart";
import "literal.dart";
import "named_expression.dart";

abstract class Collector<T> {
  R get<R>(NamedExpression<R> Function(T) fieldName);
}

class CollectorImpl<T> implements Collector<T> {
  CollectorImpl(T source) : _source = source;

  final T _source;

  Row _current;
  var _index = 0;
  var _prepared = false;
  final _cache = <_Column<Object>>[];

  void allSet() {
    _current = null;
    _index = 0;
    _prepared = true;
  }

  void set(Row row) {
    _current = row;
    _index = 0;
  }

  @override
  R get<R>(NamedExpression<R> Function(T) fieldName) {
    final namedColumn = fieldName(_source);
    final field = namedColumn.name;
    if (_prepared) {
      final column = _cache[_index];
      _index += 1;
      assert(column.name == field, "Column mismatch");
      return (column.objectFactory(_current, column.index) ??
          _defaultValueOf(namedColumn)) as R;
    }
    final columnIndex = _current.getColumnIndex(field);
    final factory = findObjectFactory<R>();
    _cache.add(_Column(columnIndex, field, factory));
    return factory(_current, columnIndex) ?? _defaultValueOf(namedColumn);
  }

  static R _defaultValueOf<R>(NamedExpression<R> column) {
    if (column is Column<R>) {
      return column.defaultValue;
    }
    return null;
  }
}

class _Column<T> {
  _Column(this.index, this.name, this.objectFactory);

  final int index;
  final String name;
  final ObjectFactory<Object> objectFactory;
}
