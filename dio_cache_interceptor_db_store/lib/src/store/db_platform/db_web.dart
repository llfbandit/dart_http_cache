import 'package:drift/web.dart';

import '../database.dart';

DioCacheDatabase openDb({
  required String databasePath,
  required String databaseName,
  bool logStatements = false,
}) {
  return DioCacheDatabase(
    WebDatabase(databaseName, logStatements: logStatements),
  );
}
