import "context.dart";
import "expressible.dart";
import "queryable.dart";

class LimitedQueryable<T extends Expressible> implements Queryable<T> {
  LimitedQueryable(Queryable<T> base, int limit, int offset)
      : _base = base,
        _limit = limit,
        _offset = offset;

  final Queryable<T> _base;
  final int _limit;
  final int _offset;

  @override
  String clause(Context context) {
    return "${_base.clause(context)}  LIMIT $_limit  OFFSET $_offset";
  }

  @override
  List<Object?> args() => _base.args();

  @override
  T get source => _base.source;
}
