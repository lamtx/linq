import 'dart:typed_data';

import "package:collection/collection.dart";
import 'package:meta/meta.dart';
import "package:sqlite/sqlite.dart";

import "column.dart";
import "context.dart";
import "debug.dart";
import "expressible.dart";
import 'literal.dart';
import "selectable.dart";
import "setter.dart";
import "sqlite_type.dart";

T _identity<T>(T e) => e;

base class Table implements Selectable {
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

  Column<T> _register<T>(String name, SqliteType sqliteType) {
    final column = Column<T>(name, this, sqliteType);
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
      sb
        ..write("\r\n")
        ..write(column.definition());
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
          .firstWhereOrNull((x) => x.foreignTable._tableName == name);
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
    final nonnullColumns =
        _columns.where((x) => x.isNonnull && !x.isRowIdAlias).toList();

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
      args.add(toSQLiteLiteral(e.value));
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

  void insertMany(
    Database db,
    Iterable<List<Setter<Object?>>> Function(T table) setters,
  ) {
    final table = setters(this);
    db.beginTransaction();
    PreparedStatement? statement;
    try {
      for (final columns in table) {
        if (statement == null) {
          final columnStatement =
              columns.map((x) => x.column.clause(Context.empty)).join(", ");
          final valuesStatement = columns.map((_) => "?").join(", ");
          final statementStr =
              "INSERT INTO $_tableName ($columnStatement) VALUES($valuesStatement)";
          statement = db.prepare(statementStr);
        }
        final args = List.generate(
          columns.length,
          (i) => toSQLiteLiteral(columns[i].value),
        );
        statement.execute(args);
      }
    } finally {
      statement?.release();
      db.endTransaction();
    }
  }
}

class _InternalForeignKey {
  _InternalForeignKey(this.foreignTable);

  final Table foreignTable;
  final List<Column<void>> thisKeys = <Column<void>>[];
  final List<Column<void>> foreignKeys = <Column<void>>[];
}

extension ColumnExt<T extends Object> on Column<T?> {
  Column<T> primary() {
    if (foreignKey != null) {
      throw StateError("primary should be called before the foreign key set.");
    }
    final instance = Column<T>(
      name,
      owner,
      sqliteType,
      isPrimary: true,
      isNonnull: isNonnull,
    );
    if (defaultValue != null) {
      instance.def(defaultValue!);
    }
    _replace(instance);
    return instance;
  }

  Column<T> nonnull() {
    if (foreignKey != null) {
      throw StateError("nonnull should be called before the foreign key set.");
    }
    final instance = Column<T>(
      name,
      owner,
      sqliteType,
      isPrimary: isPrimary,
      isNonnull: true,
    );
    if (defaultValue != null) {
      instance.def(defaultValue!);
    }
    _replace(instance);
    return instance;
  }

  void _replace(Column newValue) {
    final index = owner._columns.indexOf(this);
    assert(index != -1, "Old value not found");
    owner._columns[index] = newValue;
  }
}

extension on Column {
  /// In SQLite, a column with type INTEGER PRIMARY KEY is an alias for the ROWID
  /// (except in WITHOUT ROWID tables) which is always a 64-bit signed integer.
  bool get isRowIdAlias {
    return sqliteType == SqliteType.integer && isPrimary;
  }
}
