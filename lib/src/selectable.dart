import "expressible.dart";

abstract interface class Selectable implements Expressible {
  List<Expressible> allExpressible();
}
