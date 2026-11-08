import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Downloads only HTTPS recipe images. The HTTP client must not follow
/// redirects, including a redirect from HTTPS to an insecure HTTP URL.
Future<Uint8List> fetchSecureRecipeImage(
  Uri url, {
  http.Client? client,
  int maxBytes = 5 * 1024 * 1024,
}) async {
  if (url.scheme != 'https' || !url.hasAuthority || url.userInfo.isNotEmpty) {
    throw const FormatException('Recipe image URL must be HTTPS.');
  }
  if (maxBytes <= 0) {
    throw ArgumentError.value(maxBytes, 'maxBytes', 'Must be positive.');
  }

  final ownedClient = client == null;
  final httpClient = client ?? http.Client();
  try {
    final request = http.Request('GET', url)..followRedirects = false;
    final response = await httpClient
        .send(request)
        .timeout(const Duration(seconds: 12));

    // Do not retry or follow 301/302/307/308. BrowserClient raises an
    // exception when redirect='error'; IOClient returns the 3xx response.
    if (response.statusCode != 200 || response.isRedirect) {
      throw const FormatException('Recipe image request was rejected.');
    }
    final mediaType = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (mediaType == null || !mediaType.startsWith('image/')) {
      throw const FormatException('Recipe image response is not an image.');
    }
    if (response.contentLength != null && response.contentLength! > maxBytes) {
      throw const FormatException('Recipe image exceeds the size limit.');
    }

    final bytes = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 12),
    )) {
      total += chunk.length;
      if (total > maxBytes) {
        throw const FormatException('Recipe image exceeds the size limit.');
      }
      bytes.add(chunk);
    }
    if (total == 0) {
      throw const FormatException('Recipe image is empty.');
    }
    return bytes.takeBytes();
  } finally {
    if (ownedClient) httpClient.close();
  }
}
