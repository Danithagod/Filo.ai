import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for exploring the local filesystem
class FileSystemService {
  /// List contents of a directory and check if they are indexed
  Future<List<FileSystemEntry>> listDirectory(
    Session session,
    String dirPath,
  ) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      throw Exception('Directory not found: $dirPath');
    }

    final entries = <FileSystemEntry>[];

    // Get all indexed paths in this directory to avoid per-file DB queries
    Set<String> indexedPaths = {};
    try {
      final indexedEntries = await FileIndex.db.find(
        session,
        where: (t) => t.path.like('$dirPath%'),
      );
      indexedPaths = indexedEntries.map((e) => e.path).toSet();
    } catch (e, stack) {
      session.log(
        'Error querying file index: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: stack,
      );
      // Continue without index status if DB fails
    }

    try {
      await for (final entity in dir.list()) {
        try {
          final stat = await entity.stat();
          final isDirectory = entity is Directory;
          final name = path.basename(entity.path);

          entries.add(
            FileSystemEntry(
              name: name,
              path: entity.path,
              isDirectory: isDirectory,
              size: stat.size,
              modifiedAt: stat.modified,
              fileExtension: isDirectory ? null : path.extension(entity.path),
              isIndexed: indexedPaths.contains(entity.path),
            ),
          );
        } catch (e) {
          // Skip individual files specifically if we can't stat them (Access Denied etc)
          session.log(
            'Skipping file ${entity.path}: $e',
            level: LogLevel.debug,
          );
        }
      }
    } catch (e, stack) {
      session.log(
        'Error listing directory $dirPath: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stack,
      );
      rethrow; // Rethrow to let endpoint handle it, but now we have logs
    }

    // Sort: Directories first, then alphabetically
    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  /// List available drives on the system
  Future<List<DriveInfo>> listDrives() async {
    final drives = <DriveInfo>[];

    if (Platform.isWindows) {
      // Use PowerShell to get logical disks as JSON. wmic is deprecated/unreliable
      try {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-CimInstance Win32_LogicalDisk | Select-Object Name, VolumeName, Size, FreeSpace | ConvertTo-Json',
        ]);

        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          if (output.isNotEmpty) {
            // ConvertTo-Json returns a single object if only one drive, or a list if multiple.
            // We need to handle both cases.
            var data = jsonDecode(output);
            if (data is Map) {
              data = [data];
            }

            if (data is List) {
              for (final item in data) {
                final name = item['Name'] as String?;
                final volumeName = item['VolumeName'] as String?;
                final size = item['Size'] as int?;
                final freeSpace = item['FreeSpace'] as int?;

                if (name != null) {
                  drives.add(
                    DriveInfo(
                      name: volumeName != null && volumeName.isNotEmpty
                          ? '$volumeName ($name)'
                          : 'Local Disk ($name)',
                      path: '$name\\',
                      totalSpace: size,
                      availableSpace: freeSpace,
                      driveType: 'Fixed',
                    ),
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        stderr.writeln('Error listing drives: $e');
        // Fallback to at least C:\ if everything fails
        drives.add(DriveInfo(name: 'Local Disk (C:)', path: 'C:\\'));
      }
    } else {
      // Unix-like: just show root as a drive
      drives.add(DriveInfo(name: 'Root /', path: '/', driveType: 'Root'));
    }

    return drives;
  }
}
