import "package:sqlite/sqlite.dart";

import "context.dart";
import "debug.dart";
import "foreign_key.dart";
import "literal_expression.dart";
import "named_expression.dart";
import "sqlite_type.dart";
import "table.dart";

class Column<T> implements NamedExpression<T> {
  Column(this.name, this.owner, SqliteType sqliteType)
      : assert(name != null && name.isNotEmpty, "Name is null or empty"),
        assert(owner != null),
        assert(sqliteType != null),
        _sqliteType = sqliteType;

  @override
  final String name;
  final Table owner;
  final SqliteType _sqliteType;

  var _isPrimary = false;
  var _isNonnull = false;
  T _defaultValue;
  ForeignKey<T> _foreignKey;

  bool get isPrimary => _isPrimary;

  T get defaultValue => _defaultValue;

  ForeignKey<T> get foreignKey => _foreignKey;

  bool get isNonnull => _isNonnull;

  Column<T> primary() {
    _isPrimary = true;
    return this;
  }

  Column<T> nonnull() {
    _isNonnull = true;
    return this;
  }

  Column<T> references(Column<T> other) {
    _foreignKey = ForeignKey(other.owner, other);
    return this;
  }

  Column<T> def(T value) {
    _defaultValue = value;
    return this;
  }

  String definition() {
    final sb = StringBuffer()..write(name)..write(" ")..write(_sqliteType.name);

    if (_isNonnull || _isPrimary) {
      sb.write(" NOT NULL");
    }
    if (_defaultValue != null) {
      sb.write(" DEFAULT ${LiteralExpression(_defaultValue).value}");
    }
    return sb.toString();
  }

  @override
  List<Object> args() => const [];

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
