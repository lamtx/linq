base class SqlException implements Exception {
  const SqlException(this.message);

  final String message;

  @override
  String toString() => message;

  static Never noElement() {
    throw const SqlException("no element");
  }
}
