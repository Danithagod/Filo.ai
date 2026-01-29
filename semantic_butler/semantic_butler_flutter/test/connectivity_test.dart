import 'package:test/test.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

void main() {
  test('Server Connectivity Test', () async {
    // Configure client to point to local development server
    final client = Client(
      'http://127.0.0.1:8080/',
    );

    // Just check if we can make a basic call, e.g. to get insights or health check
    // Since we don't have a dedicated "ping" endpoint exposed publicly in the protocol
    // we might just try to call a simple method or check connectivity monitor

    // Actually, Serverpod has a built-in health check on the insights server (8081)
    // but the client connects to 8080.

    // Let's try to call a simple endpoint.
    // The "butler" endpoint requires auth for most things, but let's see.
    // We can try `client.insights.logEntry` if available, or just rely on connectivity monitor.

    // Better approach: Test the server's readiness by checking if we have connectivity.
    // But this is an async stream usually.

    print('Testing connection to http://localhost:8080/ ...');

    // We can try to access the fileSystem endpoint which we know exists.
    // Even if it throws Unauthorized or Unsupported, receiving a response proves connectivity.
    try {
      // Calling getDrives() which is now Deprecated/Unsupported on server side
      // BUT, receiving the UnsupportedError PROVES we talked to the server!
      await client.fileSystem.getDrives();
      print('Connection successful! (Unexpectedly got drives)');
    } catch (e) {
      print('Connection successful! (Received response: $e)');
      // If the error is related to connection refused, then it failed.
      // If it is 'UnsupportedError' (which we implemented), then it SUCCEEDED in connecting.
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        fail('Failed to connect to server: $e');
      }
    }
  });
}
