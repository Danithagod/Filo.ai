import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/file_system_service.dart';
import '../services/file_operations_service.dart';

/// Endpoint for filesystem browsing and operations
class FileSystemEndpoint extends Endpoint {
  final FileSystemService _fileSystem = FileSystemService();
  final FileOperationsService _fileOps = FileOperationsService();

  /// List contents of a directory
  Future<List<FileSystemEntry>> listDirectory(
    Session session,
    String path,
  ) async {
    return await _fileSystem.listDirectory(session, path);
  }

  /// Get available drives on the system
  Future<List<DriveInfo>> getDrives(Session session) async {
    return await _fileSystem.listDrives();
  }

  /// Rename a file or folder
  Future<FileOperationResult> rename(
    Session session,
    String path,
    String newName,
    bool isDirectory,
  ) async {
    if (isDirectory) {
      return await _fileOps.renameFolder(path, newName);
    } else {
      return await _fileOps.renameFile(path, newName);
    }
  }

  /// Move a file or folder
  Future<FileOperationResult> move(
    Session session,
    String sourcePath,
    String destFolder,
  ) async {
    return await _fileOps.moveFile(sourcePath, destFolder);
  }

  /// Delete a file or folder
  Future<FileOperationResult> delete(
    Session session,
    String path,
  ) async {
    return await _fileOps.deleteFile(path);
  }

  /// Create a new folder
  Future<FileOperationResult> createFolder(
    Session session,
    String path,
  ) async {
    return await _fileOps.createFolder(path);
  }
}
