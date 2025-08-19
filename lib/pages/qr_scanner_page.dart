import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:passwordmanager/pages/widgets/corner_border_widget.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';

/// Page for the view for QR-Code scanning, will return to previous page once a QR-Code has been scanned.
/// * Flashlight can be enabled
/// * Camera can be switched
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  bool _torchEnabled = false;

  void _handleScan(BarcodeCapture capture) {
    if (_hasScanned) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code == null) return;
    setState(() {
      _hasScanned = true;
    });

    Navigator.pop(context, code);
  }

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
            child: MobileScanner(
              controller: _controller,
              overlayBuilder: (context, constrains) => Stack(children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: SizedBox(
                        width: 150,
                        child: Container(
                          color: Colors.grey.withAlpha(100),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _torchEnabled
                                      ? Icons.flash_on_rounded
                                      : Icons.flash_off_rounded,
                                ),
                                color: _torchEnabled
                                    ? Colors.amberAccent
                                    : Colors.white,
                                onPressed: () async {
                                  await _controller.toggleTorch();
                                  setState(() {
                                    _torchEnabled = !_torchEnabled;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.cameraswitch_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () async =>
                                    await _controller.switchCamera(),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: CornerBorderWidget(
                    size: Size(200, 200),
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: 20,
                    cornerLength: 40,
                    strokeWidth: 5,
                  ),
                ),
              ]),
              errorBuilder: (context, error) {
                return DefaultPageBody(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(25),
                    child: Column(
                      children: [
                        const SizedBox(height: 25.0),
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to access the camera',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onDetect: _handleScan,
            ),
          ),
        ],
      ),
    );
  }
}
