enum SqliteType {
  integer("INTEGER"),
  real("REAL"),
  text("TEXT"),
  blob("BLOB"),
  nul("NULL");

  const SqliteType(this.name);

  final String name;
}
