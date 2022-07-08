import "package:ext/ext.dart";

import "binary_expression.dart";
import "context.dart";
import "expressible.dart";
import "literal.dart";
import "literal_expression.dart";

abstract class Expression<T> implements Expressible {}

extension ExpressionOperator<T> on Expression<T> {
  Expression<bool> eq(T? value) => value == null
      ? _binary(BinaryOperator.$is, null)
      : _binary(BinaryOperator.equal, value);

  Expression<bool> eqOther(Expression<T> other) =>
      _binaryOther(BinaryOperator.equal, other);

  Expression<bool> ne(T? value) => value == null
      ? _binary(BinaryOperator.isNot, null)
      : _binary(BinaryOperator.notEqual, value);

  Expression<bool> neOther(Expression<T> other) =>
      _binaryOther(BinaryOperator.notEqual, other);

  Expression<bool> lt(T value) => _binary(BinaryOperator.lessThan, value);

  Expression<bool> gt(T value) => _binary(BinaryOperator.greaterThan, value);

  Expression<bool> le(T value) =>
      _binary(BinaryOperator.lessThanOrEqual, value);

  Expression<bool> ge(T value) =>
      _binary(BinaryOperator.greaterThanOrEqual, value);

  Expression<bool> $in(List<T> value) =>
      BinaryExpression(BinaryOperator.$in, this, _CollectionExpression(value));

  Expression<T> desc() => postfix("DESC");

  Expression<T> asc() => postfix("ASC");

  Expression<R> postfix<R>(String functionName) =>
      _PostfixExpression(functionName, this);

  Expression<R> func<R>(String functionName, [Object? args]) =>
      _FunctionExpression(
        functionName,
        [this, if (args != null) LiteralExpression(args)],
      );

  Expression<T> max() => func<T>("max");

  Expression<int> count() => func<int>("count");

  Expression<T> sum() => func<T>("sum");

  Expression<T> min() => func<T>("min");

  Expression<bool> _binary(BinaryOperator op, T? value) =>
      BinaryExpression(op, this, LiteralExpression(value));

  Expression<bool> _binaryOther(BinaryOperator op, Expression<T?> other) =>
      BinaryExpression(op, this, other);
}

extension BoolExpressionOperator on Expression<bool> {
  Expression<bool> or(bool value) {
    if (value) {
      return LiteralExpression(true);
    }
    return this;
  }

  Expression<bool> operator |(Expression<bool> other) {
    return _binaryOther(BinaryOperator.or, other);
  }
}

extension StringExpressionOperator on Expression<String?> {
  Expression<bool> contains(String? value) => BinaryExpression(
      BinaryOperator.like, this, _ContainExpression(LiteralExpression(value)));

  Expression<bool> endsWith(String? value) => BinaryExpression(
      BinaryOperator.like, this, _EndsWithExpression(LiteralExpression(value)));

  Expression<bool> startsWith(String? value) => BinaryExpression(
      BinaryOperator.like,
      this,
      _StartsWithExpression(LiteralExpression(value)));

  Expression<String> groupConcat(String separator) =>
      func<String>("group_concat", separator);
}

class _PostfixExpression<T> implements Expression<T> {
  _PostfixExpression(this.functionName, this.arg);

  final String functionName;
  final Expression<Object?> arg;

  @override
  List<Object?> args() => arg.args();

  @override
  String clause(Context context) => "${arg.clause(context)} $functionName";
}

class _FunctionExpression<T> implements Expression<T> {
  _FunctionExpression(this.func, this.arg) : assert(arg.isNotEmpty);

  final String func;
  final List<Expression<Object?>> arg;

  @override
  List<Object?> args() {
    if (arg.length == 1) {
      return arg.first.args();
    }
    final list = <Object?>[];
    for (final e in arg) {
      list.addAll(e.args());
    }
    return list;
  }

  @override
  String clause(Context context) {
    final params = arg.length == 1
        ? arg.first.clause(context)
        : arg.joinToString(",", (e) => e.clause(context));
    return "$func($params)";
  }
}

class _ContainExpression implements Expression<bool> {
  _ContainExpression(this.arg);

  final Expression<String?> arg;

  @override
  List<Object?> args() => arg.args();

  @override
  String clause(Context context) {
    return "'%' || ${arg.clause(context)} || '%'";
  }
}

class _EndsWithExpression implements Expression<bool> {
  _EndsWithExpression(this.arg);

  final Expression<String?> arg;

  @override
  List<Object?> args() => arg.args();

  @override
  String clause(Context context) {
    return "'%' || ${arg.clause(context)}";
  }
}

class _StartsWithExpression implements Expression<bool> {
  _StartsWithExpression(this.arg);

  final Expression<String?> arg;

  @override
  List<Object?> args() => arg.args();

  @override
  String clause(Context context) {
    return "${arg.clause(context)} || '%'";
  }
}

class _CollectionExpression implements Expressible {
  _CollectionExpression(this.items);

  final List<Object?> items;

  @override
  List<Object?> args() {
    return items.map(toSQLiteLiteral).toList();
  }

  @override
  String clause(Context context) {
    final sb = StringBuffer();
    for (final _ in items) {
      if (sb.isNotEmpty) {
        sb.write(",");
      }
      sb.write("?");
    }
    return sb.toString();
  }
}
