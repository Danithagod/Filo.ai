import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/lock_service.dart';
import 'package:serverpod_test/serverpod_test.dart' as serverpod_test;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('LockService Hardening Tests', (sessionBuilder, endpoints) {
    group('LockService (Hardened)', () {
      test('when checking isLocked then does not modify lock state', () async {
        final session1 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final session2 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');

        final resourceId = 'hardening_test_resource_1';

        // 1. Acquire lock
        await LockService.tryAcquireLock(session1, resourceId);
        expect(await LockService.isLocked(session1, resourceId), isTrue);

        // 2. Check from other session
        expect(await LockService.isLocked(session2, resourceId), isTrue);

        // 3. Release
        await LockService.releaseLock(session1, resourceId);

        // 4. Verify released
        expect(await LockService.isLocked(session2, resourceId), isFalse);

        await session1.close();
        await session2.close();
      });

      test('when timeout provided then waits for lock', () async {
        final session1 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final session2 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');

        final resourceId = 'hardening_test_resource_timeout';

        // 1. Acquire with session 1
        await LockService.tryAcquireLock(session1, resourceId);

        // 2. Try acquire with session 2 with short timeout (should fail)
        final stopwatch = Stopwatch()..start();
        final result = await LockService.tryAcquireLock(
          session2,
          resourceId,
          timeout: Duration(milliseconds: 500),
        );
        stopwatch.stop();

        expect(result, isFalse);
        expect(
          stopwatch.elapsedMilliseconds,
          greaterThanOrEqualTo(400),
        ); // allow some jitter margin

        // 3. Release session 1
        await LockService.releaseLock(session1, resourceId);

        // 4. Try acquire session 2 again (success)
        final result2 = await LockService.tryAcquireLock(session2, resourceId);
        expect(result2, isTrue);

        await session1.close();
        await session2.close();
      });

      test('withLock throws exception on failure', () async {
        final session1 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final session2 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');

        final resourceId = 'hardening_test_resource_exception';

        await LockService.tryAcquireLock(session1, resourceId);

        expect(
          () => LockService.withLock(
            session2,
            resourceId,
            () async => 'success',
            timeout: Duration(milliseconds: 100),
          ),
          throwsA(isA<LockException>()),
        );

        await session1.close();
        await session2.close();
      });
    });
  });
}
