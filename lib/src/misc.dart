extension IterableExt<T> on Iterable<T> {
  String joinToString([
    String separator = ", ",
    String Function(T e) transform,
  ]) {
    final iterator = this.iterator;
    transform ??= (e) => e.toString();
    if (!iterator.moveNext()) {
      return "";
    }
    final buffer = StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.write(transform(iterator.current));
      } while (iterator.moveNext());
    } else {
      buffer.write(transform(iterator.current));
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write(transform(iterator.current));
      }
    }
    return buffer.toString();
  }
}
