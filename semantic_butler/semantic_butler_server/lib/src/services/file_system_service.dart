import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../utils/cross_platform_paths.dart';
import '../utils/path_utils.dart';
import '../utils/validation.dart';
import 'file_operations_service.dart';

/// Service for exploring the local filesystem
class FileSystemService {
  /// List contents of a directory and check if they are indexed
  Future<List<FileSystemEntry>> listDirectory(
    Session session,
    String dirPath,
  ) async {
    InputValidation.validateFilePath(dirPath);
    final resolvedPath = FileOperationsService.resolvePath(dirPath);
    final dir = Directory(resolvedPath);

    if (!await dir.exists()) {
      throw Exception('Directory not found: $dirPath');
    }

    final entities = await dir.list(followLinks: false).toList();
    final entityPaths = entities.map((entity) => entity.path).toList();

    final indexedPaths = <String>{};
    if (entityPaths.isNotEmpty) {
      final indexed = await FileIndex.db.find(
        session,
        where: (t) => t.path.inSet(entityPaths.toSet()),
      );
      indexedPaths.addAll(
        indexed.map((entry) => PathUtils.normalize(entry.path)),
      );
    }

    final entries = <FileSystemEntry>[];
    for (final entity in entities) {
      try {
        final stat = await entity.stat();
        final name = p.basename(entity.path);
        final isDirectory = entity is Directory;
        final extension = isDirectory ? '' : p.extension(name);

        entries.add(
          FileSystemEntry(
            name: name,
            path: entity.path,
            isDirectory: isDirectory,
            size: isDirectory ? 0 : stat.size,
            modifiedAt: stat.modified,
            fileExtension: extension.isNotEmpty ? extension.substring(1) : null,
            isIndexed: indexedPaths.contains(PathUtils.normalize(entity.path)),
          ),
        );
      } catch (e) {
        session.log(
          'Failed to stat entry ${entity.path}: $e',
          level: LogLevel.debug,
        );
      }
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  /// List available drives on the system
  Future<List<DriveInfo>> listDrives() async {
    final rootPaths = await CrossPlatformPaths.getRootPaths();

    return rootPaths.map((path) {
      final displayName = _driveDisplayName(path);
      return DriveInfo(
        name: displayName,
        path: path,
        driveType: Platform.isWindows ? 'local' : 'mount',
      );
    }).toList();
  }

  String _driveDisplayName(String path) {
    if (Platform.isWindows) {
      final trimmed = path.replaceAll('\\', '');
      return trimmed.isEmpty ? path : trimmed;
    }
    if (path == '/') {
      return 'Root';
    }
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.where((part) => part.isNotEmpty).last;
  }
}
