// import 'dart:convert';
// import 'dart:io';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:xconn/xconn.dart' as xconn;
//
//
// class QRCodeController extends GetxController {
//   RxString? ipAddress = ''.obs;
//   RxString? fileName = ''.obs;
//   RxString? qrData = ''.obs;
//
//
//   static const procedureDownload = "io.xconn.progress.download";
//
//   @override
//   void onInit() {
//     super.onInit();
//     getIPAddress();
//     startWampRouter();
//   }
//
//
//
//   Future<void> startWampRouter() async {
//     print("shakeeb");
//     var rout = xconn.Router();
//     rout.addRealm("realm1");
//
//     var server = xconn.Server(rout);
//     await server.start("0.0.0.0", 8080);
//     print('WAMP Router started on ws://0.0.0.0:8080');
//   }
//
//
//   // CALLE FUNCTION REGISTER PROCEDURE
//   void calleRegisterProcedure() async {
//     var client = xconn.Client();
//     var session = await client.connect("ws://localhost:8080/ws", "realm1");
//
//     // Use the correct Invocation and Result from xconn
//     xconn.Result downloadHandler(xconn.Invocation inv) {
//       final file = File('test.txt');
//       final raf = file.openSync();
//       const chunkSize = 1024;
//       final length = file.lengthSync();
//
//       int offset = 0;
//       while (offset < length) {
//         final remaining = length - offset;
//         final size = remaining < chunkSize ? remaining : chunkSize;
//         final chunk = raf.readSync(size);
//         inv.sendProgress([chunk], null);
//         offset += size;
//       }
//
//       raf.closeSync();
//       return xconn.Result(args: ["Download complete!"]);
//     }
//
//     var registration = await session.register("procedureDownload", downloadHandler);
//     print("Registered procedure 'procedureDownload' successfully");
//
//     ProcessSignal.sigint.watch().listen((signal) async {
//       await session.unregister(registration);
//       await session.close();
//     });
//   }
//
//
//
//
//   Future<void> getIPAddress() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (addr.type == InternetAddressType.IPv4 &&
//               !addr.isLoopback &&
//               addr.address.startsWith('192')) {
//             ipAddress?.value = addr.address;
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Error getting IP address: $e");
//     }
//   }
//
//   Future<void> pickFileAndGenerateQR() async {
//     calleRegisterProcedure();
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4'],
//     );
//
//     if (result != null && ipAddress?.value != '') {
//       fileName?.value = result.files.single.name;
//
//       Map<String, String> qrContent = {
//         'fileName': fileName!.value!,
//         'ip': ipAddress!.value!,
//       };
//
//       qrData?.value = jsonEncode(qrContent);
//
//       showQRDialog();
//     } else {
//       Get.snackbar(
//         "Error",
//         "Failed to pick file or IP not available",
//         backgroundColor: Colors.red.shade400,
//         colorText: Colors.white,
//       );
//     }
//   }
//
//   void showQRDialog() {
//     Get.dialog(
//       Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "QR Code Generated",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 15),
//               QrImageView(
//                 data: qrData!.value!,
//                 version: QrVersions.auto,
//                 size: 200,
//               ),
//               const SizedBox(height: 15),
//               Text("File: ${fileName!.value}", style: TextStyle(fontWeight: FontWeight.w600),),
//               Text("IP: ${ipAddress!.value}", style: TextStyle(fontWeight: FontWeight.w600),),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue.shade700,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 25,
//                     vertical: 12,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: () => Get.back(),
//                 icon: const Icon(Icons.close, color: Colors.white,),
//                 label: const Text("Close"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:xconn/xconn.dart' as xconn;

import 'dart:typed_data';


class QRCodeController extends GetxController {
  RxString fileName = ''.obs;
  RxString filePath = ''.obs;
  RxString ipAddress = ''.obs;
  RxString qrData = ''.obs;
  Rx<Uint8List?> fileBytes = Rx<Uint8List?>(null);


  xconn.Client? client;
  xconn.Session? session;
  bool isRegistered = false;



  static const procedureDownload = "io.xconn.progress.download";

  @override
  void onInit() {
    super.onInit();
    getIPAddress();
    startWampRouter();
  }

  Future<void> startWampRouter() async {
    print("shakeeb");
    var rout = xconn.Router();
    rout.addRealm("realm1");

    var server = xconn.Server(rout);
    await server.start("0.0.0.0", 8080);
    print('WAMP Router started on ws://0.0.0.0:8080');
  }

  // CALLE FUNCTION REGISTER PROCEDURE
  void calleRegisterProcedure(Uint8List fileData) async {
    if (isRegistered) return;

    client ??= xconn.Client();
    session ??= await client!.connect("ws://0.0.0.0:8080/ws", "realm1");

    xconn.Result downloadHandler(xconn.Invocation inv) {
      const int chunkSize = 1024;
      int offset = 0;

      while (offset < fileData.length) {
        int end = offset + chunkSize;
        if (end > fileData.length) end = fileData.length;

        final chunk = fileData.sublist(offset, end);
        inv.sendProgress([chunk], null);
        offset = end;
      }

      return xconn.Result(args: ["Download complete!"]);
    }


    try {
      await session!.register(procedureDownload, downloadHandler);
      isRegistered = true;
      print("Registered procedure '$procedureDownload' successfully");
    } catch (e) {
      print("Procedure registration failed: $e");
    }

    ProcessSignal.sigint.watch().listen((signal) async {
      await session?.close();
    });
  }



  Future<void> getIPAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              addr.address.startsWith('192')) {
            ipAddress.value = addr.address;
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error getting IP address: $e");
    }
  }

  // Future<void> pickFileAndGenerateQR() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4', 'txt'],
  //   );
  //
  //   if (result != null && ipAddress.value != '') {
  //     fileName.value = result.files.single.name;
  //     filePath.value = result.files.single.path ?? '';
  //
  //     // Prepare QR Data with fileName, IP, and path
  //     Map<String, String> qrContent = {
  //       'fileName': fileName.value,
  //       'ip': ipAddress.value,
  //       'path': filePath.value,
  //     };
  //
  //     qrData.value = jsonEncode(qrContent);
  //
  //     // Start file-sharing procedure with selected file
  //     calleRegisterProcedure(filePath.value);
  //
  //     // Show QR Dialog
  //     showQRDialog();
  //   } else {
  //     Get.snackbar(
  //       "Error",
  //       "Failed to pick file or IP not available",
  //       backgroundColor: Colors.red.shade400,
  //       colorText: Colors.white,
  //     );
  //   }
  // }


  Future<void> pickFileAndGenerateQR() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4', 'mp3', 'txt'],
      withData: true, // This is important!
    );

    if (result != null && ipAddress.value != '') {
      qrData.value = '';
      fileName.value = result.files.single.name;
      fileBytes.value = result.files.single.bytes;

      if (fileBytes.value == null) {
        Get.snackbar(
          "Error",
          "Unable to read file data.",
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        return;
      }

      var uniqueId = const Uuid().v4();
      Map<String, String> qrContent = {
        'id': uniqueId,
        'fileName': fileName.value,
        'ip': ipAddress.value,
      };

      qrData.value = jsonEncode(qrContent);

      calleRegisterProcedure(fileBytes.value!); // pass bytes

      showQRDialog();
    } else {
      Get.snackbar(
        "Error",
        "Failed to pick file or IP not available",
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }




  void showQRDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "QR Code Generated",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              QrImageView(
                data: qrData.value,
                version: QrVersions.auto,
                size: 200,
              ),
              const SizedBox(height: 15),
              Text("File: ${fileName.value}",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text("IP: ${ipAddress.value}",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text("Path: ${filePath.value}",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
