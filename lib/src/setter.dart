import "column.dart";

class Setter<T> {
    Setter(this.column, this.value);

    final Column<T> column;
    final T value;
}

extension ColumnOperator<T> on Column<T> {
    Setter<T> operator <<(T value) => Setter(this, value);
}
