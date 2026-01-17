import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/auth_service.dart';

void main() {
  group('AuthService', () {
    group('apiKeyHeader', () {
      test('uses x-api-key header', () {
        expect(AuthService.apiKeyHeader, equals('x-api-key'));
      });
    });
  });

  group('UnauthorizedException', () {
    test('stores message', () {
      final exception = UnauthorizedException('Test message');
      expect(exception.message, equals('Test message'));
    });

    test('toString includes class name', () {
      final exception = UnauthorizedException('Access denied');
      expect(exception.toString(), contains('UnauthorizedException'));
    });

    test('toString includes message', () {
      final exception = UnauthorizedException('Invalid API key');
      expect(exception.toString(), contains('Invalid API key'));
    });
  });
}
