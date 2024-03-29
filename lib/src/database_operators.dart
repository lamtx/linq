import 'package:sqlite/sqlite.dart';

import 'column.dart';
import 'debug.dart';
import 'table.dart';

extension SqlOperatorOnDatabase on Database {
  void create(Table table) {
    execute(table.createStatement());
  }

  void add(Column<void> column) {
    final statement =
        "ALTER TABLE ${column.owner} ADD COLUMN ${column.definition()}";
    assert(() {
      if (enableLog) {
        print("SQL/ALTER: $statement");
      }
      return true;
    }());
    execute(statement);
  }
}
