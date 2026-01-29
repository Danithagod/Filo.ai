import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to database...');
  final connection = await Connection.open(
    Endpoint(
      host: 'ep-purple-block-ahv7qmg4-pooler.c-3.us-east-1.aws.neon.tech',
      port: 5432,
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_3mDeWLlIZS8g',
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    print('Checking indexes on file_index...');
    final result = await connection.execute(
      "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'file_index'",
    );

    bool foundFilename = false;
    bool foundContent = false;

    for (final row in result) {
      final name = row[0] as String;
      final def = row[1] as String;
      print('Found index: $name -> $def');

      if (name == 'idx_file_index_filename_trgm') foundFilename = true;
      if (name == 'idx_file_index_content_preview_trgm') foundContent = true;
    }

    if (foundFilename && foundContent) {
      print('SUCCESS: All required indexes exist.');
    } else {
      print('FAILURE: Missing indexes.');
      if (!foundFilename) print(' - Missing: idx_file_index_filename_trgm');
      if (!foundContent) {
        print(' - Missing: idx_file_index_content_preview_trgm');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
