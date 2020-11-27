import "column.dart";
import 'table.dart';

class Setter<T> {
  Setter(this.column, this.value) {
    if (column.isNonnull && value == null) {
      throw InsertNullValueException(column);
    }
  }

  final Column<T> column;
  final T value;
}

extension ColumnOperator<T> on Column<T> {
  Setter<T> operator <<(T value) => Setter(this, value);
}
