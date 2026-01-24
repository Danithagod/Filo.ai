import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'package:semantic_butler_server/src/generated/endpoints.dart';

void main(List<String> args) async {
  final serverpod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  final session = await serverpod.createSession();
  try {
    print('Checking document_embedding schema...');
    final result = await session.db.unsafeQuery(
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'document_embedding';",
    );

    for (final row in result) {
      print('Column: ${row[0]}, Type: ${row[1]}');
    }

    print('\nChecking indexes...');
    final indexResult = await session.db.unsafeQuery(
      "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'document_embedding';",
    );
    for (final row in indexResult) {
      print('Index: ${row[0]}, Def: ${row[1]}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await session.close();
    serverpod.shutdown();
  }
}
