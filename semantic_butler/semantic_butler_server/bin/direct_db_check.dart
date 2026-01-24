import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'ep-purple-block-ahv7qmg4-pooler.c-3.us-east-1.aws.neon.tech',
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_3mDeWLlIZS8g',
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    print('Connected to database.');

    print('\n--- Recent Migrations ---');
    final migrations = await conn.execute(
      "SELECT module, version, timestamp FROM serverpod_migrations ORDER BY timestamp DESC LIMIT 10;",
    );
    for (final row in migrations) {
      print('Module: ${row[0]}, Version: ${row[1]}, Timestamp: ${row[2]}');
    }

    print('\n--- Columns in document_embedding ---');
    final columns = await conn.execute(
      "SELECT column_name, data_type, udt_name FROM information_schema.columns WHERE table_name = 'document_embedding';",
    );
    for (final row in columns) {
      print('Column: ${row[0]}, Type: ${row[1]} (UDT: ${row[2]})');
    }

    print('\n--- Index list ---');
    final indexes = await conn.execute(
      "SELECT indexname FROM pg_indexes WHERE tablename = 'document_embedding';",
    );
    for (final row in indexes) {
      print('Index: ${row[0]}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
