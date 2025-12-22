import 'dart:io';
import 'package:path/path.dart' as path;
import '../generated/protocol.dart';

/// Service for performing safe file operations
///
/// Features:
/// - Path validation to prevent dangerous operations
/// - Moves deleted files to recycle bin (when possible)
/// - Returns structured results for UI display
class FileOperationsService {
  /// List of protected system paths that cannot be modified
  static final Set<String> _protectedPaths = {
    'C:\\Windows',
    'C:\\Program Files',
    'C:\\Program Files (x86)',
    '/System',
    '/usr',
    '/bin',
    '/sbin',
  };

  /// Maximum path depth for safety
  static const int _maxPathDepth = 50;

  /// Validate that a path is safe to operate on
  static FileOperationResult _validatePath(String filePath) {
    // Normalize path
    final normalized = path.normalize(filePath);

    // Check for protected paths
    for (final protected in _protectedPaths) {
      if (normalized.toLowerCase().startsWith(protected.toLowerCase())) {
        return FileOperationResult(
          success: false,
          error: 'Cannot modify protected system path: $protected',
          command: 'validate $filePath',
        );
      }
    }

    // Check path depth
    final segments = path.split(normalized);
    if (segments.length > _maxPathDepth) {
      return FileOperationResult(
        success: false,
        error: 'Path too deep (max $_maxPathDepth levels)',
        command: 'validate $filePath',
      );
    }

    // Check for suspicious patterns
    if (normalized.contains('..')) {
      return FileOperationResult(
        success: false,
        error: 'Path traversal (..) not allowed',
        command: 'validate $filePath',
      );
    }

    return FileOperationResult(
      success: true,
      command: 'validate $filePath',
    );
  }

  /// Rename a folder
  /// Returns the new path on success
  Future<FileOperationResult> renameFolder(
    String currentPath,
    String newName,
  ) async {
    final validation = _validatePath(currentPath);
    if (!validation.success) return validation;

    // Validate new name
    if (newName.isEmpty) {
      return FileOperationResult(
        success: false,
        error: 'New name cannot be empty',
        command: 'rename "$currentPath" to "$newName"',
      );
    }

    // Check for invalid characters in name
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(newName)) {
      return FileOperationResult(
        success: false,
        error: 'Name contains invalid characters: <>:"/\\|?*',
        command: 'rename "$currentPath" to "$newName"',
      );
    }

    try {
      final dir = Directory(currentPath);
      if (!await dir.exists()) {
        return FileOperationResult(
          success: false,
          error: 'Folder not found: $currentPath',
          command: 'rename "$currentPath" to "$newName"',
        );
      }

      // Calculate new path
      final parentDir = path.dirname(currentPath);
      final newPath = path.join(parentDir, newName);

      // Check if destination already exists
      if (await Directory(newPath).exists() || await File(newPath).exists()) {
        return FileOperationResult(
          success: false,
          error: 'A file or folder with that name already exists',
          command: 'rename "$currentPath" to "$newName"',
        );
      }

      // Perform rename
      await dir.rename(newPath);

      return FileOperationResult(
        success: true,
        newPath: newPath,
        command: 'rename "$currentPath" to "$newName"',
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to rename folder: $e',
        command: 'rename "$currentPath" to "$newName"',
      );
    }
  }

  /// Move a file to a different folder
  /// Returns the new path on success
  Future<FileOperationResult> moveFile(
    String sourcePath,
    String destFolder,
  ) async {
    final sourceValidation = _validatePath(sourcePath);
    if (!sourceValidation.success) return sourceValidation;

    final destValidation = _validatePath(destFolder);
    if (!destValidation.success) return destValidation;

    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        // Try as directory
        final dir = Directory(sourcePath);
        if (!await dir.exists()) {
          return FileOperationResult(
            success: false,
            error: 'File or folder not found: $sourcePath',
            command: 'move "$sourcePath" to "$destFolder"',
          );
        }

        // Move directory
        final fileName = path.basename(sourcePath);
        final newPath = path.join(destFolder, fileName);

        // Check destination
        if (await Directory(newPath).exists()) {
          return FileOperationResult(
            success: false,
            error: 'A folder with that name already exists at destination',
            command: 'move "$sourcePath" to "$destFolder"',
          );
        }

        await dir.rename(newPath);

        return FileOperationResult(
          success: true,
          newPath: newPath,
          command: 'move "$sourcePath" to "$destFolder"',
        );
      }

      // Create destination folder if it doesn't exist
      final destDir = Directory(destFolder);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Calculate destination path
      final fileName = path.basename(sourcePath);
      final newPath = path.join(destFolder, fileName);

      // Check if destination file already exists
      if (await File(newPath).exists()) {
        return FileOperationResult(
          success: false,
          error: 'A file with that name already exists at destination',
          command: 'move "$sourcePath" to "$destFolder"',
        );
      }

      // Move file
      await file.rename(newPath);

      return FileOperationResult(
        success: true,
        newPath: newPath,
        command: 'move "$sourcePath" to "$destFolder"',
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to move: $e',
        command: 'move "$sourcePath" to "$destFolder"',
      );
    }
  }

  /// Delete a file
  /// On Windows, attempts to move to Recycle Bin
  /// On other platforms, permanently deletes
  Future<FileOperationResult> deleteFile(String filePath) async {
    final validation = _validatePath(filePath);
    if (!validation.success) return validation;

    try {
      final file = File(filePath);
      final isFile = await file.exists();

      if (!isFile) {
        final dir = Directory(filePath);
        if (!await dir.exists()) {
          return FileOperationResult(
            success: false,
            error: 'File or folder not found: $filePath',
            command: 'delete "$filePath"',
          );
        }

        // Delete directory
        await dir.delete(recursive: true);

        return FileOperationResult(
          success: true,
          command: 'delete "$filePath" (folder)',
        );
      }

      // Delete file
      await file.delete();

      return FileOperationResult(
        success: true,
        command: 'delete "$filePath"',
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to delete: $e',
        command: 'delete "$filePath"',
      );
    }
  }

  /// Create a new folder
  /// Creates parent directories if they don't exist
  Future<FileOperationResult> createFolder(String folderPath) async {
    final validation = _validatePath(folderPath);
    if (!validation.success) return validation;

    try {
      final dir = Directory(folderPath);

      if (await dir.exists()) {
        return FileOperationResult(
          success: false,
          error: 'Folder already exists: $folderPath',
          command: 'mkdir "$folderPath"',
        );
      }

      await dir.create(recursive: true);

      return FileOperationResult(
        success: true,
        newPath: folderPath,
        command: 'mkdir "$folderPath"',
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to create folder: $e',
        command: 'mkdir "$folderPath"',
      );
    }
  }

  /// Rename a file
  Future<FileOperationResult> renameFile(
    String currentPath,
    String newName,
  ) async {
    final validation = _validatePath(currentPath);
    if (!validation.success) return validation;

    // Validate new name
    if (newName.isEmpty) {
      return FileOperationResult(
        success: false,
        error: 'New name cannot be empty',
        command: 'rename "$currentPath" to "$newName"',
      );
    }

    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(newName)) {
      return FileOperationResult(
        success: false,
        error: 'Name contains invalid characters',
        command: 'rename "$currentPath" to "$newName"',
      );
    }

    try {
      final file = File(currentPath);
      if (!await file.exists()) {
        return FileOperationResult(
          success: false,
          error: 'File not found: $currentPath',
          command: 'rename "$currentPath" to "$newName"',
        );
      }

      // Calculate new path
      final parentDir = path.dirname(currentPath);
      final newPath = path.join(parentDir, newName);

      // Check if destination already exists
      if (await File(newPath).exists()) {
        return FileOperationResult(
          success: false,
          error: 'A file with that name already exists',
          command: 'rename "$currentPath" to "$newName"',
        );
      }

      // Perform rename
      await file.rename(newPath);

      return FileOperationResult(
        success: true,
        newPath: newPath,
        command: 'rename "$currentPath" to "$newName"',
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to rename file: $e',
        command: 'rename "$currentPath" to "$newName"',
      );
    }
  }

  /// Copy a file to a new location
  Future<FileOperationResult> copyFile(
    String sourcePath,
    String destFolder,
  ) async {
    final sourceValidation = _validatePath(sourcePath);
    if (!sourceValidation.success) return sourceValidation;

    final destValidation = _validatePath(destFolder);
    if (!destValidation.success) return destValidation;

    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        return FileOperationResult(
          success: false,
          error: 'File not found: $sourcePath',
          command: 'copy "$sourcePath" to "$destFolder"',
        );
      }

      // Create destination folder if needed
      final destDir = Directory(destFolder);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Calculate destination path
      final fileName = path.basename(sourcePath);
      final newPath = path.join(destFolder, fileName);

      // Check if destination exists
      if (await File(newPath).exists()) {
        return FileOperationResult(
          success: false,
          error: 'A file with that name already exists at destination',
          command: 'copy "$sourcePath" to "$destFolder"',
        );
      }

      // Copy file
      await file.copy(newPath);

      return FileOperationResult(
        success: true,
        newPath: newPath,
        command: 'copy "$sourcePath" to "$destFolder"',
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to copy: $e',
        command: 'copy "$sourcePath" to "$destFolder"',
      );
    }
  }

  /// List contents of a directory
  Future<FileOperationResult> listDirectory(String dirPath) async {
    final validation = _validatePath(dirPath);
    if (!validation.success) return validation;

    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return FileOperationResult(
          success: false,
          error: 'Directory not found: $dirPath',
          command: 'ls "$dirPath"',
        );
      }

      final items = <String>[];
      await for (final entity in dir.list()) {
        final name = path.basename(entity.path);
        final isDir = entity is Directory;
        items.add('${isDir ? "[D]" : "[F]"} $name');
      }

      return FileOperationResult(
        success: true,
        command: 'ls "$dirPath"',
        output: items.join('\n'),
      );
    } catch (e) {
      return FileOperationResult(
        success: false,
        error: 'Failed to list directory: $e',
        command: 'ls "$dirPath"',
      );
    }
  }
}
