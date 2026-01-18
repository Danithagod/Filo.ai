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
    await connection.execute('DROP TABLE IF EXISTS "saved_search_preset"');
    await connection.execute(r'''
      CREATE TABLE "saved_search_preset" (
        "id" serial PRIMARY KEY,
        "name" text NOT NULL,
        "query" text NOT NULL,
        "category" text,
        "tags" json,
        "fileTypes" json,
        "dateFrom" timestamp without time zone,
        "dateTo" timestamp without time zone,
        "minSize" integer,
        "maxSize" integer,
        "createdAt" timestamp without time zone NOT NULL,
        "usageCount" integer NOT NULL
      );
    ''');
    print('Table saved_search_preset created (or already exists)');
  } catch (e) {
    print('Error creating table: $e');
  } finally {
    await connection.close();
    print('Connection closed');
  }
}
