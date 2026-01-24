import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/lock_service.dart';
import 'package:serverpod_test/serverpod_test.dart' as serverpod_test;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('LockService Integration Tests', (sessionBuilder, endpoints) {
    group('LockService concurrency', () {
      test(
        'when acquiring lock from different sessions then second fails',
        () async {
          final session1 =
              (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                  .internalBuild(endpoint: 'butler', method: 'startIndexing');
          final session2 =
              (sessionBuilder)
                  .internalBuild(endpoint: 'butler', method: 'startIndexing');
          final resourceId = 'test_resource_1';

          // 1. Acquire lock with session 1
          final locked1 = await LockService.tryAcquireLock(
            session1,
            resourceId,
          );
          expect(locked1, isTrue, reason: 'First session should acquire lock');

          // 2. Try to acquire same lock with session 2
          final locked2 = await LockService.tryAcquireLock(
            session2,
            resourceId,
          );
          expect(
            locked2,
            isFalse,
            reason: 'Second session should NOT acquire lock',
          );

          // 3. Release lock 1
          await LockService.releaseLock(session1, resourceId);

          // 4. Try to acquire with session 2 again
          final locked2Retry = await LockService.tryAcquireLock(
            session2,
            resourceId,
          );
          expect(
            locked2Retry,
            isTrue,
            reason: 'Second session should acquire lock after release',
          );

          // Cleanup
          await LockService.releaseLock(session2, resourceId);
          await session1.close();
          await session2.close();
        },
      );

      test('when checking isLocked then returns correct status', () async {
        final session1 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final session2 =
            (sessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final resourceId = 'test_resource_2';

        // Initially not locked
        expect(await LockService.isLocked(session1, resourceId), isFalse);

        // Lock with session 1
        await LockService.tryAcquireLock(session1, resourceId);

        // Check with session 2 (should be locked)
        expect(await LockService.isLocked(session2, resourceId), isTrue);

        // Release
        await LockService.releaseLock(session1, resourceId);

        // Check again (should be unlocked)
        expect(await LockService.isLocked(session2, resourceId), isFalse);

        await session1.close();
        await session2.close();
      });

      test('withLock executes operation and releases lock', () async {
        final session =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final resourceId = 'test_resource_3';
        bool executed = false;

        final result = await LockService.withLock(
          session,
          resourceId,
          () async {
            executed = true;
            return 'success';
          },
        );

        expect(result, equals('success'));
        expect(executed, isTrue);

        // Should be released now
        expect(await LockService.isLocked(session, resourceId), isFalse);

        await session.close();
      });

      test('withLock returns null if already locked', () async {
        final session1 =
            (sessionBuilder as serverpod_test.InternalTestSessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final session2 =
            (sessionBuilder)
                .internalBuild(endpoint: 'butler', method: 'startIndexing');
        final resourceId = 'test_resource_4';

        // Lock with session 1
        await LockService.tryAcquireLock(session1, resourceId);

        // Try withLock with session 2
        bool executed = false;
        final result = await LockService.withLock(
          session2,
          resourceId,
          () async {
            executed = true;
            return 'should not return';
          },
        );

        expect(result, isNull);
        expect(executed, isFalse);

        await session1.close();
        await session2.close();
      });
    });
  });
}
