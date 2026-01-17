import 'dart:io';
import 'package:path/path.dart' as path;
import '../generated/protocol.dart';

/// Error types for file operations
/// Used for better error handling and UI display
abstract class FileOperationErrorType {
  static const String permissionDenied = 'permission_denied';
  static const String pathNotFound = 'path_not_found';
  static const String pathTooLong = 'path_too_long';
  static const String protectedPath = 'protected_path';
  static const String diskFull = 'disk_full';
  static const String fileInUse = 'file_in_use';
  static const String invalidCharacters = 'invalid_characters';
  static const String alreadyExists = 'already_exists';
  static const String pathTraversal = 'path_traversal';
  static const String emptyName = 'empty_name';
  static const String nullBytes = 'null_bytes';
  static const String other = 'other';
}

/// Service for performing safe file operations
///
/// Features:
/// - Path validation to prevent dangerous operations
/// - Moves deleted files to recycle bin (when possible)
/// - Returns structured results for UI display
/// - Dry-run mode for previewing operations
/// - Undo information for reversible operations
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
    '/etc',
    '/var',
  };

  /// Maximum path depth for safety
  static const int _maxPathDepth = 50;

  /// Maximum path length (Windows limit is 260, but we allow longer for extended paths)
  static const int _maxPathLength = 4096;

  /// Create an error result with type classification
  static FileOperationResult _errorResult(
    String error,
    String command, {
    String? errorType,
  }) {
    return FileOperationResult(
      success: false,
      error: error,
      command: command,
      errorType: errorType ?? FileOperationErrorType.other,
    );
  }

  /// Create a success result with undo information
  static FileOperationResult _successResult(
    String command, {
    String? newPath,
    String? output,
    bool isDryRun = false,
    String? undoOperation,
    String? undoPath,
  }) {
    return FileOperationResult(
      success: true,
      command: command,
      newPath: newPath,
      output: output,
      isDryRun: isDryRun,
      undoOperation: undoOperation,
      undoPath: undoPath,
    );
  }

  // ==========================================================================
  // UNDO OPERATIONS
  // ==========================================================================

  /// Undo a previous operation using the result's undo information
  ///
  /// [result] - The result from a successful operation with undo info
  Future<FileOperationResult> undoOperation(FileOperationResult result) async {
    if (!result.success) {
      return _errorResult(
        'Cannot undo a failed operation',
        'undo',
        errorType: FileOperationErrorType.other,
      );
    }

    if (result.undoOperation == null || result.undoPath == null) {
      return _errorResult(
        'Operation is not reversible (no undo information)',
        'undo',
        errorType: FileOperationErrorType.other,
      );
    }

    if (result.newPath == null) {
      return _errorResult(
        'Cannot undo: no current path available',
        'undo',
        errorType: FileOperationErrorType.other,
      );
    }

    switch (result.undoOperation) {
      case 'rename':
      case 'move':
        return await _undoRenameOrMove(result.newPath!, result.undoPath!);
      case 'copy':
        return await _undoCopy(result.newPath!);
      case 'create':
        return await _undoCreate(result.newPath!);
      default:
        return _errorResult(
          'Unknown undo operation: ${result.undoOperation}',
          'undo',
          errorType: FileOperationErrorType.other,
        );
    }
  }

  /// Undo a rename or move by moving back to original location
  Future<FileOperationResult> _undoRenameOrMove(
    String currentPath,
    String originalPath,
  ) async {
    final command = 'undo: move "$currentPath" back to "$originalPath"';

    try {
      final entity = await _getFileSystemEntity(currentPath);
      if (entity == null) {
        return _errorResult(
          'File or folder not found at current location: $currentPath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      // Check if original location is available
      if (await File(originalPath).exists() ||
          await Directory(originalPath).exists()) {
        return _errorResult(
          'Cannot undo: something already exists at original location',
          command,
          errorType: FileOperationErrorType.alreadyExists,
        );
      }

      // Move back
      if (entity is File) {
        await entity.rename(originalPath);
      } else if (entity is Directory) {
        await entity.rename(originalPath);
      }

      return _successResult(
        command,
        newPath: originalPath,
        undoOperation: 'rename',
        undoPath: currentPath, // Can undo the undo!
      );
    } catch (e) {
      return _errorResult(
        'Failed to undo: $e',
        command,
      );
    }
  }

  /// Undo a copy by deleting the copied file
  Future<FileOperationResult> _undoCopy(String copiedPath) async {
    final command = 'undo copy: delete "$copiedPath"';

    try {
      final file = File(copiedPath);
      if (!await file.exists()) {
        return _errorResult(
          'Copied file not found: $copiedPath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      await file.delete();

      return _successResult(command, output: 'Deleted copied file');
    } catch (e) {
      return _errorResult(
        'Failed to undo copy: $e',
        command,
      );
    }
  }

  /// Undo a create by deleting the created file/folder
  Future<FileOperationResult> _undoCreate(String createdPath) async {
    final command = 'undo create: delete "$createdPath"';

    try {
      final entity = await _getFileSystemEntity(createdPath);
      if (entity == null) {
        return _errorResult(
          'Created file/folder not found: $createdPath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }

      return _successResult(command, output: 'Deleted created item');
    } catch (e) {
      return _errorResult(
        'Failed to undo create: $e',
        command,
      );
    }
  }

  /// Get the FileSystemEntity for a path (file or directory)
  static Future<FileSystemEntity?> _getFileSystemEntity(String filePath) async {
    final resolvedPath = resolvePath(filePath);
    final file = File(resolvedPath);
    if (await file.exists()) return file;

    final dir = Directory(resolvedPath);
    if (await dir.exists()) return dir;

    return null;
  }

  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  /// Resolve a path, expanding ~ to the user's home directory
  static String resolvePath(String filePath) {
    if (filePath.startsWith('~/') ||
        filePath.startsWith('~\\') ||
        filePath == '~') {
      final home = _getHomeDirectory();
      if (home != null) {
        if (filePath == '~') return home;
        return path.join(home, filePath.substring(2));
      }
    }
    return filePath;
  }

  /// Get the user's home directory
  static String? _getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'];
    } else {
      return Platform.environment['HOME'];
    }
  }

  /// Escape a path for safe use in PowerShell single-quoted strings
  /// Prevents command injection by doubling single quotes and blocking other dangerous patterns
  static String _escapePowerShellPath(String inputPath) {
    // Check for dangerous PowerShell-specific characters/patterns
    final dangerousPatterns = [
      '\x00', // Null byte
      '\$(',  // Command substitution
      '`',    // Backtick (escape character in PowerShell)
      '\n',   // Newline
      '\r',   // Carriage return
    ];

    for (final pattern in dangerousPatterns) {
      if (inputPath.contains(pattern)) {
        throw ArgumentError('Path contains dangerous characters');
      }
    }

    // Escape single quotes by doubling them (PowerShell single-quoted string rule)
    return inputPath.replaceAll("'", "''");
  }

  /// Validate that a path is safe to operate on
  static FileOperationResult _validatePath(String filePath) {
    // Resolve path (expand ~)
    final resolvedPath = resolvePath(filePath);

    // Check for null bytes (can bypass path validation)
    if (resolvedPath.contains('\x00')) {
      return _errorResult(
        'Path contains null bytes',
        'validate',
        errorType: FileOperationErrorType.nullBytes,
      );
    }

    // Check for URL encoding attacks (iterative decode until stable)
    String decodedPath = resolvedPath;
    try {
      // Iteratively decode until the path stops changing
      // This catches multi-level encoding attacks (%252e%252e -> %2e%2e -> ..)
      String previousPath;
      int decodeIterations = 0;
      const maxDecodeIterations = 10; // Prevent infinite loops

      do {
        previousPath = decodedPath;
        try {
          decodedPath = Uri.decodeComponent(decodedPath);
        } catch (_) {
          // Decoding failed (e.g., invalid encoding), stop iteration
          break;
        }
        decodeIterations++;
      } while (decodedPath != previousPath && decodeIterations < maxDecodeIterations);

      // Also check for hex-encoded characters (e.g., 0x2e for '.')
      if (RegExp(r'0x[0-9a-fA-F]{2}').hasMatch(decodedPath)) {
        return _errorResult(
          'Path contains hex-encoded characters',
          'validate $resolvedPath',
          errorType: FileOperationErrorType.pathTraversal,
        );
      }

      // Check for Unicode/UTF encoding bypass attempts
      if (RegExp(r'%u[0-9a-fA-F]{4}').hasMatch(resolvedPath)) {
        return _errorResult(
          'Path contains Unicode-encoded characters',
          'validate $resolvedPath',
          errorType: FileOperationErrorType.pathTraversal,
        );
      }
    } catch (_) {
      decodedPath = resolvedPath;
    }

    // Check for path traversal patterns (before and after normalization)
    final traversalPatterns = ['..', '..\\', '../', '..%2F', '..%5C', '%2e%2e'];
    for (final pattern in traversalPatterns) {
      if (decodedPath.toLowerCase().contains(pattern.toLowerCase())) {
        return _errorResult(
          'Path traversal not allowed',
          'validate $resolvedPath',
          errorType: FileOperationErrorType.pathTraversal,
        );
      }
    }

    // Check path length
    if (resolvedPath.length > _maxPathLength) {
      return _errorResult(
        'Path too long (max $_maxPathLength characters)',
        'validate $resolvedPath',
        errorType: FileOperationErrorType.pathTooLong,
      );
    }

    // Normalize path and get canonical form
    final normalized = path.normalize(resolvedPath);

    // Verify the normalized path doesn't contain traversal (after normalization)
    if (normalized.contains('..')) {
      return _errorResult(
        'Path traversal (..) not allowed',
        'validate $resolvedPath',
        errorType: FileOperationErrorType.pathTraversal,
      );
    }

    // Check for protected paths
    for (final protected in _protectedPaths) {
      if (normalized.toLowerCase().startsWith(protected.toLowerCase())) {
        return _errorResult(
          'Cannot modify protected system path: $protected',
          'validate $resolvedPath',
          errorType: FileOperationErrorType.protectedPath,
        );
      }
    }

    // Check path depth
    final segments = path.split(normalized);
    if (segments.length > _maxPathDepth) {
      return _errorResult(
        'Path too deep (max $_maxPathDepth levels)',
        'validate $resolvedPath',
        errorType: FileOperationErrorType.pathTooLong,
      );
    }

    return _successResult('validate $resolvedPath');
  }

  /// Rename a folder
  /// Returns the new path on success
  ///
  /// [dryRun] - If true, validates but doesn't execute (for preview)
  Future<FileOperationResult> renameFolder(
    String currentPath,
    String newName, {
    bool dryRun = false,
  }) async {
    final command = 'rename "$currentPath" to "$newName"';
    final validation = _validatePath(currentPath);
    if (!validation.success) return validation;

    // Validate new name
    if (newName.isEmpty) {
      return _errorResult(
        'New name cannot be empty',
        command,
        errorType: FileOperationErrorType.emptyName,
      );
    }

    // Check for invalid characters in name
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(newName)) {
      return _errorResult(
        'Name contains invalid characters: <>:"/\\|?*',
        command,
        errorType: FileOperationErrorType.invalidCharacters,
      );
    }

    final resolvedCurrentPath = resolvePath(currentPath);
    try {
      final dir = Directory(resolvedCurrentPath);
      if (!await dir.exists()) {
        return _errorResult(
          'Folder not found: $currentPath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      // Calculate new path
      final parentDir = path.dirname(resolvedCurrentPath);
      final newPath = path.join(parentDir, newName);

      // Check if destination already exists
      if (await Directory(newPath).exists() || await File(newPath).exists()) {
        // On case-insensitive systems like Windows, renaming 'gemma' to 'GeMMa'
        // will trigger 'exists' even though it's logically the same folder.
        // We allow it if the canonical paths are identical (meaning it's the same entity).
        final isCaseOnlyRename =
            path.canonicalize(resolvedCurrentPath) ==
            path.canonicalize(newPath);

        if (!isCaseOnlyRename) {
          return _errorResult(
            'A file or folder with that name already exists',
            command,
            errorType: FileOperationErrorType.alreadyExists,
          );
        }
      }

      // Dry-run mode: return what would happen without executing
      if (dryRun) {
        return _successResult(
          command,
          newPath: newPath,
          output: 'Would rename: $currentPath -> $newPath',
          isDryRun: true,
        );
      }

      // Perform rename
      await dir.rename(newPath);

      return _successResult(
        command,
        newPath: newPath,
        undoOperation: 'rename',
        undoPath: currentPath, // Original path to restore to
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      String errorType = FileOperationErrorType.other;

      if (errorMessage.contains('permission') ||
          errorMessage.contains('access')) {
        errorType = FileOperationErrorType.permissionDenied;
      } else if (errorMessage.contains('in use') ||
          errorMessage.contains('being used')) {
        errorType = FileOperationErrorType.fileInUse;
      }

      return _errorResult(
        'Failed to rename folder: $e',
        command,
        errorType: errorType,
      );
    }
  }

  /// Move a file or folder to a different folder
  /// Returns the new path on success
  ///
  /// [dryRun] - If true, validates but doesn't execute
  Future<FileOperationResult> moveFile(
    String sourcePath,
    String destFolder, {
    bool dryRun = false,
  }) async {
    final command = 'move "$sourcePath" to "$destFolder"';
    final sourceValidation = _validatePath(sourcePath);
    if (!sourceValidation.success) return sourceValidation;

    final destValidation = _validatePath(destFolder);
    if (!destValidation.success) return destValidation;

    final resolvedSourcePath = resolvePath(sourcePath);
    final resolvedDestFolder = resolvePath(destFolder);
    try {
      final entity = await _getFileSystemEntity(resolvedSourcePath);
      if (entity == null) {
        return _errorResult(
          'File or folder not found: $sourcePath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      // Create destination folder if it doesn't exist (unless dry run)
      final destDir = Directory(resolvedDestFolder);
      if (!dryRun && !await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Calculate destination path
      final fileName = path.basename(resolvedSourcePath);
      final newPath = path.join(resolvedDestFolder, fileName);

      // Check if destination already exists
      if (await File(newPath).exists() || await Directory(newPath).exists()) {
        return _errorResult(
          'A file or folder with that name already exists at destination',
          command,
          errorType: FileOperationErrorType.alreadyExists,
        );
      }

      // Dry-run mode
      if (dryRun) {
        return _successResult(
          command,
          newPath: newPath,
          output: 'Would move: $sourcePath -> $newPath',
          isDryRun: true,
        );
      }

      // Perform move
      if (entity is File) {
        await entity.rename(newPath);
      } else if (entity is Directory) {
        await entity.rename(newPath);
      }

      return _successResult(
        command,
        newPath: newPath,
        undoOperation: 'move',
        undoPath: sourcePath,
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      String errorType = FileOperationErrorType.other;

      if (errorMessage.contains('permission') ||
          errorMessage.contains('access')) {
        errorType = FileOperationErrorType.permissionDenied;
      } else if (errorMessage.contains('in use') ||
          errorMessage.contains('being used')) {
        errorType = FileOperationErrorType.fileInUse;
      }

      return _errorResult(
        'Failed to move: $e',
        command,
        errorType: errorType,
      );
    }
  }

  /// Move a file or folder to the trash/recycle bin
  ///
  /// On Windows: Uses PowerShell to move to Recycle Bin
  /// On other platforms: Currently falls back to permanent delete
  Future<FileOperationResult> moveToTrash(
    String filePath, {
    bool dryRun = false,
  }) async {
    final resolvedPath = resolvePath(filePath);
    final command = 'trash "$filePath"';
    final validation = _validatePath(filePath);
    if (!validation.success) return validation;

    try {
      final entity = await _getFileSystemEntity(resolvedPath);
      if (entity == null) {
        return _errorResult(
          'File or folder not found: $filePath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      if (dryRun) {
        return _successResult(
          command,
          output: 'Would move to trash: $filePath',
          isDryRun: true,
        );
      }

      if (Platform.isWindows) {
        final absPath = path.absolute(resolvedPath);
        // Escape single quotes for PowerShell by doubling them
        final escapedPath = _escapePowerShellPath(absPath);
        // PowerShell command to move to recycle bin
        final psCommand =
            '''
        Add-Type -AssemblyName Microsoft.VisualBasic;
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('$escapedPath', 'OnlyErrorDialogs', 'SendToRecycleBin');
        ''';

        final result = await Process.run('powershell.exe', [
          '-Command',
          psCommand,
        ]);

        if (result.exitCode != 0) {
          return _errorResult(
            'PowerShell trash failed: ${result.stderr}',
            command,
          );
        }
      } else {
        // Fallback for other platforms (could use 'trash-cli' if available)
        await deleteFile(filePath);
        return _successResult(
          command,
          output: 'Permanently deleted (trash not supported on this platform)',
        );
      }

      return _successResult(
        command,
        output: 'Moved to trash',
      );
    } catch (e) {
      return _errorResult('Failed to move to trash: $e', command);
    }
  }

  /// Delete a file or folder permanently
  ///
  /// [dryRun] - If true, validates but doesn't execute
  Future<FileOperationResult> deleteFile(
    String filePath, {
    bool dryRun = false,
  }) async {
    final resolvedPath = resolvePath(filePath);
    final command = 'delete "$filePath"';
    final validation = _validatePath(filePath);
    if (!validation.success) return validation;

    try {
      final entity = await _getFileSystemEntity(resolvedPath);
      if (entity == null) {
        return _errorResult(
          'File or folder not found: $filePath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      // Dry-run mode
      if (dryRun) {
        return _successResult(
          command,
          output: 'Would delete: $filePath',
          isDryRun: true,
        );
      }

      // Perform delete
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }

      return _successResult(
        command,
        output: 'Permanently deleted',
      );
    } catch (e) {
      return _errorResult('Failed to delete: $e', command);
    }
  }

  Future<FileOperationResult> createFolder(
    String folderPath, {
    bool dryRun = false,
  }) async {
    final resolvedPath = resolvePath(folderPath);
    final command = 'mkdir "$folderPath"';
    final validation = _validatePath(folderPath);
    if (!validation.success) return validation;

    try {
      final dir = Directory(resolvedPath);

      if (await dir.exists()) {
        return _errorResult(
          'Folder already exists: $folderPath',
          command,
          errorType: FileOperationErrorType.alreadyExists,
        );
      }

      // Dry-run mode
      if (dryRun) {
        return _successResult(
          command,
          newPath: folderPath,
          output: 'Would create: $folderPath',
          isDryRun: true,
        );
      }

      await dir.create(recursive: true);

      return _successResult(
        command,
        newPath: folderPath,
        undoOperation: 'create',
        undoPath: folderPath,
      );
    } catch (e) {
      return _errorResult('Failed to create folder: $e', command);
    }
  }

  /// Rename a file
  ///
  /// [dryRun] - If true, validates but doesn't execute
  Future<FileOperationResult> renameFile(
    String currentPath,
    String newName, {
    bool dryRun = false,
  }) async {
    final resolvedCurrentPath = resolvePath(currentPath);
    final command = 'rename "$currentPath" to "$newName"';
    final validation = _validatePath(currentPath);
    if (!validation.success) return validation;

    // Validate new name
    if (newName.isEmpty) {
      return _errorResult(
        'New name cannot be empty',
        command,
        errorType: FileOperationErrorType.emptyName,
      );
    }

    // Check for invalid characters in name
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(newName)) {
      return _errorResult(
        'Name contains invalid characters: <>:"/\\|?*',
        command,
        errorType: FileOperationErrorType.invalidCharacters,
      );
    }

    try {
      final file = File(resolvedCurrentPath);
      if (!await file.exists()) {
        return _errorResult(
          'File not found: $currentPath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      // Calculate new path
      final parentDir = path.dirname(resolvedCurrentPath);
      final newPath = path.join(parentDir, newName);

      // Check if destination already exists
      if (await File(newPath).exists() || await Directory(newPath).exists()) {
        final isCaseOnlyRename =
            path.canonicalize(resolvedCurrentPath) ==
            path.canonicalize(newPath);

        if (!isCaseOnlyRename) {
          return _errorResult(
            'A file or folder with that name already exists',
            command,
            errorType: FileOperationErrorType.alreadyExists,
          );
        }
      }

      // Dry-run mode
      if (dryRun) {
        return _successResult(
          command,
          newPath: newPath,
          output: 'Would rename: $currentPath -> $newPath',
          isDryRun: true,
        );
      }

      // Perform rename
      await file.rename(newPath);

      return _successResult(
        command,
        newPath: newPath,
        undoOperation: 'rename',
        undoPath: currentPath,
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      String errorType = FileOperationErrorType.other;

      if (errorMessage.contains('permission') ||
          errorMessage.contains('access')) {
        errorType = FileOperationErrorType.permissionDenied;
      } else if (errorMessage.contains('in use') ||
          errorMessage.contains('being used')) {
        errorType = FileOperationErrorType.fileInUse;
      }

      return _errorResult(
        'Failed to rename file: $e',
        command,
        errorType: errorType,
      );
    }
  }

  /// Copy a file to a new location
  ///
  /// [dryRun] - If true, validates but doesn't execute
  Future<FileOperationResult> copyFile(
    String sourcePath,
    String destFolder, {
    bool dryRun = false,
  }) async {
    final resolvedSourcePath = resolvePath(sourcePath);
    final resolvedDestFolder = resolvePath(destFolder);
    final command = 'copy "$sourcePath" to "$destFolder"';
    final sourceValidation = _validatePath(sourcePath);
    if (!sourceValidation.success) return sourceValidation;

    final destValidation = _validatePath(destFolder);
    if (!destValidation.success) return destValidation;

    try {
      final file = File(resolvedSourcePath);
      if (!await file.exists()) {
        return _errorResult(
          'File not found: $sourcePath',
          command,
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      // Create destination folder if it doesn't exist (unless dry run)
      final destDir = Directory(resolvedDestFolder);
      if (!dryRun && !await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Calculate destination path
      final fileName = path.basename(resolvedSourcePath);
      final newPath = path.join(resolvedDestFolder, fileName);

      // Check if destination file already exists
      if (await File(newPath).exists()) {
        return _errorResult(
          'A file with that name already exists at destination',
          command,
          errorType: FileOperationErrorType.alreadyExists,
        );
      }

      // Dry-run mode
      if (dryRun) {
        return _successResult(
          command,
          newPath: newPath,
          output: 'Would copy: $sourcePath -> $newPath',
          isDryRun: true,
        );
      }

      // Copy file
      await file.copy(newPath);

      return _successResult(
        command,
        newPath: newPath,
        undoOperation: 'copy',
        undoPath: sourcePath,
      );
    } catch (e) {
      return _errorResult('Failed to copy: $e', command);
    }
  }

  /// List contents of a directory
  Future<FileOperationResult> listDirectory(String dirPath) async {
    final resolvedPath = resolvePath(dirPath);
    final validation = _validatePath(dirPath);
    if (!validation.success) return validation;

    try {
      final dir = Directory(resolvedPath);
      if (!await dir.exists()) {
        return _errorResult(
          'Directory not found: $dirPath',
          'ls "$dirPath"',
          errorType: FileOperationErrorType.pathNotFound,
        );
      }

      final items = <String>[];
      await for (final entity in dir.list()) {
        final name = path.basename(entity.path);
        final isDir = entity is Directory;
        items.add('${isDir ? "[D]" : "[F]"} $name');
      }

      return _successResult(
        'ls "$dirPath"',
        output: items.join('\n'),
      );
    } catch (e) {
      return _errorResult('Failed to list directory: $e', 'ls "$dirPath"');
    }
  }

  // ==========================================================================
  // BATCH OPERATIONS
  // ==========================================================================

  /// Execute multiple file operations as a batch
  ///
  /// [operations] - List of operations to perform
  /// [rollbackOnError] - If true, successfully completed operations are reversed if one fails
  Future<BatchFileOperationResult> batchOperations(
    List<FileOperationRequest> operations, {
    bool rollbackOnError = true,
  }) async {
    final results = <FileOperationResult>[];
    final completed = <FileOperationResult>[];

    bool batchSuccess = true;
    String? batchError;

    for (final op in operations) {
      FileOperationResult result;

      switch (op.type) {
        case FileOperationType.rename:
          result = await renameFile(op.sourcePath, op.newName!);
          break;
        case FileOperationType.move:
          result = await moveFile(op.sourcePath, op.destinationPath!);
          break;
        case FileOperationType.copy:
          result = await copyFile(op.sourcePath, op.destinationPath!);
          break;
        case FileOperationType.delete:
          result = await deleteFile(op.sourcePath);
          break;
        case FileOperationType.create:
          result = await createFolder(op.sourcePath);
          break;
        case FileOperationType.trash:
          result = await moveToTrash(op.sourcePath);
          break;
      }

      results.add(result);

      if (result.success) {
        completed.add(result);
      } else {
        batchSuccess = false;
        batchError = result.error;
        break; // Stop on first error
      }
    }

    if (!batchSuccess && rollbackOnError) {
      // Rollback completed operations in reverse order
      for (final result in completed.reversed) {
        await undoOperation(result);
      }
    }

    return BatchFileOperationResult(
      success: batchSuccess,
      error: batchError,
      results: results,
      totalCount: operations.length,
      successCount: completed.length,
      wasRolledBack: !batchSuccess && rollbackOnError,
    );
  }
}

/// Types of file operations
enum FileOperationType {
  rename,
  move,
  copy,
  delete,
  create,
  trash,
}

/// A request for a single file operation in a batch
class FileOperationRequest {
  final FileOperationType type;
  final String sourcePath;
  final String? destinationPath;
  final String? newName;

  FileOperationRequest({
    required this.type,
    required this.sourcePath,
    this.destinationPath,
    this.newName,
  });
}

/// Result of a batch of file operations
class BatchFileOperationResult {
  final bool success;
  final String? error;
  final List<FileOperationResult> results;
  final int totalCount;
  final int successCount;
  final bool wasRolledBack;

  BatchFileOperationResult({
    required this.success,
    this.error,
    required this.results,
    required this.totalCount,
    required this.successCount,
    required this.wasRolledBack,
  });
}
