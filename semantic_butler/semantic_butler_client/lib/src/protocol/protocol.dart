/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'agent_file_command.dart' as _i2;
import 'agent_message.dart' as _i3;
import 'agent_response.dart' as _i4;
import 'agent_stream_message.dart' as _i5;
import 'ai_search_progress.dart' as _i6;
import 'ai_search_result.dart' as _i7;
import 'batch_organization_request.dart' as _i8;
import 'batch_organization_result.dart' as _i9;
import 'database_stats.dart' as _i10;
import 'document_embedding.dart' as _i11;
import 'drive_info.dart' as _i12;
import 'duplicate_file.dart' as _i13;
import 'duplicate_group.dart' as _i14;
import 'error_category_count.dart' as _i15;
import 'error_stats.dart' as _i16;
import 'file_index.dart' as _i17;
import 'file_operation_result.dart' as _i18;
import 'file_system_entry.dart' as _i19;
import 'greetings/greeting.dart' as _i20;
import 'health_check.dart' as _i21;
import 'ignore_pattern.dart' as _i22;
import 'index_health_report.dart' as _i23;
import 'indexing_job.dart' as _i24;
import 'indexing_job_detail.dart' as _i25;
import 'indexing_progress.dart' as _i26;
import 'indexing_status.dart' as _i27;
import 'naming_issue.dart' as _i28;
import 'organization_action_request.dart' as _i29;
import 'organization_action_result.dart' as _i30;
import 'organization_suggestions.dart' as _i31;
import 'reset_preview.dart' as _i32;
import 'reset_result.dart' as _i33;
import 'saved_search_preset.dart' as _i34;
import 'search_filters.dart' as _i35;
import 'search_history.dart' as _i36;
import 'search_result.dart' as _i37;
import 'search_suggestion.dart' as _i38;
import 'similar_content_group.dart' as _i39;
import 'similar_file.dart' as _i40;
import 'tag_taxonomy.dart' as _i41;
import 'watched_folder.dart' as _i42;
import 'package:semantic_butler_client/src/protocol/agent_message.dart' as _i43;
import 'package:semantic_butler_client/src/protocol/search_result.dart' as _i44;
import 'package:semantic_butler_client/src/protocol/search_suggestion.dart'
    as _i45;
import 'package:semantic_butler_client/src/protocol/saved_search_preset.dart'
    as _i46;
import 'package:semantic_butler_client/src/protocol/search_history.dart'
    as _i47;
import 'package:semantic_butler_client/src/protocol/watched_folder.dart'
    as _i48;
import 'package:semantic_butler_client/src/protocol/ignore_pattern.dart'
    as _i49;
import 'package:semantic_butler_client/src/protocol/tag_taxonomy.dart' as _i50;
import 'package:semantic_butler_client/src/protocol/file_system_entry.dart'
    as _i51;
import 'package:semantic_butler_client/src/protocol/drive_info.dart' as _i52;
export 'agent_file_command.dart';
export 'agent_message.dart';
export 'agent_response.dart';
export 'agent_stream_message.dart';
export 'ai_search_progress.dart';
export 'ai_search_result.dart';
export 'batch_organization_request.dart';
export 'batch_organization_result.dart';
export 'database_stats.dart';
export 'document_embedding.dart';
export 'drive_info.dart';
export 'duplicate_file.dart';
export 'duplicate_group.dart';
export 'error_category_count.dart';
export 'error_stats.dart';
export 'file_index.dart';
export 'file_operation_result.dart';
export 'file_system_entry.dart';
export 'greetings/greeting.dart';
export 'health_check.dart';
export 'ignore_pattern.dart';
export 'index_health_report.dart';
export 'indexing_job.dart';
export 'indexing_job_detail.dart';
export 'indexing_progress.dart';
export 'indexing_status.dart';
export 'naming_issue.dart';
export 'organization_action_request.dart';
export 'organization_action_result.dart';
export 'organization_suggestions.dart';
export 'reset_preview.dart';
export 'reset_result.dart';
export 'saved_search_preset.dart';
export 'search_filters.dart';
export 'search_history.dart';
export 'search_result.dart';
export 'search_suggestion.dart';
export 'similar_content_group.dart';
export 'similar_file.dart';
export 'tag_taxonomy.dart';
export 'watched_folder.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AgentFileCommand) {
      return _i2.AgentFileCommand.fromJson(data) as T;
    }
    if (t == _i3.AgentMessage) {
      return _i3.AgentMessage.fromJson(data) as T;
    }
    if (t == _i4.AgentResponse) {
      return _i4.AgentResponse.fromJson(data) as T;
    }
    if (t == _i5.AgentStreamMessage) {
      return _i5.AgentStreamMessage.fromJson(data) as T;
    }
    if (t == _i6.AISearchProgress) {
      return _i6.AISearchProgress.fromJson(data) as T;
    }
    if (t == _i7.AISearchResult) {
      return _i7.AISearchResult.fromJson(data) as T;
    }
    if (t == _i8.BatchOrganizationRequest) {
      return _i8.BatchOrganizationRequest.fromJson(data) as T;
    }
    if (t == _i9.BatchOrganizationResult) {
      return _i9.BatchOrganizationResult.fromJson(data) as T;
    }
    if (t == _i10.DatabaseStats) {
      return _i10.DatabaseStats.fromJson(data) as T;
    }
    if (t == _i11.DocumentEmbedding) {
      return _i11.DocumentEmbedding.fromJson(data) as T;
    }
    if (t == _i12.DriveInfo) {
      return _i12.DriveInfo.fromJson(data) as T;
    }
    if (t == _i13.DuplicateFile) {
      return _i13.DuplicateFile.fromJson(data) as T;
    }
    if (t == _i14.DuplicateGroup) {
      return _i14.DuplicateGroup.fromJson(data) as T;
    }
    if (t == _i15.ErrorCategoryCount) {
      return _i15.ErrorCategoryCount.fromJson(data) as T;
    }
    if (t == _i16.ErrorStats) {
      return _i16.ErrorStats.fromJson(data) as T;
    }
    if (t == _i17.FileIndex) {
      return _i17.FileIndex.fromJson(data) as T;
    }
    if (t == _i18.FileOperationResult) {
      return _i18.FileOperationResult.fromJson(data) as T;
    }
    if (t == _i19.FileSystemEntry) {
      return _i19.FileSystemEntry.fromJson(data) as T;
    }
    if (t == _i20.Greeting) {
      return _i20.Greeting.fromJson(data) as T;
    }
    if (t == _i21.HealthCheck) {
      return _i21.HealthCheck.fromJson(data) as T;
    }
    if (t == _i22.IgnorePattern) {
      return _i22.IgnorePattern.fromJson(data) as T;
    }
    if (t == _i23.IndexHealthReport) {
      return _i23.IndexHealthReport.fromJson(data) as T;
    }
    if (t == _i24.IndexingJob) {
      return _i24.IndexingJob.fromJson(data) as T;
    }
    if (t == _i25.IndexingJobDetail) {
      return _i25.IndexingJobDetail.fromJson(data) as T;
    }
    if (t == _i26.IndexingProgress) {
      return _i26.IndexingProgress.fromJson(data) as T;
    }
    if (t == _i27.IndexingStatus) {
      return _i27.IndexingStatus.fromJson(data) as T;
    }
    if (t == _i28.NamingIssue) {
      return _i28.NamingIssue.fromJson(data) as T;
    }
    if (t == _i29.OrganizationActionRequest) {
      return _i29.OrganizationActionRequest.fromJson(data) as T;
    }
    if (t == _i30.OrganizationActionResult) {
      return _i30.OrganizationActionResult.fromJson(data) as T;
    }
    if (t == _i31.OrganizationSuggestions) {
      return _i31.OrganizationSuggestions.fromJson(data) as T;
    }
    if (t == _i32.ResetPreview) {
      return _i32.ResetPreview.fromJson(data) as T;
    }
    if (t == _i33.ResetResult) {
      return _i33.ResetResult.fromJson(data) as T;
    }
    if (t == _i34.SavedSearchPreset) {
      return _i34.SavedSearchPreset.fromJson(data) as T;
    }
    if (t == _i35.SearchFilters) {
      return _i35.SearchFilters.fromJson(data) as T;
    }
    if (t == _i36.SearchHistory) {
      return _i36.SearchHistory.fromJson(data) as T;
    }
    if (t == _i37.SearchResult) {
      return _i37.SearchResult.fromJson(data) as T;
    }
    if (t == _i38.SearchSuggestion) {
      return _i38.SearchSuggestion.fromJson(data) as T;
    }
    if (t == _i39.SimilarContentGroup) {
      return _i39.SimilarContentGroup.fromJson(data) as T;
    }
    if (t == _i40.SimilarFile) {
      return _i40.SimilarFile.fromJson(data) as T;
    }
    if (t == _i41.TagTaxonomy) {
      return _i41.TagTaxonomy.fromJson(data) as T;
    }
    if (t == _i42.WatchedFolder) {
      return _i42.WatchedFolder.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AgentFileCommand?>()) {
      return (data != null ? _i2.AgentFileCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AgentMessage?>()) {
      return (data != null ? _i3.AgentMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AgentResponse?>()) {
      return (data != null ? _i4.AgentResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AgentStreamMessage?>()) {
      return (data != null ? _i5.AgentStreamMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AISearchProgress?>()) {
      return (data != null ? _i6.AISearchProgress.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AISearchResult?>()) {
      return (data != null ? _i7.AISearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.BatchOrganizationRequest?>()) {
      return (data != null ? _i8.BatchOrganizationRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.BatchOrganizationResult?>()) {
      return (data != null ? _i9.BatchOrganizationResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.DatabaseStats?>()) {
      return (data != null ? _i10.DatabaseStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.DocumentEmbedding?>()) {
      return (data != null ? _i11.DocumentEmbedding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.DriveInfo?>()) {
      return (data != null ? _i12.DriveInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.DuplicateFile?>()) {
      return (data != null ? _i13.DuplicateFile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.DuplicateGroup?>()) {
      return (data != null ? _i14.DuplicateGroup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ErrorCategoryCount?>()) {
      return (data != null ? _i15.ErrorCategoryCount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.ErrorStats?>()) {
      return (data != null ? _i16.ErrorStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.FileIndex?>()) {
      return (data != null ? _i17.FileIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.FileOperationResult?>()) {
      return (data != null ? _i18.FileOperationResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.FileSystemEntry?>()) {
      return (data != null ? _i19.FileSystemEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.Greeting?>()) {
      return (data != null ? _i20.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.HealthCheck?>()) {
      return (data != null ? _i21.HealthCheck.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.IgnorePattern?>()) {
      return (data != null ? _i22.IgnorePattern.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.IndexHealthReport?>()) {
      return (data != null ? _i23.IndexHealthReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.IndexingJob?>()) {
      return (data != null ? _i24.IndexingJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.IndexingJobDetail?>()) {
      return (data != null ? _i25.IndexingJobDetail.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.IndexingProgress?>()) {
      return (data != null ? _i26.IndexingProgress.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.IndexingStatus?>()) {
      return (data != null ? _i27.IndexingStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.NamingIssue?>()) {
      return (data != null ? _i28.NamingIssue.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.OrganizationActionRequest?>()) {
      return (data != null
              ? _i29.OrganizationActionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i30.OrganizationActionResult?>()) {
      return (data != null
              ? _i30.OrganizationActionResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i31.OrganizationSuggestions?>()) {
      return (data != null ? _i31.OrganizationSuggestions.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.ResetPreview?>()) {
      return (data != null ? _i32.ResetPreview.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.ResetResult?>()) {
      return (data != null ? _i33.ResetResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.SavedSearchPreset?>()) {
      return (data != null ? _i34.SavedSearchPreset.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.SearchFilters?>()) {
      return (data != null ? _i35.SearchFilters.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.SearchHistory?>()) {
      return (data != null ? _i36.SearchHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.SearchResult?>()) {
      return (data != null ? _i37.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.SearchSuggestion?>()) {
      return (data != null ? _i38.SearchSuggestion.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.SimilarContentGroup?>()) {
      return (data != null ? _i39.SimilarContentGroup.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i40.SimilarFile?>()) {
      return (data != null ? _i40.SimilarFile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.TagTaxonomy?>()) {
      return (data != null ? _i41.TagTaxonomy.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.WatchedFolder?>()) {
      return (data != null ? _i42.WatchedFolder.fromJson(data) : null) as T;
    }
    if (t == List<_i7.AISearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i7.AISearchResult>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i7.AISearchResult>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i7.AISearchResult>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i29.OrganizationActionRequest>) {
      return (data as List)
              .map((e) => deserialize<_i29.OrganizationActionRequest>(e))
              .toList()
          as T;
    }
    if (t == List<_i30.OrganizationActionResult>) {
      return (data as List)
              .map((e) => deserialize<_i30.OrganizationActionResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i13.DuplicateFile>) {
      return (data as List)
              .map((e) => deserialize<_i13.DuplicateFile>(e))
              .toList()
          as T;
    }
    if (t == List<_i15.ErrorCategoryCount>) {
      return (data as List)
              .map((e) => deserialize<_i15.ErrorCategoryCount>(e))
              .toList()
          as T;
    }
    if (t == List<_i24.IndexingJob>) {
      return (data as List)
              .map((e) => deserialize<_i24.IndexingJob>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i24.IndexingJob>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i24.IndexingJob>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i18.FileOperationResult>) {
      return (data as List)
              .map((e) => deserialize<_i18.FileOperationResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.DuplicateGroup>) {
      return (data as List)
              .map((e) => deserialize<_i14.DuplicateGroup>(e))
              .toList()
          as T;
    }
    if (t == List<_i28.NamingIssue>) {
      return (data as List)
              .map((e) => deserialize<_i28.NamingIssue>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.SimilarContentGroup>) {
      return (data as List)
              .map((e) => deserialize<_i39.SimilarContentGroup>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i40.SimilarFile>) {
      return (data as List)
              .map((e) => deserialize<_i40.SimilarFile>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.AgentMessage>) {
      return (data as List)
              .map((e) => deserialize<_i43.AgentMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i43.AgentMessage>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i43.AgentMessage>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i44.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i44.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i45.SearchSuggestion>) {
      return (data as List)
              .map((e) => deserialize<_i45.SearchSuggestion>(e))
              .toList()
          as T;
    }
    if (t == List<_i46.SavedSearchPreset>) {
      return (data as List)
              .map((e) => deserialize<_i46.SavedSearchPreset>(e))
              .toList()
          as T;
    }
    if (t == List<_i47.SearchHistory>) {
      return (data as List)
              .map((e) => deserialize<_i47.SearchHistory>(e))
              .toList()
          as T;
    }
    if (t == List<_i48.WatchedFolder>) {
      return (data as List)
              .map((e) => deserialize<_i48.WatchedFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i49.IgnorePattern>) {
      return (data as List)
              .map((e) => deserialize<_i49.IgnorePattern>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i50.TagTaxonomy>) {
      return (data as List)
              .map((e) => deserialize<_i50.TagTaxonomy>(e))
              .toList()
          as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
              .map((e) => deserialize<Map<String, dynamic>>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == Map<String, double>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<double>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_i51.FileSystemEntry>) {
      return (data as List)
              .map((e) => deserialize<_i51.FileSystemEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i52.DriveInfo>) {
      return (data as List).map((e) => deserialize<_i52.DriveInfo>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AgentFileCommand => 'AgentFileCommand',
      _i3.AgentMessage => 'AgentMessage',
      _i4.AgentResponse => 'AgentResponse',
      _i5.AgentStreamMessage => 'AgentStreamMessage',
      _i6.AISearchProgress => 'AISearchProgress',
      _i7.AISearchResult => 'AISearchResult',
      _i8.BatchOrganizationRequest => 'BatchOrganizationRequest',
      _i9.BatchOrganizationResult => 'BatchOrganizationResult',
      _i10.DatabaseStats => 'DatabaseStats',
      _i11.DocumentEmbedding => 'DocumentEmbedding',
      _i12.DriveInfo => 'DriveInfo',
      _i13.DuplicateFile => 'DuplicateFile',
      _i14.DuplicateGroup => 'DuplicateGroup',
      _i15.ErrorCategoryCount => 'ErrorCategoryCount',
      _i16.ErrorStats => 'ErrorStats',
      _i17.FileIndex => 'FileIndex',
      _i18.FileOperationResult => 'FileOperationResult',
      _i19.FileSystemEntry => 'FileSystemEntry',
      _i20.Greeting => 'Greeting',
      _i21.HealthCheck => 'HealthCheck',
      _i22.IgnorePattern => 'IgnorePattern',
      _i23.IndexHealthReport => 'IndexHealthReport',
      _i24.IndexingJob => 'IndexingJob',
      _i25.IndexingJobDetail => 'IndexingJobDetail',
      _i26.IndexingProgress => 'IndexingProgress',
      _i27.IndexingStatus => 'IndexingStatus',
      _i28.NamingIssue => 'NamingIssue',
      _i29.OrganizationActionRequest => 'OrganizationActionRequest',
      _i30.OrganizationActionResult => 'OrganizationActionResult',
      _i31.OrganizationSuggestions => 'OrganizationSuggestions',
      _i32.ResetPreview => 'ResetPreview',
      _i33.ResetResult => 'ResetResult',
      _i34.SavedSearchPreset => 'SavedSearchPreset',
      _i35.SearchFilters => 'SearchFilters',
      _i36.SearchHistory => 'SearchHistory',
      _i37.SearchResult => 'SearchResult',
      _i38.SearchSuggestion => 'SearchSuggestion',
      _i39.SimilarContentGroup => 'SimilarContentGroup',
      _i40.SimilarFile => 'SimilarFile',
      _i41.TagTaxonomy => 'TagTaxonomy',
      _i42.WatchedFolder => 'WatchedFolder',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'semantic_butler.',
        '',
      );
    }

    switch (data) {
      case _i2.AgentFileCommand():
        return 'AgentFileCommand';
      case _i3.AgentMessage():
        return 'AgentMessage';
      case _i4.AgentResponse():
        return 'AgentResponse';
      case _i5.AgentStreamMessage():
        return 'AgentStreamMessage';
      case _i6.AISearchProgress():
        return 'AISearchProgress';
      case _i7.AISearchResult():
        return 'AISearchResult';
      case _i8.BatchOrganizationRequest():
        return 'BatchOrganizationRequest';
      case _i9.BatchOrganizationResult():
        return 'BatchOrganizationResult';
      case _i10.DatabaseStats():
        return 'DatabaseStats';
      case _i11.DocumentEmbedding():
        return 'DocumentEmbedding';
      case _i12.DriveInfo():
        return 'DriveInfo';
      case _i13.DuplicateFile():
        return 'DuplicateFile';
      case _i14.DuplicateGroup():
        return 'DuplicateGroup';
      case _i15.ErrorCategoryCount():
        return 'ErrorCategoryCount';
      case _i16.ErrorStats():
        return 'ErrorStats';
      case _i17.FileIndex():
        return 'FileIndex';
      case _i18.FileOperationResult():
        return 'FileOperationResult';
      case _i19.FileSystemEntry():
        return 'FileSystemEntry';
      case _i20.Greeting():
        return 'Greeting';
      case _i21.HealthCheck():
        return 'HealthCheck';
      case _i22.IgnorePattern():
        return 'IgnorePattern';
      case _i23.IndexHealthReport():
        return 'IndexHealthReport';
      case _i24.IndexingJob():
        return 'IndexingJob';
      case _i25.IndexingJobDetail():
        return 'IndexingJobDetail';
      case _i26.IndexingProgress():
        return 'IndexingProgress';
      case _i27.IndexingStatus():
        return 'IndexingStatus';
      case _i28.NamingIssue():
        return 'NamingIssue';
      case _i29.OrganizationActionRequest():
        return 'OrganizationActionRequest';
      case _i30.OrganizationActionResult():
        return 'OrganizationActionResult';
      case _i31.OrganizationSuggestions():
        return 'OrganizationSuggestions';
      case _i32.ResetPreview():
        return 'ResetPreview';
      case _i33.ResetResult():
        return 'ResetResult';
      case _i34.SavedSearchPreset():
        return 'SavedSearchPreset';
      case _i35.SearchFilters():
        return 'SearchFilters';
      case _i36.SearchHistory():
        return 'SearchHistory';
      case _i37.SearchResult():
        return 'SearchResult';
      case _i38.SearchSuggestion():
        return 'SearchSuggestion';
      case _i39.SimilarContentGroup():
        return 'SimilarContentGroup';
      case _i40.SimilarFile():
        return 'SimilarFile';
      case _i41.TagTaxonomy():
        return 'TagTaxonomy';
      case _i42.WatchedFolder():
        return 'WatchedFolder';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AgentFileCommand') {
      return deserialize<_i2.AgentFileCommand>(data['data']);
    }
    if (dataClassName == 'AgentMessage') {
      return deserialize<_i3.AgentMessage>(data['data']);
    }
    if (dataClassName == 'AgentResponse') {
      return deserialize<_i4.AgentResponse>(data['data']);
    }
    if (dataClassName == 'AgentStreamMessage') {
      return deserialize<_i5.AgentStreamMessage>(data['data']);
    }
    if (dataClassName == 'AISearchProgress') {
      return deserialize<_i6.AISearchProgress>(data['data']);
    }
    if (dataClassName == 'AISearchResult') {
      return deserialize<_i7.AISearchResult>(data['data']);
    }
    if (dataClassName == 'BatchOrganizationRequest') {
      return deserialize<_i8.BatchOrganizationRequest>(data['data']);
    }
    if (dataClassName == 'BatchOrganizationResult') {
      return deserialize<_i9.BatchOrganizationResult>(data['data']);
    }
    if (dataClassName == 'DatabaseStats') {
      return deserialize<_i10.DatabaseStats>(data['data']);
    }
    if (dataClassName == 'DocumentEmbedding') {
      return deserialize<_i11.DocumentEmbedding>(data['data']);
    }
    if (dataClassName == 'DriveInfo') {
      return deserialize<_i12.DriveInfo>(data['data']);
    }
    if (dataClassName == 'DuplicateFile') {
      return deserialize<_i13.DuplicateFile>(data['data']);
    }
    if (dataClassName == 'DuplicateGroup') {
      return deserialize<_i14.DuplicateGroup>(data['data']);
    }
    if (dataClassName == 'ErrorCategoryCount') {
      return deserialize<_i15.ErrorCategoryCount>(data['data']);
    }
    if (dataClassName == 'ErrorStats') {
      return deserialize<_i16.ErrorStats>(data['data']);
    }
    if (dataClassName == 'FileIndex') {
      return deserialize<_i17.FileIndex>(data['data']);
    }
    if (dataClassName == 'FileOperationResult') {
      return deserialize<_i18.FileOperationResult>(data['data']);
    }
    if (dataClassName == 'FileSystemEntry') {
      return deserialize<_i19.FileSystemEntry>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i20.Greeting>(data['data']);
    }
    if (dataClassName == 'HealthCheck') {
      return deserialize<_i21.HealthCheck>(data['data']);
    }
    if (dataClassName == 'IgnorePattern') {
      return deserialize<_i22.IgnorePattern>(data['data']);
    }
    if (dataClassName == 'IndexHealthReport') {
      return deserialize<_i23.IndexHealthReport>(data['data']);
    }
    if (dataClassName == 'IndexingJob') {
      return deserialize<_i24.IndexingJob>(data['data']);
    }
    if (dataClassName == 'IndexingJobDetail') {
      return deserialize<_i25.IndexingJobDetail>(data['data']);
    }
    if (dataClassName == 'IndexingProgress') {
      return deserialize<_i26.IndexingProgress>(data['data']);
    }
    if (dataClassName == 'IndexingStatus') {
      return deserialize<_i27.IndexingStatus>(data['data']);
    }
    if (dataClassName == 'NamingIssue') {
      return deserialize<_i28.NamingIssue>(data['data']);
    }
    if (dataClassName == 'OrganizationActionRequest') {
      return deserialize<_i29.OrganizationActionRequest>(data['data']);
    }
    if (dataClassName == 'OrganizationActionResult') {
      return deserialize<_i30.OrganizationActionResult>(data['data']);
    }
    if (dataClassName == 'OrganizationSuggestions') {
      return deserialize<_i31.OrganizationSuggestions>(data['data']);
    }
    if (dataClassName == 'ResetPreview') {
      return deserialize<_i32.ResetPreview>(data['data']);
    }
    if (dataClassName == 'ResetResult') {
      return deserialize<_i33.ResetResult>(data['data']);
    }
    if (dataClassName == 'SavedSearchPreset') {
      return deserialize<_i34.SavedSearchPreset>(data['data']);
    }
    if (dataClassName == 'SearchFilters') {
      return deserialize<_i35.SearchFilters>(data['data']);
    }
    if (dataClassName == 'SearchHistory') {
      return deserialize<_i36.SearchHistory>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i37.SearchResult>(data['data']);
    }
    if (dataClassName == 'SearchSuggestion') {
      return deserialize<_i38.SearchSuggestion>(data['data']);
    }
    if (dataClassName == 'SimilarContentGroup') {
      return deserialize<_i39.SimilarContentGroup>(data['data']);
    }
    if (dataClassName == 'SimilarFile') {
      return deserialize<_i40.SimilarFile>(data['data']);
    }
    if (dataClassName == 'TagTaxonomy') {
      return deserialize<_i41.TagTaxonomy>(data['data']);
    }
    if (dataClassName == 'WatchedFolder') {
      return deserialize<_i42.WatchedFolder>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
