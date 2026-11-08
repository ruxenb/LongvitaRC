import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:longvita/services/secure_recipe_image.dart';

void main() {
  test('rejects HTTP URLs without any network request', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response('no', 200);
    });
    addTearDown(client.close);

    await expectLater(
      fetchSecureRecipeImage(
        Uri.parse('http://example.com/photo'),
        client: client,
      ),
      throwsFormatException,
    );
    expect(called, isFalse);
  });

  test('rejects redirect rather than requesting its HTTP target', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.followRedirects, isFalse);
      expect(request.url.scheme, 'https');
      return http.Response(
        '',
        302,
        headers: {'location': 'http://example.com/insecure.jpg'},
      );
    });
    addTearDown(client.close);

    await expectLater(
      fetchSecureRecipeImage(
        Uri.parse('https://example.com/hero.jpg'),
        client: client,
      ),
      throwsFormatException,
    );
    expect(requests, 1);
  });

  test('accepts a bounded image and returns original bytes', () async {
    final sample = Uint8List.fromList([1, 2, 3, 4]);
    final client = MockClient((request) async {
      expect(request.followRedirects, isFalse);
      return http.Response.bytes(
        sample,
        200,
        headers: {'content-type': 'image/png'},
      );
    });
    addTearDown(client.close);

    final result = await fetchSecureRecipeImage(
      Uri.parse('https://example.com/photo.png'),
      client: client,
    );
    expect(result, sample);
  });

  test('rejects oversized responses and wrong content types', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/html') {
        return http.Response(
          '<html>Not an image</html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      }
      return http.Response.bytes(
        List.filled(12, 0),
        200,
        headers: {'content-type': 'image/png'},
      );
    });
    addTearDown(client.close);

    await expectLater(
      fetchSecureRecipeImage(
        Uri.parse('https://example.com/big'),
        client: client,
        maxBytes: 8,
      ),
      throwsFormatException,
    );
    await expectLater(
      fetchSecureRecipeImage(
        Uri.parse('https://example.com/html'),
        client: client,
      ),
      throwsFormatException,
    );
  });

  test('rejects empty bytes and credential-bearing URLs', () async {
    final client = MockClient(
      (_) async =>
          http.Response.bytes([], 200, headers: {'content-type': 'image/png'}),
    );
    addTearDown(client.close);

    await expectLater(
      fetchSecureRecipeImage(
        Uri.parse('https://example.com/empty'),
        client: client,
      ),
      throwsFormatException,
    );
    await expectLater(
      fetchSecureRecipeImage(
        Uri.parse('https://user:pass@example.com/image'),
        client: client,
      ),
      throwsFormatException,
    );
  });
}
