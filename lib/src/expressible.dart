import "context.dart";

abstract class Expressible {
    String clause(Context context);

    List<Object?> args();
}