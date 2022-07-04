import "context.dart";
import "expressible.dart";
import "expression.dart";

class BinaryOperator {
  const BinaryOperator._(String op) : _symbol = op;

  final String _symbol;

  static const equal = BinaryOperator._("=");
  static const lessThan = BinaryOperator._("<");
  static const lessThanOrEqual = BinaryOperator._("<=");
  static const greaterThan = BinaryOperator._(">");
  static const greaterThanOrEqual = BinaryOperator._(">=");
  static const notEqual = BinaryOperator._("<>");
  static const and = BinaryOperator._("AND");
  static const or = BinaryOperator._("OR");
  static const like = BinaryOperator._("LIKE");
  static const $in = BinaryOperator._("IN");
}

class BinaryExpression<T> implements Expression<T> {
  const BinaryExpression(BinaryOperator op, Expressible left, Expressible right)
      : _op = op,
        _left = left,
        _right = right;

  final BinaryOperator _op;
  final Expressible _left;
  final Expressible _right;

  @override
  List<Object?> args() {
    return [..._left.args(), ..._right.args()];
  }

  @override
  String clause(Context context) {
    return "(${_left.clause(context)})${_op._symbol}(${_right.clause(context)})";
  }
}
