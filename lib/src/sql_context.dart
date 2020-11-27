import "package:sqlite/sqlite.dart";

import "annotation.dart";
import "collectible.dart";
import "collector.dart";
import "context.dart";
import "debug.dart";
import "expressible.dart";
import "filterable.dart";
import "literal_expression.dart";
import "selectable.dart";
import "setter.dart";
import "table.dart";

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
      Result result, T source, R Function(Collector<T>) creator) {
    final list = <R>[];
    final collector = CollectorImpl(source);

    try {
      while (result.moveNext()) {
        collector.set(result.current);
        list.add(creator(collector));
        collector.allSet();
      }
    } finally {
      result.close();
    }
    return list;
  }

  R? _firstOrNull<T, R>(
      Result result, T source, R Function(Collector<T>) creator) {
    try {
      if (result.moveNext()) {
        final collector = CollectorImpl(source)..set(result.current);
        return creator(collector);
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
      Collectible<T> receiver, R Function(Collector<T>) creator) {
    final result = _fetch(receiver, database);
    return _toList(result, receiver.source, creator);
  }

  @implement
  R? firstOrNull<T extends Object, R>(
      Collectible<T> receiver, R Function(Collector<T>) creator) {
    final result = _fetch(receiver, database);
    return _firstOrNull(result, receiver.source, creator);
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
    statement..write(" WHERE ")..write(whereClause);
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
        : "DELETE FROM $tableName WHERE $whereClause";

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
