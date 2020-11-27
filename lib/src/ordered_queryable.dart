import "context.dart";
import "expressible.dart";
import "queryable.dart";

class OrderedQueryable<T extends Expressible> implements Queryable<T> {
  OrderedQueryable(Queryable<T> base, List<Expressible> orderBy)
      : _orderBy = orderBy,
        _base = base;

  final Queryable<T> _base;
  final List<Expressible> _orderBy;

  @override
  List<Object?> args() => _base.args();

  @override
  String clause(Context context) {
    final sb = StringBuffer(_base.clause(context))..write(" ORDER BY ");

    var appendCommas = false;
    for (final field in _orderBy) {
      if (appendCommas) {
        sb.write(", ");
      }
      appendCommas = true;
      sb.write(field.clause(context));
    }
    return sb.toString();
  }

  @override
  T get source => _base.source;
}
