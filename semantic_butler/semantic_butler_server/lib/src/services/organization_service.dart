import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'file_operations_service.dart';

/// Service for applying organization suggestions
/// Handles duplicate resolution, naming fixes, and similar content organization
class OrganizationService {
  final FileOperationsService _fileOps = FileOperationsService();

  /// Apply an organization action
  Future<OrganizationActionResult> applyAction(
    Session session,
    OrganizationActionRequest request,
  ) async {
    final isDryRun = request.dryRun ?? false;
    final results = <FileOperationResult>[];
    int successCount = 0;
    int failureCount = 0;
    int spaceSaved = 0;

    try {
      switch (request.actionType) {
        case 'resolve_duplicates':
          return await _resolveDuplicates(
            session,
            request,
            isDryRun,
          );

        case 'fix_naming':
          return await _fixNaming(
            session,
            request,
            isDryRun,
          );

        case 'organize_similar':
          return await _organizeSimilar(
            session,
            request,
            isDryRun,
          );

        default:
          return OrganizationActionResult(
            success: false,
            actionType: request.actionType,
            filesProcessed: 0,
            successCount: 0,
            failureCount: 0,
            spaceSavedBytes: 0,
            results: [],
            error: 'Unknown action type: ${request.actionType}',
            isDryRun: isDryRun,
          );
      }
    } catch (e, stackTrace) {
      session.log(
        'Organization action failed: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return OrganizationActionResult(
        success: false,
        actionType: request.actionType,
        filesProcessed: results.length,
        successCount: successCount,
        failureCount: failureCount,
        spaceSavedBytes: spaceSaved,
        results: results,
        error: e.toString(),
        isDryRun: isDryRun,
      );
    }
  }

  /// Resolve duplicate files by keeping one and deleting the rest
  Future<OrganizationActionResult> _resolveDuplicates(
    Session session,
    OrganizationActionRequest request,
    bool isDryRun,
  ) async {
    final results = <FileOperationResult>[];
    int successCount = 0;
    int failureCount = 0;
    int spaceSaved = 0;

    final deletePaths = request.deleteFilePaths ?? [];

    session.log(
      'Resolving duplicates: keeping ${request.keepFilePath}, deleting ${deletePaths.length} files',
      level: LogLevel.info,
    );

    // Delete duplicate files
    for (final path in deletePaths) {
      final result = await _fileOps.moveToTrash(path, dryRun: isDryRun);
      results.add(result);

      if (result.success) {
        successCount++;
        // Get file size before deletion for space calculation
        try {
          final file = File(path);
          if (file.existsSync()) {
            spaceSaved += await file.length();
          }
        } catch (_) {
          // File might already be gone
        }
      } else {
        failureCount++;
      }
    }

    final overallSuccess = failureCount == 0;

    session.log(
      'Duplicate resolution complete: $successCount succeeded, $failureCount failed, saved $spaceSaved bytes',
      level: LogLevel.info,
    );

    return OrganizationActionResult(
      success: overallSuccess,
      actionType: 'resolve_duplicates',
      filesProcessed: deletePaths.length,
      successCount: successCount,
      failureCount: failureCount,
      spaceSavedBytes: spaceSaved,
      results: results,
      error: overallSuccess ? null : 'Some files could not be deleted',
      isDryRun: isDryRun,
    );
  }

  /// Fix naming issues by renaming files
  Future<OrganizationActionResult> _fixNaming(
    Session session,
    OrganizationActionRequest request,
    bool isDryRun,
  ) async {
    final results = <FileOperationResult>[];
    int successCount = 0;
    int failureCount = 0;

    final oldPaths = request.renameOldPaths ?? [];
    final newNames = request.renameNewNames ?? [];

    session.log(
      'Fixing naming for ${oldPaths.length} files',
      level: LogLevel.info,
    );

    for (int i = 0; i < oldPaths.length && i < newNames.length; i++) {
      final oldPath = oldPaths[i];
      final newName = newNames[i];

      final result = await _fileOps.renameFile(
        oldPath,
        newName,
        dryRun: isDryRun,
      );
      results.add(result);

      if (result.success) {
        successCount++;
      } else {
        failureCount++;
      }
    }

    final overallSuccess = failureCount == 0;

    session.log(
      'Naming fixes complete: $successCount succeeded, $failureCount failed',
      level: LogLevel.info,
    );

    return OrganizationActionResult(
      success: overallSuccess,
      actionType: 'fix_naming',
      filesProcessed: oldPaths.length,
      successCount: successCount,
      failureCount: failureCount,
      spaceSavedBytes: 0,
      results: results,
      error: overallSuccess ? null : 'Some files could not be renamed',
      isDryRun: isDryRun,
    );
  }

  /// Organize similar files into a target folder
  Future<OrganizationActionResult> _organizeSimilar(
    Session session,
    OrganizationActionRequest request,
    bool isDryRun,
  ) async {
    final results = <FileOperationResult>[];
    int successCount = 0;
    int failureCount = 0;

    final filePaths = request.organizeFilePaths ?? [];
    final targetFolder = request.targetFolder;

    if (targetFolder == null || targetFolder.isEmpty) {
      return OrganizationActionResult(
        success: false,
        actionType: 'organize_similar',
        filesProcessed: 0,
        successCount: 0,
        failureCount: 0,
        spaceSavedBytes: 0,
        results: [],
        error: 'Target folder is required for organizing similar files',
        isDryRun: isDryRun,
      );
    }

    session.log(
      'Organizing ${filePaths.length} similar files to $targetFolder',
      level: LogLevel.info,
    );

    // Create target folder if it doesn't exist (unless dry run)
    if (!isDryRun) {
      final createResult = await _fileOps.createFolder(targetFolder);
      if (!createResult.success &&
          !createResult.error!.contains('already exists')) {
        return OrganizationActionResult(
          success: false,
          actionType: 'organize_similar',
          filesProcessed: 0,
          successCount: 0,
          failureCount: 0,
          spaceSavedBytes: 0,
          results: [],
          error: 'Failed to create target folder: ${createResult.error}',
          isDryRun: isDryRun,
        );
      }
    }

    // Move files to target folder
    for (final path in filePaths) {
      final result = await _fileOps.moveFile(
        path,
        targetFolder,
        dryRun: isDryRun,
      );
      results.add(result);

      if (result.success) {
        successCount++;
      } else {
        failureCount++;
      }
    }

    final overallSuccess = failureCount == 0;

    session.log(
      'Organization complete: $successCount succeeded, $failureCount failed',
      level: LogLevel.info,
    );

    return OrganizationActionResult(
      success: overallSuccess,
      actionType: 'organize_similar',
      filesProcessed: filePaths.length,
      successCount: successCount,
      failureCount: failureCount,
      spaceSavedBytes: 0,
      results: results,
      error: overallSuccess ? null : 'Some files could not be moved',
      isDryRun: isDryRun,
    );
  }

  /// Apply multiple organization actions as a batch
  Future<BatchOrganizationResult> applyBatch(
    Session session,
    BatchOrganizationRequest request,
  ) async {
    final actions = request.actions;
    final rollbackOnError = request.rollbackOnError ?? true;

    final results = <OrganizationActionResult>[];
    final completedResults = <OrganizationActionResult>[];

    int successCount = 0;
    int failureCount = 0;
    bool wasRolledBack = false;

    session.log(
      'Starting batch organization: ${actions.length} actions (rollback: $rollbackOnError)',
      level: LogLevel.info,
    );

    for (final actionRequest in actions) {
      final result = await applyAction(session, actionRequest);
      results.add(result);

      if (result.success) {
        successCount++;
        completedResults.add(result);
      } else {
        failureCount++;

        if (rollbackOnError) {
          session.log(
            'Batch failed, rolling back ${completedResults.length} completed actions',
            level: LogLevel.warning,
          );

          // Rollback completed actions
          for (final completed in completedResults.reversed) {
            await _rollbackAction(session, completed);
          }

          wasRolledBack = true;
          break;
        }
      }
    }

    final overallSuccess = failureCount == 0;

    session.log(
      'Batch complete: $successCount succeeded, $failureCount failed, rolled back: $wasRolledBack',
      level: LogLevel.info,
    );

    return BatchOrganizationResult(
      success: overallSuccess,
      totalActions: actions.length,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
      error: overallSuccess ? null : 'Batch operation had failures',
      wasRolledBack: wasRolledBack,
    );
  }

  /// Rollback a completed action using undo information
  Future<void> _rollbackAction(
    Session session,
    OrganizationActionResult action,
  ) async {
    session.log(
      'Rolling back action: ${action.actionType}',
      level: LogLevel.info,
    );

    for (final result in action.results) {
      if (result.success && result.undoOperation != null) {
        try {
          await _fileOps.undoOperation(result);
          session.log(
            'Rolled back: ${result.command}',
            level: LogLevel.debug,
          );
        } catch (e) {
          session.log(
            'Failed to rollback: ${result.command} - $e',
            level: LogLevel.warning,
          );
        }
      }
    }
  }
}
