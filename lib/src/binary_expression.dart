import "context.dart";
import "expressible.dart";
import "expression.dart";

enum BinaryOperator {
  equal("="),
  lessThan("<"),
  lessThanOrEqual("<="),
  greaterThan(">"),
  greaterThanOrEqual(">="),
  notEqual("<>"),
  and("AND"),
  or("OR"),
  like("LIKE"),
  $in("IN"),
  $is("IS"),
  isNot("IS NOT");

  const BinaryOperator(this._symbol);

  final String _symbol;
}

final class BinaryExpression<T> implements Expression<T> {
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
