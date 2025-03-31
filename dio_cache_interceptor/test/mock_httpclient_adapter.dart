import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_cache_core/http_cache_core.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  static const String mockHost = 'mockserver';
  static const String mockBase = 'http://$mockHost';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    final uri = options.uri;

    switch (uri.path) {
      case '/ok':
        if (options.headers.containsKey('if-none-match')) {
          return ResponseBody.fromString(
            '{}',
            304,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'etag': ['5678'],
            },
          );
        }

        if (options.extra.containsKey('x-err')) {
          return ResponseBody.fromString(
            '{}',
            500,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }

        return ResponseBody.fromString(
          jsonEncode({'path': uri.path}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'etag': ['1234'],
          },
        );
      case '/ok-nodirective':
        return ResponseBody.fromString(
          jsonEncode({'path': uri.path}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      case '/post':
        return ResponseBody.fromString(
          jsonEncode({'path': uri.path}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'etag': ['1234'],
          },
        );
      case '/exception':
        if (options.extra.containsKey('x-err')) {
          throw DioException(requestOptions: options);
        }

        return ResponseBody.fromString(
          jsonEncode({'path': uri.path}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'etag': ['1234'],
            'last-modified': [
              HttpDate.format(DateTime.now().add(Duration(days: 1)))
            ],
          },
        );
      case '/ok-stream':
        return ResponseBody(
          File('./README.md').openRead().cast<Uint8List>(),
          200,
          headers: {
            Headers.contentLengthHeader: [
              File('./README.md').lengthSync().toString()
            ],
            'etag': ['5678'],
          },
        );

      case '/ok-bytes':
        {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({'path': uri.path})),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'etag': ['9875'],
            },
          );
        }
      case '/cache-control':
        {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({'path': uri.path})),
            options.headers.containsKey('if-none-match') ? 304 : 200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              cacheControlHeader: ['public', 'max-age=0'],
              'date': ['Wed, 21 Oct 2000 07:28:00 GMT'],
              'expires': [
                HttpDate.format(DateTime.now().add(Duration(days: 10)))
              ],
              'etag': ['9875'],
            },
          );
        }
      case '/cache-control-expired':
        {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({'path': uri.path})),
            options.headers.containsKey('if-none-match') ? 304 : 200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              cacheControlHeader: ['public'],
              'expires': ['Wed, 21 Oct 2000 07:28:00 GMT'],
              'etag': ['9875'],
            },
          );
        }
      case '/cache-control-no-store':
        {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({'path': uri.path})),
            options.headers.containsKey('if-none-match') ? 304 : 200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              cacheControlHeader: ['no-store'],
              'expires': [
                HttpDate.format(DateTime.now().add(Duration(days: 10)))
              ],
              'etag': ['9875'],
            },
          );
        }
      case '/max-age':
        {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({'path': uri.path})),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'last-modified': [HttpDate.format(DateTime.now())],
              cacheControlHeader: ['public, max-age=1'],
            },
          );
        }
      case '/download':
        {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({'path': uri.path})),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'Content-Disposition': ['attachment; filename="filename.jpg"'],
              'last-modified': [HttpDate.format(DateTime.now())],
            },
          );
        }
      default:
        return ResponseBody.fromString('', 404);
    }
  }

  @override
  void close({bool force = false}) {}
}
