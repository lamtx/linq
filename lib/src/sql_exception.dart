class SqlException implements Exception {
  const SqlException(this.message);

  final String message;

  @override
  String toString() => message;

  static T noElement<T>() {
    throw const SqlException("no element");
  }
}
