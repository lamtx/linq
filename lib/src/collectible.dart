import "selector.dart";
import "context.dart";
import "expressible.dart";
import "lack_feature_error.dart";
import "selectable.dart";
import "sql_context.dart";
import "sql_exception.dart";

abstract interface class Collectible<T extends Object> implements Selectable {
  factory Collectible({
    required T source,
    required Expressible baseSource,
    required bool distinct,
    required Expressible query,
    List<Expressible>? selections,
  }) =>
      _Collectible(
          source: source,
          baseSource: baseSource,
          selections: selections,
          distinct: distinct,
          query: query);

  T get source;
}

extension SqlOperatorOnCollectible<T extends Object> on Collectible<T> {
  List<R> collect<R>(SqlContext context, R Function(Selector<T>) collector) =>
      context.collect(this, collector);

  R? firstOrNull<R>(SqlContext context, R? Function(Selector<T>) collector) =>
      context.firstOrNull(this, collector);

  R first<R>(SqlContext context, R Function(Selector<T>) collector) =>
      context.firstOrNull(this, collector) ?? SqlException.noElement();

  bool exists(SqlContext context) => context.exists(this);
}

final class _Collectible<T extends Object> implements Collectible<T> {
  _Collectible({
    required this.source,
    required this.baseSource,
    required this.distinct,
    required this.query,
    List<Expressible>? selections,
  }) : _allExpressible = selections ?? collectExpressible(source);

  @override
  final T source;
  final Expressible baseSource;
  final bool distinct;
  final Expressible query;
  final List<Expressible> _allExpressible;

  @override
  List<Expressible> allExpressible() => _allExpressible;

  @override
  String clause(Context context) {
    final selections = allExpressible();
    if (selections.isEmpty) {
      throw Exception("No selection");
    }
    final sb = StringBuffer()..write("SELECT ");
    if (distinct) {
      sb.write("DISTINCT ");
    }
    sb
      ..write(selections.map((x) => x.clause(context)).join(", "))
      ..write(" FROM (")
      ..write(baseSource.clause(context))
      ..write(")");
    final whereClause = query.clause(context);
    if (whereClause.isNotEmpty) {
      sb
        ..write(" ")
        ..write(whereClause);
    }
    return sb.toString();
  }

  @override
  List<Object?> args() {
    final typedArgs = <Object?>[];
    for (final selection in _allExpressible) {
      final selectArgs = selection.args();
      if (selectArgs.isNotEmpty) {
        typedArgs.addAll(selectArgs);
      }
    }
    final sourceArgs = baseSource.args();
    if (sourceArgs.isNotEmpty) {
      typedArgs.addAll(sourceArgs);
    }
    final queryArgs = query.args();
    if (queryArgs.isNotEmpty) {
      typedArgs.addAll(queryArgs);
    }
    return typedArgs;
  }
}

List<Expressible> collectExpressible(Object source) {
  if (source is Selectable) {
    return source.allExpressible();
  }

  if (source is Expressible) {
    return [source];
  }

  throw lacksReflection;
}
