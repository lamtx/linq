import "dart:core";

import "package:flutter_test/flutter_test.dart";
import "package:sqlite/sqlite.dart";
import "package:linq/linq.dart";

class Category extends Table {
    Category() : super("Category") {
        id = long("id").primary();
        name = text("name");
    }

    Column<int> id;
    Column<String> name;
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

    Column<String> name;
    Column<int> id;
    Column<int> categoryId;
    Column<double> grade;
    Column<bool> vip;
}

final Customer customer = Customer();

void main() {
    test("create table", () {
        final db = Database("customers2.db");
        final context = SqlContext(db);

//        insert<Customer>(customer, db, (e) =>
//        [
//            e.name << "Lam 3",
//            e.grade << 5.2,
//            e.vip << false
//        ]);
        final l = from(customer)
            .selectAll()
            .collect(context, (e) =>
            C(
                name: e.get((e) => e.name),
                grade: e.get((e) => e.grade),
                vip: e.get((e) => e.vip),
            ));

        print(l);
    });
}

class C {
    C({this.name, this.grade, this.vip});

    final String name;
    final double grade;
    final bool vip;

    @override
    String toString() => "(name: $name, grade: $grade, vip: $vip)";
}