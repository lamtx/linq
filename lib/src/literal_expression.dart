import "context.dart";
import "expression.dart";
import "literal.dart";

final class LiteralExpression<T> implements Expression<T> {
  LiteralExpression(T obj) : value = toSQLiteLiteral(obj);

  final Object? value;

  @override
  List<Object?> args() => value == null ? const [] : [value];

  @override
  String clause(Context context) => value == null ? "NULL" : "?";
}

extension BooleanLiteralExpression on LiteralExpression<bool> {
  bool get boolValue {
    return value == 1;
  }
}
