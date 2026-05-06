import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NWGraphQL', () {
    test('detects GraphQL request from map body', () {
      final body = {
        'query': 'query GetUser { user { id } }',
        'variables': {'id': '1'},
        'operationName': 'GetUser',
      };
      expect(NWGraphQL.isGraphQLRequest(body), true);
    });

    test('detects GraphQL request from JSON string body', () {
      const body = '{"query":"query Foo { foo }","operationName":"Foo"}';
      expect(NWGraphQL.isGraphQLRequest(body), true);
    });

    test('rejects non-GraphQL maps', () {
      expect(NWGraphQL.isGraphQLRequest({'name': 'x'}), false);
      expect(NWGraphQL.isGraphQLRequest('plain text'), false);
      expect(NWGraphQL.isGraphQLRequest(null), false);
    });

    test('extracts explicit operationName', () {
      final body = {
        'query': 'query AnonName { x }',
        'operationName': 'GetUser',
      };
      expect(NWGraphQL.operationName(body), 'GetUser');
    });

    test('parses operation name from query string', () {
      final body = {'query': 'mutation UpdateProfile(\$id: ID!) { ok }'};
      expect(NWGraphQL.operationName(body), 'UpdateProfile');
    });

    test('detects operation type', () {
      expect(
        NWGraphQL.operationType({'query': 'query Foo { x }'}),
        'query',
      );
      expect(
        NWGraphQL.operationType({'query': 'mutation Bar { x }'}),
        'mutation',
      );
      expect(
        NWGraphQL.operationType({'query': 'subscription Baz { x }'}),
        'subscription',
      );
    });

    test('detects GraphQL response with errors', () {
      final body = {
        'data': null,
        'errors': [
          {'message': 'forbidden'},
        ],
      };
      expect(NWGraphQL.isGraphQLResponse(body), true);
      expect(NWGraphQL.hasErrors(body), true);
      expect(NWGraphQL.responseErrors(body)?.length, 1);
    });

    test('extracts response data', () {
      final body = {
        'data': {
          'user': {'id': '1'},
        },
      };
      expect(NWGraphQL.responseData(body), {
        'user': {'id': '1'},
      });
      expect(NWGraphQL.hasErrors(body), false);
    });

    test('rejects non-GraphQL responses', () {
      expect(
        NWGraphQL.isGraphQLResponse({'success': true, 'value': 1}),
        false,
      );
    });
  });
}
