import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> scanCompanyQr(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const _CompanyQrScanPage()),
  );
}

class _CompanyQrScanPage extends StatefulWidget {
  const _CompanyQrScanPage();

  @override
  State<_CompanyQrScanPage> createState() => _CompanyQrScanPageState();
}

class _CompanyQrScanPageState extends State<_CompanyQrScanPage> {
  var _handled = false;

  void _take(String? raw) {
    if (_handled || raw == null || raw.isEmpty || !mounted) return;
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR de la empresa')),
      body: MobileScanner(
        onDetect: (capture) => _take(capture.barcodes.firstOrNull?.rawValue),
      ),
    );
  }
}
