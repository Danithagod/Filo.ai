import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'package:semantic_butler_server/src/generated/endpoints.dart';

void main(List<String> args) async {
  print('Testing database connectivity...');
  final pod = Serverpod(args, Protocol(), Endpoints());
  final session = await pod.createSession();
  try {
    print('Querying serverpod_migrations...');
    final result = await session.db.unsafeQuery(
      'SELECT * FROM serverpod_migrations',
    );
    for (final row in result) {
      print('Migration: $row');
    }
  } catch (e) {
    print('Migration query FAILED: $e');
  } finally {
    await session.close();
    await pod.shutdown();
  }
}
