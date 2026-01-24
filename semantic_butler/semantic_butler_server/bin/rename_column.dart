import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'package:semantic_butler_server/src/generated/endpoints.dart';

void main(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());
  final session = await pod.createSession();
  try {
    print('Renaming embedding column...');
    await session.db.unsafeQuery(
      'ALTER TABLE document_embedding RENAME COLUMN embedding TO embedding_vector',
    );
    print('Column renamed successfully.');
  } catch (e) {
    print('Error renaming column: $e');
  } finally {
    await session.close();
  }
}
