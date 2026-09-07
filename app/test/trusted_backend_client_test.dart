import 'package:cie_connect/core/services/trusted_backend_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production trusted backend is configured by default', () {
    expect(trustedBackendBaseUrl, startsWith('https://'));
    expect(trustedBackendBaseUrl, endsWith('/functions/v1'));
  });

  test('client request ids are valid and unique', () {
    final first = TrustedBackendClient.newRequestId();
    final second = TrustedBackendClient.newRequestId();
    expect(first, matches(RegExp(r'^[a-f0-9-]{36}$')));
    expect(second, isNot(first));
  });
}
