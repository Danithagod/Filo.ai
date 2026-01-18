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
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/agent_endpoint.dart' as _i2;
import '../endpoints/butler_endpoint.dart' as _i3;
import '../endpoints/file_system_endpoint.dart' as _i4;
import '../endpoints/health_endpoint.dart' as _i5;
import '../greetings/greeting_endpoint.dart' as _i6;
import 'package:semantic_butler_server/src/generated/agent_message.dart' as _i7;
import 'package:semantic_butler_server/src/generated/search_filters.dart'
    as _i8;
import 'package:semantic_butler_server/src/generated/saved_search_preset.dart'
    as _i9;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'agent': _i2.AgentEndpoint()
        ..initialize(
          server,
          'agent',
          null,
        ),
      'butler': _i3.ButlerEndpoint()
        ..initialize(
          server,
          'butler',
          null,
        ),
      'fileSystem': _i4.FileSystemEndpoint()
        ..initialize(
          server,
          'fileSystem',
          null,
        ),
      'health': _i5.HealthEndpoint()
        ..initialize(
          server,
          'health',
          null,
        ),
      'greeting': _i6.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['agent'] = _i1.EndpointConnector(
      name: 'agent',
      endpoint: endpoints['agent']!,
      methodConnectors: {
        'chat': _i1.MethodConnector(
          name: 'chat',
          params: {
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'conversationHistory': _i1.ParameterDescription(
              name: 'conversationHistory',
              type: _i1.getType<List<_i7.AgentMessage>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _i2.AgentEndpoint).chat(
                session,
                params['message'],
                conversationHistory: params['conversationHistory'],
              ),
        ),
        'streamChat': _i1.MethodStreamConnector(
          name: 'streamChat',
          params: {
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'conversationHistory': _i1.ParameterDescription(
              name: 'conversationHistory',
              type: _i1.getType<List<_i7.AgentMessage>?>(),
              nullable: true,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['agent'] as _i2.AgentEndpoint).streamChat(
                session,
                params['message'],
                conversationHistory: params['conversationHistory'],
              ),
        ),
      },
    );
    connectors['butler'] = _i1.EndpointConnector(
      name: 'butler',
      endpoint: endpoints['butler']!,
      methodConnectors: {
        'semanticSearch': _i1.MethodConnector(
          name: 'semanticSearch',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'threshold': _i1.ParameterDescription(
              name: 'threshold',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'filters': _i1.ParameterDescription(
              name: 'filters',
              type: _i1.getType<_i8.SearchFilters?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).semanticSearch(
                    session,
                    params['query'],
                    limit: params['limit'],
                    threshold: params['threshold'],
                    offset: params['offset'],
                    filters: params['filters'],
                  ),
        ),
        'getSearchSuggestions': _i1.MethodConnector(
          name: 'getSearchSuggestions',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getSearchSuggestions(
                    session,
                    params['query'],
                    limit: params['limit'],
                  ),
        ),
        'savePreset': _i1.MethodConnector(
          name: 'savePreset',
          params: {
            'preset': _i1.ParameterDescription(
              name: 'preset',
              type: _i1.getType<_i9.SavedSearchPreset>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint).savePreset(
                session,
                params['preset'],
              ),
        ),
        'getSavedPresets': _i1.MethodConnector(
          name: 'getSavedPresets',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getSavedPresets(session),
        ),
        'deletePreset': _i1.MethodConnector(
          name: 'deletePreset',
          params: {
            'presetId': _i1.ParameterDescription(
              name: 'presetId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).deletePreset(
                    session,
                    params['presetId'],
                  ),
        ),
        'startIndexing': _i1.MethodConnector(
          name: 'startIndexing',
          params: {
            'folderPath': _i1.ParameterDescription(
              name: 'folderPath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).startIndexing(
                    session,
                    params['folderPath'],
                  ),
        ),
        'getIndexingStatus': _i1.MethodConnector(
          name: 'getIndexingStatus',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getIndexingStatus(session),
        ),
        'getDatabaseStats': _i1.MethodConnector(
          name: 'getDatabaseStats',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getDatabaseStats(session),
        ),
        'getErrorStats': _i1.MethodConnector(
          name: 'getErrorStats',
          params: {
            'timeRange': _i1.ParameterDescription(
              name: 'timeRange',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'jobId': _i1.ParameterDescription(
              name: 'jobId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getErrorStats(
                    session,
                    timeRange: params['timeRange'],
                    category: params['category'],
                    jobId: params['jobId'],
                  ),
        ),
        'getSearchHistory': _i1.MethodConnector(
          name: 'getSearchHistory',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'searchType': _i1.ParameterDescription(
              name: 'searchType',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getSearchHistory(
                    session,
                    limit: params['limit'],
                    offset: params['offset'],
                    searchType: params['searchType'],
                  ),
        ),
        'deleteSearchHistoryItem': _i1.MethodConnector(
          name: 'deleteSearchHistoryItem',
          params: {
            'searchId': _i1.ParameterDescription(
              name: 'searchId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .deleteSearchHistoryItem(
                    session,
                    params['searchId'],
                  ),
        ),
        'clearSearchHistory': _i1.MethodConnector(
          name: 'clearSearchHistory',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .clearSearchHistory(session),
        ),
        'recordLocalSearch': _i1.MethodConnector(
          name: 'recordLocalSearch',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'directoryPath': _i1.ParameterDescription(
              name: 'directoryPath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'resultCount': _i1.ParameterDescription(
              name: 'resultCount',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).recordLocalSearch(
                    session,
                    params['query'],
                    params['directoryPath'],
                    params['resultCount'],
                  ),
        ),
        'getAIUsageStats': _i1.MethodConnector(
          name: 'getAIUsageStats',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getAIUsageStats(session),
        ),
        'clearIndex': _i1.MethodConnector(
          name: 'clearIndex',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint).clearIndex(
                session,
              ),
        ),
        'enableSmartIndexing': _i1.MethodConnector(
          name: 'enableSmartIndexing',
          params: {
            'folderPath': _i1.ParameterDescription(
              name: 'folderPath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .enableSmartIndexing(
                    session,
                    params['folderPath'],
                  ),
        ),
        'disableSmartIndexing': _i1.MethodConnector(
          name: 'disableSmartIndexing',
          params: {
            'folderPath': _i1.ParameterDescription(
              name: 'folderPath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .disableSmartIndexing(
                    session,
                    params['folderPath'],
                  ),
        ),
        'getWatchedFolders': _i1.MethodConnector(
          name: 'getWatchedFolders',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getWatchedFolders(session),
        ),
        'toggleSmartIndexing': _i1.MethodConnector(
          name: 'toggleSmartIndexing',
          params: {
            'folderPath': _i1.ParameterDescription(
              name: 'folderPath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .toggleSmartIndexing(
                    session,
                    params['folderPath'],
                  ),
        ),
        'addIgnorePattern': _i1.MethodConnector(
          name: 'addIgnorePattern',
          params: {
            'pattern': _i1.ParameterDescription(
              name: 'pattern',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'patternType': _i1.ParameterDescription(
              name: 'patternType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).addIgnorePattern(
                    session,
                    params['pattern'],
                    patternType: params['patternType'],
                    description: params['description'],
                  ),
        ),
        'removeIgnorePattern': _i1.MethodConnector(
          name: 'removeIgnorePattern',
          params: {
            'patternId': _i1.ParameterDescription(
              name: 'patternId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .removeIgnorePattern(
                    session,
                    params['patternId'],
                  ),
        ),
        'listIgnorePatterns': _i1.MethodConnector(
          name: 'listIgnorePatterns',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .listIgnorePatterns(session),
        ),
        'getIgnorePatternStrings': _i1.MethodConnector(
          name: 'getIgnorePatternStrings',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getIgnorePatternStrings(session),
        ),
        'removeFromIndex': _i1.MethodConnector(
          name: 'removeFromIndex',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).removeFromIndex(
                    session,
                    path: params['path'],
                    id: params['id'],
                  ),
        ),
        'removeMultipleFromIndex': _i1.MethodConnector(
          name: 'removeMultipleFromIndex',
          params: {
            'paths': _i1.ParameterDescription(
              name: 'paths',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .removeMultipleFromIndex(
                    session,
                    params['paths'],
                  ),
        ),
        'getTopTags': _i1.MethodConnector(
          name: 'getTopTags',
          params: {
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint).getTopTags(
                session,
                category: params['category'],
                limit: params['limit'],
              ),
        ),
        'searchTags': _i1.MethodConnector(
          name: 'searchTags',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint).searchTags(
                session,
                params['query'],
                category: params['category'],
                limit: params['limit'],
              ),
        ),
        'mergeTags': _i1.MethodConnector(
          name: 'mergeTags',
          params: {
            'sourceTags': _i1.ParameterDescription(
              name: 'sourceTags',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
            'targetTag': _i1.ParameterDescription(
              name: 'targetTag',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint).mergeTags(
                session,
                sourceTags: params['sourceTags'],
                targetTag: params['targetTag'],
                category: params['category'],
              ),
        ),
        'renameTag': _i1.MethodConnector(
          name: 'renameTag',
          params: {
            'oldTag': _i1.ParameterDescription(
              name: 'oldTag',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newTag': _i1.ParameterDescription(
              name: 'newTag',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint).renameTag(
                session,
                oldTag: params['oldTag'],
                newTag: params['newTag'],
                category: params['category'],
              ),
        ),
        'getRelatedTags': _i1.MethodConnector(
          name: 'getRelatedTags',
          params: {
            'tagValue': _i1.ParameterDescription(
              name: 'tagValue',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getRelatedTags(
                    session,
                    tagValue: params['tagValue'],
                    limit: params['limit'],
                  ),
        ),
        'getTagCategoryStats': _i1.MethodConnector(
          name: 'getTagCategoryStats',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getTagCategoryStats(session),
        ),
        'getAICostSummary': _i1.MethodConnector(
          name: 'getAICostSummary',
          params: {
            'startDate': _i1.ParameterDescription(
              name: 'startDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'endDate': _i1.ParameterDescription(
              name: 'endDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getAICostSummary(
                    session,
                    startDate: params['startDate'],
                    endDate: params['endDate'],
                  ),
        ),
        'checkBudget': _i1.MethodConnector(
          name: 'checkBudget',
          params: {
            'budgetLimit': _i1.ParameterDescription(
              name: 'budgetLimit',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'periodStart': _i1.ParameterDescription(
              name: 'periodStart',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'periodEnd': _i1.ParameterDescription(
              name: 'periodEnd',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).checkBudget(
                    session,
                    budgetLimit: params['budgetLimit'],
                    periodStart: params['periodStart'],
                    periodEnd: params['periodEnd'],
                  ),
        ),
        'getProjectedCosts': _i1.MethodConnector(
          name: 'getProjectedCosts',
          params: {
            'lookbackDays': _i1.ParameterDescription(
              name: 'lookbackDays',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'forecastDays': _i1.ParameterDescription(
              name: 'forecastDays',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getProjectedCosts(
                    session,
                    lookbackDays: params['lookbackDays'],
                    forecastDays: params['forecastDays'],
                  ),
        ),
        'getDailyCosts': _i1.MethodConnector(
          name: 'getDailyCosts',
          params: {
            'startDate': _i1.ParameterDescription(
              name: 'startDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'endDate': _i1.ParameterDescription(
              name: 'endDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getDailyCosts(
                    session,
                    startDate: params['startDate'],
                    endDate: params['endDate'],
                  ),
        ),
        'getCostByFeature': _i1.MethodConnector(
          name: 'getCostByFeature',
          params: {
            'startDate': _i1.ParameterDescription(
              name: 'startDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'endDate': _i1.ParameterDescription(
              name: 'endDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getCostByFeature(
                    session,
                    startDate: params['startDate'],
                    endDate: params['endDate'],
                  ),
        ),
        'getCostByModel': _i1.MethodConnector(
          name: 'getCostByModel',
          params: {
            'startDate': _i1.ParameterDescription(
              name: 'startDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'endDate': _i1.ParameterDescription(
              name: 'endDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getCostByModel(
                    session,
                    startDate: params['startDate'],
                    endDate: params['endDate'],
                  ),
        ),
        'recordAICost': _i1.MethodConnector(
          name: 'recordAICost',
          params: {
            'feature': _i1.ParameterDescription(
              name: 'feature',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'model': _i1.ParameterDescription(
              name: 'model',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'inputTokens': _i1.ParameterDescription(
              name: 'inputTokens',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'outputTokens': _i1.ParameterDescription(
              name: 'outputTokens',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'cost': _i1.ParameterDescription(
              name: 'cost',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'metadata': _i1.ParameterDescription(
              name: 'metadata',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).recordAICost(
                    session,
                    feature: params['feature'],
                    model: params['model'],
                    inputTokens: params['inputTokens'],
                    outputTokens: params['outputTokens'],
                    cost: params['cost'],
                    metadata: params['metadata'],
                  ),
        ),
        'hybridSearch': _i1.MethodConnector(
          name: 'hybridSearch',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'threshold': _i1.ParameterDescription(
              name: 'threshold',
              type: _i1.getType<double?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'semanticWeight': _i1.ParameterDescription(
              name: 'semanticWeight',
              type: _i1.getType<double?>(),
              nullable: true,
            ),
            'keywordWeight': _i1.ParameterDescription(
              name: 'keywordWeight',
              type: _i1.getType<double?>(),
              nullable: true,
            ),
            'filters': _i1.ParameterDescription(
              name: 'filters',
              type: _i1.getType<_i8.SearchFilters?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).hybridSearch(
                    session,
                    params['query'],
                    threshold: params['threshold'],
                    limit: params['limit'],
                    offset: params['offset'],
                    semanticWeight: params['semanticWeight'],
                    keywordWeight: params['keywordWeight'],
                    filters: params['filters'],
                  ),
        ),
        'getIndexHealthReport': _i1.MethodConnector(
          name: 'getIndexHealthReport',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getIndexHealthReport(session),
        ),
        'cleanupOrphanedFiles': _i1.MethodConnector(
          name: 'cleanupOrphanedFiles',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .cleanupOrphanedFiles(session),
        ),
        'refreshStaleEntries': _i1.MethodConnector(
          name: 'refreshStaleEntries',
          params: {
            'staleThresholdDays': _i1.ParameterDescription(
              name: 'staleThresholdDays',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .refreshStaleEntries(
                    session,
                    staleThresholdDays: params['staleThresholdDays'],
                  ),
        ),
        'removeDuplicates': _i1.MethodConnector(
          name: 'removeDuplicates',
          params: {
            'keepNewest': _i1.ParameterDescription(
              name: 'keepNewest',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).removeDuplicates(
                    session,
                    keepNewest: params['keepNewest'],
                  ),
        ),
        'fixMissingEmbeddings': _i1.MethodConnector(
          name: 'fixMissingEmbeddings',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .fixMissingEmbeddings(session),
        ),
        'summarizeFile': _i1.MethodConnector(
          name: 'summarizeFile',
          params: {
            'filePath': _i1.ParameterDescription(
              name: 'filePath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).summarizeFile(
                    session,
                    params['filePath'],
                  ),
        ),
        'getOrganizationSuggestions': _i1.MethodConnector(
          name: 'getOrganizationSuggestions',
          params: {
            'rootPath': _i1.ParameterDescription(
              name: 'rootPath',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .getOrganizationSuggestions(
                    session,
                    rootPath: params['rootPath'],
                  ),
        ),
        'streamIndexingProgress': _i1.MethodStreamConnector(
          name: 'streamIndexingProgress',
          params: {
            'jobId': _i1.ParameterDescription(
              name: 'jobId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['butler'] as _i3.ButlerEndpoint)
                  .streamIndexingProgress(
                    session,
                    params['jobId'],
                  ),
        ),
        'aiSearch': _i1.MethodStreamConnector(
          name: 'aiSearch',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'strategy': _i1.ParameterDescription(
              name: 'strategy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'maxResults': _i1.ParameterDescription(
              name: 'maxResults',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['butler'] as _i3.ButlerEndpoint).aiSearch(
                session,
                params['query'],
                strategy: params['strategy'],
                maxResults: params['maxResults'],
              ),
        ),
      },
    );
    connectors['fileSystem'] = _i1.EndpointConnector(
      name: 'fileSystem',
      endpoint: endpoints['fileSystem']!,
      methodConnectors: {
        'listDirectory': _i1.MethodConnector(
          name: 'listDirectory',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['fileSystem'] as _i4.FileSystemEndpoint)
                  .listDirectory(
                    session,
                    params['path'],
                  ),
        ),
        'getDrives': _i1.MethodConnector(
          name: 'getDrives',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['fileSystem'] as _i4.FileSystemEndpoint)
                  .getDrives(session),
        ),
        'rename': _i1.MethodConnector(
          name: 'rename',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newName': _i1.ParameterDescription(
              name: 'newName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'isDirectory': _i1.ParameterDescription(
              name: 'isDirectory',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['fileSystem'] as _i4.FileSystemEndpoint).rename(
                    session,
                    params['path'],
                    params['newName'],
                    params['isDirectory'],
                  ),
        ),
        'move': _i1.MethodConnector(
          name: 'move',
          params: {
            'sourcePath': _i1.ParameterDescription(
              name: 'sourcePath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'destFolder': _i1.ParameterDescription(
              name: 'destFolder',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['fileSystem'] as _i4.FileSystemEndpoint).move(
                    session,
                    params['sourcePath'],
                    params['destFolder'],
                  ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['fileSystem'] as _i4.FileSystemEndpoint).delete(
                    session,
                    params['path'],
                  ),
        ),
        'createFolder': _i1.MethodConnector(
          name: 'createFolder',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['fileSystem'] as _i4.FileSystemEndpoint)
                  .createFolder(
                    session,
                    params['path'],
                  ),
        ),
      },
    );
    connectors['health'] = _i1.EndpointConnector(
      name: 'health',
      endpoint: endpoints['health']!,
      methodConnectors: {
        'check': _i1.MethodConnector(
          name: 'check',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i5.HealthEndpoint).check(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i6.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
  }
}
