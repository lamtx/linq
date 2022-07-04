import "annotation.dart";
import "filterable.dart";
import "selectable.dart";

abstract class Context {
  Filterable<T> from<T extends Selectable>(T source);

  @overridableExtension
  Filterable<T> query<T extends Selectable>(T source);

  String? alias(Selectable source);

  static const Context empty = _EmptyContext();
}

class _EmptyContext implements Context {
  const _EmptyContext();

  @override
  String? alias(Selectable source) => null;

  @override
  Filterable<T> from<T extends Selectable>(T source) =>
      Filterable(source, const []);

  @override
  Filterable<T> query<T extends Selectable>(T source) =>
      Filterable(source, const []);
}
