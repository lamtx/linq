import "dart:core";

import "package:linq/linq.dart";

class Category extends Table {
  Category() : super("Category") {
    id = long("id").primary();
    name = text("name");
  }

  late Column<int> id;
  late Column<String?> name;
}

final Category category = Category();

class Customer extends Table {
  Customer() : super("Customer") {
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

final Customer customer = Customer();

void main() {}

class C {
  C({required this.name, required this.grade, required this.vip});

  final String? name;
  final double? grade;
  final bool? vip;

  @override
  String toString() => "(name: $name, grade: $grade, vip: $vip)";
}
