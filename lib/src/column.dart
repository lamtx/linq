import "package:sqlite/sqlite.dart";

import "context.dart";
import "debug.dart";
import "foreign_key.dart";
import "literal_expression.dart";
import "named_expression.dart";
import "sqlite_type.dart";
import "table.dart";

class Column<T> implements NamedExpression<T> {
  Column(
    this.name,
    this.owner,
    SqliteType sqliteType, {
    this.isPrimary = false,
    this.isNonnull = false,
  })  : assert(name.isNotEmpty, "Name cannot be null"),
        _sqliteType = sqliteType;

  @override
  final String name;
  final Table owner;
  final SqliteType _sqliteType;

  final bool isPrimary;
  final bool isNonnull;
  T? _defaultValue;
  ForeignKey<T>? _foreignKey;

  ForeignKey<T>? get foreignKey => _foreignKey;

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

extension ColumnExt<T extends Object> on Column<T?> {
  Column<T> primary() {
    if (_foreignKey != null) {
      throw StateError("primary should be called before the foreign key set.");
    }
    final instance = Column<T>(
      name,
      owner,
      _sqliteType,
      isPrimary: true,
      isNonnull: isNonnull,
    );
    instance._defaultValue = _defaultValue;
    return instance;
  }

  Column<T> nonnull() {
    if (_foreignKey != null) {
      throw StateError("nonnull should be called before the foreign key set.");
    }
    final instance = Column<T>(
      name,
      owner,
      _sqliteType,
      isPrimary: isPrimary,
      isNonnull: true,
    );
    instance._defaultValue = _defaultValue;
    return instance;
  }
}
