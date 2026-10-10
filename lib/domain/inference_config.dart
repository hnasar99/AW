import 'dart:io';

/// Credentials are only sent to an explicitly reviewed, absolute endpoint.
Uri validateInferenceEndpoint(String input) {
  final raw = input.trim();
  final uri = Uri.tryParse(raw);
  if (raw.length > 2048 ||
      uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException(
      'Use an absolute endpoint without embedded credentials, query or fragment.',
    );
  }
  final ip = InternetAddress.tryParse(uri.host);
  final loopback =
      uri.host.toLowerCase() == 'localhost' || (ip != null && ip.isLoopback);
  if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) {
    throw const FormatException(
      'Remote inference requires HTTPS. HTTP is only allowed on this device’s loopback address.',
    );
  }
  return uri;
}
