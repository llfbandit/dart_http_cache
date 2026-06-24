import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/src/model/dio_base_request.dart';
import 'package:test/test.dart';

void main() {
  group('DioBaseRequest', () {
    test('constructor does not replace RequestOptions.headers', () {
      final options = RequestOptions(path: '/test');
      options.headers['accept'] = ['application/json', 'text/html'];
      final original = options.headers;

      DioBaseRequest(options);

      expect(
        identical(options.headers, original),
        isTrue,
        reason: 'constructor must not replace requestOptions.headers',
      );
      expect(
        options.headers['accept'],
        isA<List>(),
        reason: 'list-valued headers must not be flattened to String',
      );
    });

    test('setHeader updates internal flat map and requestOptions.headers', () {
      final options = RequestOptions(path: '/test');
      final dioRequest = DioBaseRequest(options);

      dioRequest.setHeader('if-none-match', 'etag123');

      expect(dioRequest.headers['if-none-match'], equals('etag123'));
      expect(options.headers['if-none-match'], equals('etag123'));
    });

    test('setHeader null removes from both maps', () {
      final options = RequestOptions(path: '/test');
      options.headers['x-test'] = 'value';
      final dioRequest = DioBaseRequest(options);

      dioRequest.setHeader('x-test', null);

      expect(dioRequest.headers.containsKey('x-test'), isFalse);
      expect(options.headers.containsKey('x-test'), isFalse);
    });

    test('headers getter returns flat Map<String, String> snapshot', () {
      final options = RequestOptions(path: '/test');
      options.headers['accept'] = ['application/json', 'text/html'];
      final dioRequest = DioBaseRequest(options);

      expect(
        dioRequest.headers['accept'],
        equals('application/json, text/html'),
      );
    });
  });
}
