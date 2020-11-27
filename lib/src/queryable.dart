import "collectible.dart";
import "expressible.dart";
import "expression.dart";
import 'group_queryable.dart';
import "limited_queryable.dart";
import "ordered_queryable.dart";

abstract class Queryable<T> extends Expression<T> {
  T get source;
}

extension QueryableSelector<T extends Expressible> on Queryable<T> {
  Collectible<T> selectAll() => Collectible(
        source: source,
        baseSource: source,
        distinct: false,
        query: this,
      );

  Collectible<R> select<R extends Object>(R Function(T) selector) =>
      Collectible(
        source: selector(source),
        baseSource: source,
        distinct: false,
        query: this,
      );

  Collectible<T> selectOnly(List<Expressible> Function(T) selector) =>
      Collectible(
          source: source,
          baseSource: source,
          distinct: false,
          query: this,
          selections: selector(source));

  Collectible<T> selectDistinctAll() => Collectible(
        source: source,
        baseSource: source,
        distinct: true,
        query: this,
      );

  Collectible<T> selectDistinctOnly(List<Expressible> Function(T) selector) =>
      Collectible(
        source: source,
        baseSource: source,
        distinct: true,
        query: this,
        selections: selector(source),
      );

  Collectible<R> selectDistinct<R extends Object>(R Function(T) selector) =>
      Collectible(
        source: selector(source),
        baseSource: source,
        distinct: true,
        query: this,
      );

  LimitedQueryable<T> limit(int limit, int offset) =>
      LimitedQueryable(this, limit, offset);

  GroupQueryable<T, TKey> groupBy<TKey extends Object>(
          TKey Function(T) selector) =>
      GroupQueryable(this, selector(source));

  OrderedQueryable<T> orderBy(List<Expressible> Function(T) fields) =>
      OrderedQueryable<T>(this, fields(source));
}
