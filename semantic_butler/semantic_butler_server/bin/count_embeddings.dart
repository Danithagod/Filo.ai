import 'package:semantic_butler_server/src/generated/endpoints.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

void main(List<String> args) async {
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
    authenticationHandler: null,
  );

  final session = await pod.createSession(enableLogging: false);
  try {
    print('Checking DocumentEmbedding count...');
    final count = await DocumentEmbedding.db.count(session);
    print('DocumentEmbedding count: $count');
  } catch (e) {
    print('Error counting embeddings: $e');
  } finally {
    await session.close();
    // We don't need to exit explicitly if we close session, but pod.start() wasn't called so it's fine.
  }
}
