import "package:linq/src/sqlite_type.dart";
import "package:sqlite/sqlite.dart";

import "context.dart";
import "debug.dart";
import "foreign_key.dart";
import "literal_expression.dart";
import "named_expression.dart";
import "table.dart";

final class Column<T> implements NamedExpression<T> {
  Column(
    this.name,
    this.owner,
    this.sqliteType, {
    this.isPrimary = false,
    this.isNonnull = false,
  }) : assert(name.isNotEmpty, "Name cannot be null");

  @override
  final String name;
  final Table owner;
  final bool isPrimary;
  final bool isNonnull;

  final SqliteType sqliteType;
  T? _defaultValue;

  ForeignKey<T>? _foreignKey;

  ForeignKey<T>? get foreignKey => _foreignKey;

  T? get defaultValue => _defaultValue;

  Column<T> references(Column<T> other) {
    _foreignKey = ForeignKey(other.owner, other);
    return this;
  }

  Column<T> def(T value) {
    _defaultValue = value;
    return this;
  }

  String definition() {
    final sb = StringBuffer()
      ..write(name)
      ..write(" ")
      ..write(sqliteType.name);

    if (isNonnull || isPrimary) {
      sb.write(" NOT NULL");
    }
    if (_defaultValue != null) {
      sb.write(" DEFAULT ${LiteralExpression(_defaultValue).value}");
    }
    return sb.toString();
  }

  @override
  List<Object?> args() => const [];

  @override
  String clause(Context context) {
    final alias = context.alias(owner);
    if (alias == null) {
      return name;
    }
    return "$alias.$name";
  }
}

extension SqlOperatorOnColumn<T extends Column<Object>> on T {
  void add(Database db) {
    final statement = "ALTER TABLE $owner ADD COLUMN ${definition()}";
    assert(() {
      if (enableLog) {
        print("SQL/ALTER: $statement");
      }
      return true;
    }());
    db.execute(statement);
  }
}
