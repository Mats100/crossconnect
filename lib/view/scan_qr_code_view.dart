import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../data/controller/qr_scan_controller.dart';
import 'file_history_screen.dart';

class QRScanView extends StatefulWidget {
  const QRScanView({super.key});

  @override
  State<QRScanView> createState() => _QRScanViewState();
}

class _QRScanViewState extends State<QRScanView> {
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  final QRScanController controller = Get.put(QRScanController());

  @override
  void reassemble() {
    super.reassemble();
    if (qrController != null) {
      qrController!.pauseCamera();
      qrController!.resumeCamera();
    }
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrViewController) {
    this.qrController = qrViewController;
    qrViewController.scannedDataStream.listen((scanData) {
      qrController?.pauseCamera();
      controller.handleScannedData(scanData.code ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Cross Connect',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: (){
                Get.to(() => FileHistoryScreen());
              },
              child: const Text(
                'Downloaded Files',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Obx(() {
              final data = controller.scannedData.value;
              return data != null
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📁 File Name: ${data.fileName}"),
                        const SizedBox(height: 8),
                        Text("🌐 IP Address: ${data.ip}"),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                  : const Center(
                    child: Text(
                      "Scan a QR to see details.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
            }),
          ),
        ],
      ),
    );
  }
}
