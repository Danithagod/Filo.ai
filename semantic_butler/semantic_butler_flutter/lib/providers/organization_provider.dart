import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';

/// State for the organization operations
class OrganizationState {
  final bool isProcessing;
  final String? error;
  final OrganizationActionResult? lastResult;

  OrganizationState({
    this.isProcessing = false,
    this.error,
    this.lastResult,
  });

  OrganizationState copyWith({
    bool? isProcessing,
    String? error,
    OrganizationActionResult? lastResult,
  }) {
    return OrganizationState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// Provider for organization actions
final organizationProvider =
    NotifierProvider<OrganizationNotifier, OrganizationState>(
      OrganizationNotifier.new,
    );

class OrganizationNotifier extends Notifier<OrganizationState> {
  @override
  OrganizationState build() {
    return OrganizationState();
  }

  Client get _client => ref.read(clientProvider);

  /// Resolve duplicates
  Future<OrganizationActionResult?> resolveDuplicates({
    required String contentHash,
    required String keepFilePath,
    required List<String> deleteFilePaths,
    bool dryRun = false,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _client.butler.resolveDuplicates(
        contentHash: contentHash,
        keepFilePath: keepFilePath,
        deleteFilePaths: deleteFilePaths,
        dryRun: dryRun,
      );
      state = state.copyWith(isProcessing: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  /// Fix naming issues
  Future<OrganizationActionResult?> fixNamingIssues({
    required List<String> oldPaths,
    required List<String> newNames,
    bool dryRun = false,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _client.butler.fixNamingIssues(
        renameOldPaths: oldPaths,
        renameNewNames: newNames,
        dryRun: dryRun,
      );
      state = state.copyWith(isProcessing: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  /// Organize similar files
  Future<OrganizationActionResult?> organizeSimilarFiles({
    required List<String> filePaths,
    required String targetFolder,
    bool dryRun = false,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _client.butler.organizeSimilarFiles(
        filePaths: filePaths,
        targetFolder: targetFolder,
        dryRun: dryRun,
      );
      state = state.copyWith(isProcessing: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  /// Apply a generic organization action
  Future<OrganizationActionResult?> applyAction(
    OrganizationActionRequest request,
  ) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _client.butler.applyOrganizationAction(request);
      state = state.copyWith(isProcessing: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  /// Apply batch organization
  Future<BatchOrganizationResult?> applyBatch(
    BatchOrganizationRequest request,
  ) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _client.butler.applyBatchOrganization(request);
      state = state.copyWith(isProcessing: false);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
