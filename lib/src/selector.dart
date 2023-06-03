import "named_expression.dart";

abstract interface class Selector<T> {
  R call<R>(NamedExpression<R> Function(T t) fieldName);
}
