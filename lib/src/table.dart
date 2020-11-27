import "dart:typed_data";

import "package:ext/ext.dart";
import "package:flutter/foundation.dart";
import "package:sqlite/sqlite.dart";

import "column.dart";
import "context.dart";
import "debug.dart";
import "expressible.dart";
import "literal_expression.dart";
import "selectable.dart";
import "setter.dart";
import "sqlite_type.dart";

T _identity<T>(T e) => e;

class Table implements Selectable {
  Table(String name)
      : assert(name.isNotEmpty, "Table name cannot be empty"),
        _tableName = name;

  final String _tableName;

  final List<Column<void>> _columns = [];

  @protected
  Column<int?> long(String name) => _register(name, SqliteType.integer);

  @protected
  Column<double?> real(String name) => _register(name, SqliteType.real);

  @protected
  Column<String?> text(String name) => _register(name, SqliteType.text);

  @protected
  Column<DateTime?> date(String name) => _register(name, SqliteType.integer);

  @protected
  Column<bool?> boolean(String name) => _register(name, SqliteType.integer);

  @protected
  Column<Uint8List?> blob(String name) => _register(name, SqliteType.blob);

  Column<T> _register<T>(String name, SqliteType type) {
    final column = Column<T>(name, this, type);
    _columns.add(column);
    return column;
  }

  @override
  List<Expressible> allExpressible() =>
      _columns.map<Expressible>(_identity).toList(growable: false);

  @override
  List<Object?> args() => const [];

  @override
  String clause(Context context) {
    final alias = context.alias(this);
    if (alias == null) {
      return _tableName;
    }
    return "$_tableName as $alias";
  }

  @override
  String toString() => _tableName;

  String createStatement() {
    final sb = StringBuffer()
      ..write("CREATE TABLE IF NOT EXISTS ")
      ..write(_tableName)
      ..write(" (");
    var first = true;
    for (final column in _columns) {
      if (first) {
        first = false;
      } else {
        sb.write(",");
      }
      sb..write("\r\n")..write(column.definition());
    }
    final primaries = _columns.where((it) => it.isPrimary);

    if (primaries.isNotEmpty) {
      sb.write(",\r\n PRIMARY KEY (");
      var f = true;
      for (final primary in primaries) {
        if (f) {
          f = false;
        } else {
          sb.write(",");
        }
        sb.write(primary.name);
      }
      sb.write(")");
    }
    final foreignKeys = _collect();
    for (final foreign in foreignKeys) {
      sb.write(",\r\nFOREIGN KEY (");
      var f = true;
      for (final column in foreign.thisKeys) {
        if (f) {
          f = false;
        } else {
          sb.write(",");
        }
        sb.write(column.name);
      }
      sb
        ..write(") REFERENCES ")
        ..write(foreign.foreignTable._tableName)
        ..write("(");
      f = true;
      for (final column in foreign.foreignKeys) {
        if (f) {
          f = false;
        } else {
          sb.write(",");
        }
        sb.write(column.name);
      }
      sb.write(")");
    }
    sb.write(")");
    return sb.toString();
  }

  List<_InternalForeignKey> _collect() {
    final foreignColumn = _columns.where((it) => it.foreignKey != null);
    final internalForeignKeys = <_InternalForeignKey>[];

    for (final col in foreignColumn) {
      final name = col.foreignKey!.otherTableName;
      var key = internalForeignKeys
          .firstOrNull((x) => x.foreignTable._tableName == name);
      if (key == null) {
        final foreignTable = col.foreignKey!.otherTable;
        key = _InternalForeignKey(foreignTable);
        key.thisKeys.add(col);
        key.foreignKeys.add(col.foreignKey!.otherColumn);
        internalForeignKeys.add(key);
      } else {
        key.thisKeys.add(col);
        key.foreignKeys.add(col.foreignKey!.otherColumn);
      }
    }
    return internalForeignKeys;
  }
}

class LackNonnullColumnError extends StateError {
  LackNonnullColumnError(Column<void> column)
      : super(
            "Insert statement lacks a nonnull column ${column.owner}.${column.name}");
}

class InsertNullValueException extends StateError {
  InsertNullValueException(Column<void> column)
      : super(
            "Insert or update a null value to a nonnull column  ${column.owner}.${column.name}");
}

extension SqlOperatorOnTable<T extends Table> on T {
  int insert(Database db, List<Setter<Object?>> Function(T table) setters) {
    final columns = setters(this);
    final nonnullColumns = _columns.where((x) => x.isNonnull).toList();

    for (final column in nonnullColumns) {
      if (!columns.any((e) => identical(e.column, column))) {
        throw LackNonnullColumnError(column);
      }
    }

    final columnStatement =
        columns.map((x) => x.column.clause(Context.empty)).join(", ");
    final valuesStatement = columns.map((_) => "?").join(", ");
    final statement =
        "INSERT INTO $_tableName ($columnStatement) VALUES($valuesStatement)";

    final args = <Object?>[];
    for (final e in columns) {
      args.addAll(LiteralExpression(e.value).args());
    }
    assert(() {
      if (enableLog) {
        print("LinQ/Insert: $statement");
        print("LinQ/Args: $args");
      }
      return true;
    }());
    return db.execute(statement, args, true);
  }
}

class _InternalForeignKey {
  _InternalForeignKey(this.foreignTable);

  final Table foreignTable;
  final List<Column<void>> thisKeys = <Column<void>>[];
  final List<Column<void>> foreignKeys = <Column<void>>[];
}
