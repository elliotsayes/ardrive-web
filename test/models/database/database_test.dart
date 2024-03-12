import 'package:ardrive/models/database/database.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:test/test.dart';

import '../../generated_migrations/schema.dart';

void main() {
  // Initialize SchemaVerifier before all tests
  late SchemaVerifier verifier;

  setUpAll(() {
    // Initializes SchemaVerifier with GeneratedHelper from drift
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Utility function to setup database and run migration to a target version
  // It returns a Database instance for further validation in tests.
  Future<Database> migrateDatabase(
      SchemaVerifier verifier, int startVersion, int targetVersion) async {
    final connection = await verifier.startAt(startVersion);
    final db = Database(connection);
    await verifier.migrateAndValidate(db, targetVersion);
    return db;
  }

  group('Database Migration Tests', () {
    test('should successfully upgrade database schema from v17 to v20',
        () async {
      final db = await migrateDatabase(verifier, 17, 20);

      db.close();
    });

    test('should successfully upgrade database schema from v18 to v20',
        () async {
      final db = await migrateDatabase(verifier, 18, 20);

      db.close();
    });

    test('should successfully upgrade database schema from v19 to v20',
        () async {
      final db = await migrateDatabase(verifier, 19, 20);

      db.close();
    });
  });
}
