import "collector.dart";
import "context.dart";
import "expressible.dart";
import "lack_feature_error.dart";
import "selectable.dart";
import "sql_context.dart";
import "sql_exception.dart";

abstract class Collectible<T> implements Selectable {
    factory Collectible({T source, Expressible baseSource, List<
        Expressible> selections, bool distinct, Expressible query}) =>
        _Collectible(
            source: source,
            baseSource: baseSource,
            selections: selections,
            distinct: distinct,
            query: query
        );

    T get source;
}

extension SqlOperatorOnCollectible<T> on Collectible<T> {
    List<R> collect<R>(SqlContext context,
        R Function(Collector<T>) collector) => context.collect(this, collector);

    R firstOrNull<R>(SqlContext context, R Function(Collector<T>) collector) =>
        context.firstOrNull(this, collector);

    R first<R>(SqlContext context, R Function(Collector<T>) collector) =>
        context.firstOrNull(this, collector) ?? SqlException.noElement();

    bool exists(SqlContext context) => context.exists(this);
}

class _Collectible<T> implements Collectible<T> {
    _Collectible({this.source, this.baseSource, this.distinct, this.query, List<
        Expressible> selections})
        : _allExpressible = selections ?? collectExpressible(source);

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
        final sb = StringBuffer()
            ..write("SELECT ");
        if (distinct) {
            sb.write("DISTINCT ");
        }
        sb..write(selections.map((x) => x.clause(context)).join(", ")).. write(
            " FROM (").. write(baseSource.clause(context)).. write(")");
        final whereClause = query.clause(context);
        if (whereClause.isNotEmpty) {
            sb..write(" WHERE ").. write(whereClause);
        }
        return sb.toString();
    }

    @override
    List<Object> args() {
        final typedArgs = <Object>[];
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