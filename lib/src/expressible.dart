import "context.dart";

abstract interface class Expressible {
  String clause(Context context);

  List<Object?> args();
}
