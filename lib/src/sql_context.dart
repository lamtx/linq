import "package:ext/ext.dart";
import "package:sqlite/sqlite.dart";

import "annotation.dart";
import "collectible.dart";
import "context.dart";
import "debug.dart";
import "expressible.dart";
import "filterable.dart";
import "literal.dart";
import "literal_expression.dart";
import "named_expression.dart";
import "selectable.dart";
import "selector.dart";
import "setter.dart";
import "table.dart";

typedef Collector<T, R> = R Function(Selector<T> get);

class SqlContext implements Context {
  SqlContext(this.database);

  final Database database;
  final _mapping = <Selectable>[];

  @override
  Filterable<T> from<T extends Selectable>(T source) {
    _mapping.add(source);
    return Filterable(source, const []);
  }

  @override
  Filterable<T> query<T extends Selectable>(T source) => from(source);

  @override
  String? alias(Selectable source) {
    final index = _mapping.indexWhere((e) => e == source);
    if (index == -1) {
      return null;
    }
    return "t$index";
  }

  Result _fetch(Expressible expressible, Database database) {
    final query = expressible.clause(this);
    final typedArgs = expressible.args();
    assert(() {
      if (enableLog) {
        print("LinQ/Query: $query");
        print("LinQ/Args: $typedArgs");
      }
      return true;
    }());
    return database.query(query, typedArgs);
  }

  List<R> _toList<T, R>(
      Result result, T source, R Function(Selector<T>) collector) {
    final list = <R>[];
    final selector = _Selector(source);

    try {
      while (result.moveNext()) {
        selector.set(result.current);
        list.add(collector(selector));
        selector.allSet();
      }
    } finally {
      result.close();
    }
    return list;
  }

  R? _firstOrNull<T, R>(Result result, T source, Collector<T, R?> collector) {
    try {
      if (result.moveNext()) {
        final selector = _Selector(source)..set(result.current);
        return collector(selector);
      } else {
        return null;
      }
    } finally {
      result.close();
    }
  }

  bool _exist(Result result) {
    try {
      return result.moveNext();
    } finally {
      result.close();
    }
  }

  @implement
  List<R> collect<T extends Object, R>(
      Collectible<T> receiver, Collector<T, R> collector) {
    final result = _fetch(receiver, database);
    return _toList(result, receiver.source, collector);
  }

  @implement
  R? firstOrNull<T extends Object, R>(
      Collectible<T> receiver, Collector<T, R?> collector) {
    final result = _fetch(receiver, database);
    return _firstOrNull(result, receiver.source, collector);
  }

  @implement
  static void update<T extends Expressible>(Filterable<T> receiver,
      Database database, List<Setter<Object?>> Function(T) setters) {
    assert(receiver.source is Table);
    final args = receiver.args();
    final tableName = receiver.source.clause(Context.empty);
    final expressions = setters(receiver.source);
    if (expressions.isEmpty) {
      return;
    }
    final whereClause = receiver.clause(Context.empty);
    final bindArgs = <Object?>[];
    final statement = StringBuffer()
      ..write("UPDATE ")
      ..write(tableName)
      ..write(" SET");

    var appendCommas = false;
    for (final exp in expressions) {
      if (appendCommas) {
        statement.write(",");
      }
      appendCommas = true;
      statement
        ..write(" ")
        ..write(exp.column.clause(Context.empty))
        ..write(" = ?");
      bindArgs.addAll(LiteralExpression(exp.value).args());
    }
    statement
      ..write(" ")
      ..write(whereClause);
    bindArgs.addAll(args);

    assert(() {
      if (enableLog) {
        print("LinQ/Update: $statement");
        print("LinQ/Args: $bindArgs");
      }
      return true;
    }());
    database.execute(statement.toString(), bindArgs);
  }

  @implement
  static void delete<T extends Expressible>(
      Filterable<T> receiver, Database database) {
    assert(receiver.source is Selectable);
    final tableName = receiver.source.clause(Context.empty);
    final args = receiver.args();
    final whereClause = receiver.clause(Context.empty);
    final statement = whereClause.isEmpty
        ? "DELETE FROM $tableName"
        : "DELETE FROM $tableName $whereClause";

    assert(() {
      if (enableLog) {
        print("LinQ/Delete: $statement");
      }
      return true;
    }());
    database.execute(statement, args);
  }

  @implement
  bool exists(Collectible<Object> receiver) {
    final result = _fetch(receiver, database);
    return _exist(result);
  }
}

final class _Selector<T> implements Selector<T> {
  _Selector(T source) : _source = source;

  final T _source;

  Row? _current;
  var _index = 0;
  var _prepared = false;
  final _cache = <_Column<Object?>>[];

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
  R call<R>(NamedExpression<R> Function(T e) fieldName) {
    final namedColumn = fieldName(_source);
    final field = namedColumn.name;
    final current = _current ?? error("set must be called before get");

    if (_prepared) {
      final column = _cache[_index];
      _index += 1;
      assert(column.name == field, "Column mismatch");
      return column.objectFactory(current, column.index) as R;
    }

    final columnIndex = current.getColumnIndex(field) ??
        error(
          "Index out of bound. It usually happens when the number of field reading for each time are different",
        );
    final factory = findObjectFactory<R>();
    _cache.add(_Column(columnIndex, field, factory));
    return factory(current, columnIndex);
  }
}

class _Column<T> {
  _Column(this.index, this.name, this.objectFactory);

  final int index;
  final String name;
  final ObjectFactory<T> objectFactory;
}
