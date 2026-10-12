import 'dart:io';
import 'dart:math';

/// Immutable build policy. The existing Arc build remains the default.
const bool awLabTextOnly = bool.fromEnvironment('AW_LAB_TEXT_ONLY');

const String labTextMode = 'lab-text-only';
const String labInferenceKind = 'lab-endpoint';
const String inferenceSettingsKey = awLabTextOnly
    ? 'aw_lab_text_settings_v1'
    : 'aw_settings_v1';

/// Laboratory traffic must use an explicitly established loopback transport.
/// A DNS name or a private LAN address is not proof of an authorized endpoint.
Uri validateLabInferenceEndpoint(String input) {
  final uri = validateInferenceEndpoint(input);
  final literal = RegExp(
    r'^https?://(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|\[::1\])(?::([1-9][0-9]{0,4}))?/v1$',
  ).firstMatch(input.trim());
  final address = InternetAddress.tryParse(uri.host);
  final port = literal?.group(2);
  final host = literal?.group(1);
  final canonicalV4 =
      host == null ||
      !host.startsWith('127.') ||
      host.split('.').map(int.parse).join('.') == host;
  if (literal == null ||
      address == null ||
      !address.isLoopback ||
      !canonicalV4 ||
      (port != null &&
          (int.parse(port) > 65535 ||
              (uri.scheme == 'http' && port == '80') ||
              (uri.scheme == 'https' && port == '443')))) {
    throw const FormatException(
      'El laboratorio requiere una IP loopback literal y la ruta /v1. '
      'Configurá primero el transporte autorizado hacia tu servidor.',
    );
  }
  return uri;
}

String validateLabModel(String input) {
  final model = input.trim();
  final lower = model.toLowerCase();
  if (model.isEmpty ||
      model.length > 256 ||
      model.contains('\u0000') ||
      lower.startsWith('hint:') ||
      model.contains('@') ||
      lower.contains('cloud')) {
    throw const FormatException(
      'Usá el ID explícito de un modelo local, sin rutas hint:, @ ni cloud. '
      'Si un nombre local contiene cloud, configurá un alias local antes de usarlo.',
    );
  }
  return model;
}

String newLabRequestId() {
  final random = Random.secure();
  final suffix = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return 'awlab-$suffix';
}

bool isLabRequestId(String value) =>
    value.length == 38 && RegExp(r'^awlab-[a-f0-9]{32}$').hasMatch(value);

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
