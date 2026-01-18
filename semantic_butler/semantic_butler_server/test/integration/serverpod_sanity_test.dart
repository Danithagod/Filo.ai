import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Serverpod Sanity', (sessionBuilder, endpoints) {
    test('serverpod works', () {
      expect(endpoints, isNotNull);
    });
  });
}
