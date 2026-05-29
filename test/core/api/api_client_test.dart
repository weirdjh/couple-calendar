import 'package:calendar/core/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('sends dev user id header for local QA requests', () async {
      http.Request? capturedRequest;
      final client = ApiClient(
        baseUrl: 'http://api.test/base',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"ok":true}', 200);
        }),
      );

      final json = await client.getJson(
        '/v1/couples/couple-1/events',
        credential: ApiCredential.devUser('user-a'),
        queryParameters: {'startAt': '2026-05-01', 'endAt': '2026-06-01'},
      );

      expect(json, {'ok': true});
      expect(capturedRequest?.url.toString(), contains('/base/v1/couples/'));
      expect(capturedRequest?.url.queryParameters['startAt'], '2026-05-01');
      expect(capturedRequest?.headers['X-Dev-User-Id'], 'user-a');
      expect(capturedRequest?.headers.containsKey('Authorization'), false);
    });

    test('sends bearer token without exposing a user id header', () async {
      http.Request? capturedRequest;
      final client = ApiClient(
        baseUrl: 'http://api.test',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"id":"created"}', 201);
        }),
      );

      final json = await client.postJson(
        '/v1/couples',
        credential: ApiCredential.bearerToken('session-token'),
        body: {'partnerName': 'Partner'},
      );

      expect(json, {'id': 'created'});
      expect(capturedRequest?.headers['Authorization'], 'Bearer session-token');
      expect(capturedRequest?.headers['Content-Type'], 'application/json');
      expect(capturedRequest?.headers.containsKey('X-Dev-User-Id'), false);
      expect(capturedRequest?.body, '{"partnerName":"Partner"}');
    });

    test('returns null for empty no-content responses', () async {
      final client = ApiClient(
        baseUrl: 'http://api.test',
        client: MockClient((_) async => http.Response('', 204)),
      );

      final json = await client.deleteJson(
        '/v1/couples/current',
        credential: ApiCredential.devUser('user-a'),
      );

      expect(json, isNull);
    });

    test(
      'throws ApiException with status and body for non-2xx responses',
      () async {
        final client = ApiClient(
          baseUrl: 'http://api.test',
          client: MockClient(
            (_) async => http.Response('{"error":"forbidden"}', 403),
          ),
        );

        expect(
          () => client.getJson(
            '/v1/couples/couple-1/events',
            credential: ApiCredential.devUser('non-member'),
          ),
          throwsA(
            isA<ApiException>()
                .having((error) => error.statusCode, 'statusCode', 403)
                .having((error) => error.body, 'body', '{"error":"forbidden"}'),
          ),
        );
      },
    );
  });
}
