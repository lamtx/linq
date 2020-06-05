import "context.dart";
import "expression.dart";
import "literal.dart";

class LiteralExpression<T> implements Expression<T> {
    LiteralExpression(T obj) : value = toSQLiteLiteral(obj);

    final Object value;

    @override
    List<Object> args() => [value];

    @override
    String clause(Context context) => "?";
}

extension BooleanLiteralExpression on LiteralExpression<bool> {
    bool get boolValue {
        return value == 1;
    }
}
