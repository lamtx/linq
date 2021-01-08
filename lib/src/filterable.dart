import "package:sqlite/sqlite.dart";

import "context.dart";
import "expressible.dart";
import "expression.dart";
import 'literal_expression.dart';
import "named_expression.dart";
import "queryable.dart";
import "selectable.dart";
import "setter.dart";
import 'sql_context.dart';

abstract class Filterable<T extends Expressible> implements Queryable<T> {
  factory Filterable(T source,
          [List<Expression<bool>> whereClauses = const []]) =>
      _Filterable(source, whereClauses);

  Filterable<T> where(Expression<bool> Function(T source) expression);
}

Filterable<T> from<T extends Selectable>(T source) => Filterable(source);

class _Filterable<T extends Expressible> implements Filterable<T> {
  _Filterable(this.source, [this.whereClauses = const []]);

  final List<Expression<bool>> whereClauses;

  @override
  final T source;

  @override
  Filterable<T> where(Expression<bool> Function(T source) expression) {
    var predicate = expression(source);
    if (predicate is NamedExpression<bool>) {
      predicate = predicate.eq(true);
    } else if (predicate is LiteralExpression<bool>) {
      if (predicate.boolValue) {
        return this;
      }
    }
    return Filterable(source, [...whereClauses, predicate]);
  }

  @override
  String clause(Context context) {
    if (whereClauses.isEmpty) {
      return "";
    }
    var appendAnd = false;
    final sb = StringBuffer();
    sb.write("WHERE ");
    for (final clause in whereClauses) {
      if (appendAnd) {
        sb.write(" AND ");
      }
      appendAnd = true;
      sb..write("(")..write(clause.clause(context))..write(")");
    }
    return sb.toString();
  }

  @override
  List<Object?> args() {
    return [for (final exp in whereClauses) ...exp.args()];
  }
}

extension SqlOperatorOnFilterable<T extends Expressible> on Filterable<T> {
  void update(Database database, List<Setter<Object?>> Function(T) setters) =>
      SqlContext.update(this, database, setters);

  void delete(Database database) => SqlContext.delete(this, database);
}
