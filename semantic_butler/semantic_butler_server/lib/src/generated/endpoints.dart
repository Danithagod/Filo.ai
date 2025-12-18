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
import '../greetings/greeting_endpoint.dart' as _i4;
import 'package:semantic_butler_server/src/generated/agent_message.dart' as _i5;

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
      'greeting': _i4.GreetingEndpoint()
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
              type: _i1.getType<List<_i5.AgentMessage>?>(),
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
              ) async => (endpoints['greeting'] as _i4.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
  }
}
