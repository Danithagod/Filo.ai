import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(
      host: 'ep-purple-block-ahv7qmg4-pooler.c-3.us-east-1.aws.neon.tech',
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_3mDeWLlIZS8g',
      port: 5432,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('Connected to database');

  try {
    final results = await connection.execute(
      "SELECT column_name FROM information_schema.columns WHERE table_name = 'saved_search_preset'",
    );
    print('Columns in saved_search_preset:');
    for (final row in results) {
      print(' - ${row[0]}');
    }

    final allTables = await connection.execute(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
    );
    print('\nAll tables:');
    for (final row in allTables) {
      if (row[0].toString().startsWith('serverpod_')) continue;
      print(' - ${row[0]}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
    print('Connection closed');
  }
}
