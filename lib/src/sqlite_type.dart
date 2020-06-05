class SqliteType {
    const SqliteType._(this.name);

    final String name;

    static const integer = SqliteType._("INTEGER");
    static const real = SqliteType._("REAL");
    static const text = SqliteType._("TEXT");
    static const blob = SqliteType._("BLOB");
    static const nul = SqliteType._("NULL");
}