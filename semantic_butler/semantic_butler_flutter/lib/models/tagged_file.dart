import 'dart:io';

/// Model for a file tagged in chat via @-mention
class TaggedFile {
  final String path;
  final String name;
  final bool isDirectory;
  String? content; // Loaded when sending message

  TaggedFile({
    required this.path,
    required this.name,
    this.isDirectory = false,
    this.content,
  });

  /// Get display name (just filename) - uses platform-aware path separator
  String get displayName =>
      name.isNotEmpty ? name : path.split(Platform.pathSeparator).last;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaggedFile &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
