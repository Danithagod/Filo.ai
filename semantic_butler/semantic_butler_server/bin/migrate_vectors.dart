import 'package:semantic_butler_server/src/generated/endpoints.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

void main(List<String> args) async {
  final service = VectorMigrationService();
  await service.run(args);
}

class VectorMigrationService {
  Future<void> run(List<String> args) async {
    // Initialize Serverpod securely
    final pod = Serverpod(
      args,
      Protocol(),
      Endpoints(),
    );

    await pod.start();

    final session = await pod.createSession(enableLogging: true);
    print('Starting vector migration...');

    try {
      // 1. Create the new unmanaged table
      print('Creating document_vector_store table...');
      await session.db.unsafeQuery('''
        CREATE TABLE IF NOT EXISTS document_vector_store (
          id bigint NOT NULL REFERENCES document_embedding(id) ON DELETE CASCADE,
          embedding_vector vector(768),
          PRIMARY KEY (id)
        );
      ''');

      // 2. Create index on the new table
      print('Creating HNSW index on document_vector_store...');
      await session.db.unsafeQuery('''
        CREATE INDEX IF NOT EXISTS idx_document_vector_store_embedding 
        ON document_vector_store USING hnsw (embedding_vector vector_cosine_ops);
      ''');

      // 3. Migrate existing data
      print('Migrating existing vectors...');
      // Check if source column exists first to avoid errors if already dropped
      final checkColumn = await session.db.unsafeQuery('''
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'document_embedding' AND column_name = 'embedding_vector';
      ''');

      if (checkColumn.isNotEmpty) {
        await session.db.unsafeQuery('''
          INSERT INTO document_vector_store (id, embedding_vector)
          SELECT id, embedding_vector
          FROM document_embedding
          WHERE embedding_vector IS NOT NULL
          ON CONFLICT (id) DO UPDATE SET embedding_vector = EXCLUDED.embedding_vector;
        ''');
        print('Migrated vectors.');

        // 4. Drop the old column to fix schema mismatch
        print('Dropping embedding_vector from document_embedding...');
        await session.db.unsafeQuery('''
          ALTER TABLE document_embedding DROP COLUMN IF EXISTS embedding_vector;
        ''');
        print('Dropped embedding_vector column.');
      } else {
        print(
          'Source column embedding_vector does not exist, skipping data migration.',
        );
      }

      // 5. Cleanup old index if it exists (it likely was dropped with the column, but to be sure)
      print('Ensuring old index is gone...');
      await session.db.unsafeQuery('''
        DROP INDEX IF EXISTS idx_document_embedding_hnsw;
      ''');

      print('Migration completed successfully!');
    } catch (e, stack) {
      print('Error during migration: $e');
      print(stack);
    } finally {
      await session.close();
      await pod.shutdown();
    }
  }
}
