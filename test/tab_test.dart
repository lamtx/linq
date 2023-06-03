import "dart:core";

import "package:linq/linq.dart";

final class Category extends Table {
  Category() : super("Category") {
    id = long("id").primary();
    name = text("name");
  }

  late Column<int> id;
  late Column<String?> name;
}

final Category category = Category();

class Customer {
  final int id;
  final String? name;
  final int? categoryId;
  final double? grade;
  final bool? vip;

  Customer({
    required this.id,
    this.name,
    this.categoryId,
    this.grade,
    this.vip,
  });
}

final class Customers extends Table {
  Customers() : super("Customers") {
    name = text("name");
    id = long("id").primary();
    categoryId = long("categoryId").references(category.id);
    grade = real("grade");
    vip = boolean("vip");
  }

  late Column<String?> name;
  late Column<int> id;
  late Column<int?> categoryId;
  late Column<double?> grade;
  late Column<bool?> vip;
}

final Customers customer = Customers();

void main() {
  final Customer Function(Selector<Customers> get) collector =
      (get) => Customer(
            id: get((e) => e.id),
          );
}
