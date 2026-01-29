import 'package:semantic_butler_server/server.dart';

/// This is the starting point for your Serverpod server. Typically, there is
/// no need to modify this file.
import 'dart:io';

Future<void> main(List<String> args) async {
  try {
    await run(args);
  } catch (e, stack) {
    stderr.writeln('CRASH: $e\n$stack');
    exit(1);
  }
}
