import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Returns an [http.Client] that allows bad SSL certificates.
/// Use only in debug/development (e.g. Android emulator with CERTIFICATE_VERIFY_FAILED).
http.Client createDevHttpClient() {
  final client = HttpClient();
  client.badCertificateCallback = (_, __, ___) => true;
  return IOClient(client);
}
