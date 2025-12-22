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
import '../greetings/greeting_endpoint.dart' as _i5;
import 'package:semantic_butler_server/src/generated/agent_message.dart' as _i6;

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
      'greeting': _i5.GreetingEndpoint()
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
              type: _i1.getType<List<_i6.AgentMessage>?>(),
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
              type: _i1.getType<List<_i6.AgentMessage>?>(),
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
        'getSearchHistory': _i1.MethodConnector(
          name: 'getSearchHistory',
          params: {
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
              ) async =>
                  (endpoints['butler'] as _i3.ButlerEndpoint).getSearchHistory(
                    session,
                    limit: params['limit'],
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
              ) async => (endpoints['greeting'] as _i5.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
  }
}
