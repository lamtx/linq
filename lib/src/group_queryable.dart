import 'collectible.dart';
import 'context.dart';
import 'expressible.dart';
import 'queryable.dart';

class Group<TSource extends Expressible, TKey> implements Expressible {
  Group(this.source, this.key);

  final TSource source;
  final TKey key;

  @override
  List<Object?> args() => source.args();

  @override
  String clause(Context context) => source.clause(context);
}

class GroupQueryable<T extends Expressible, TKey extends Object>
    implements Queryable<Group<T, TKey>> {
  GroupQueryable(Queryable<T> base, TKey key)
      : _base = base,
        _key = key ,
        _groupByClauses = collectExpressible(key);


  final Queryable<T> _base;
  final TKey _key;
  List<Expressible> _groupByClauses;

  @override
  List<Object?> args() => _base.args();

  @override
  String clause(Context context) {
    final sb = StringBuffer(_base.clause(context))..write(" GROUP BY ");
    for (var i = 0; i < _groupByClauses.length; i++) {
      if (i != 0) {
        sb.write(", ");
      }
      sb.write(_groupByClauses[i].clause(context));
    }
    return sb.toString();
  }

  @override
  Group<T, TKey> get source => Group(_base.source, _key);
}
