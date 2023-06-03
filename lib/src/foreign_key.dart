import "column.dart";
import "context.dart";
import "table.dart";

final class ForeignKey<T> {
  const ForeignKey(this.otherTable, this.otherColumn);

  final Table otherTable;
  final Column<T> otherColumn;

  String get otherTableName => otherTable.clause(Context.empty);
}
