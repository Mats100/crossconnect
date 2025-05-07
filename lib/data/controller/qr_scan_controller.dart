import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xconn/xconn.dart';
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import '../db/db_helper_class.dart';
import '../model/file_model.dart';

import 'dart:typed_data';

class QRScanController extends GetxController {
  static const procedureDownload = "io.xconn.progress.download";

  Rx<FileHistoryModel?> scannedData = Rx<FileHistoryModel?>(null);

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    final statuses =
        await [
          Permission.storage,
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();

    final anyDenied = statuses.values.any((status) => !status.isGranted);
    if (anyDenied) {
      // Get.snackbar("Permission Denied", "Storage/media access is required to download files.");
    }
  }

  Future<void> handleScannedData(String rawJson) async {
    try {
      await requestPermissions();

      final Map<String, dynamic> decoded = jsonDecode(rawJson);
      final model = FileHistoryModel.fromJson(decoded);
      scannedData.value = model;

      await caller();
    } catch (e) {
      Get.snackbar("Error", "Invalid QR code data");
    }
  }

  Future<void> caller() async {
    final model = scannedData.value;
    if (model == null) {
      Get.snackbar("Error", "No QR data available");
      return;
    }

    final ip = model.ip;
    final fileName = model.fileName;

    try {
      final client = Client();
      final session = await client.connect("ws://$ip:8080/ws", "realm1");

      final dir = await getApplicationDocumentsDirectory();
      final uniqueFileName =
          "${DateTime.now().microsecondsSinceEpoch}_$fileName";
      final path = "${dir.path}/$uniqueFileName";
      final file = File(path);
      final sink = file.openWrite();

      await session.callProgress(procedureDownload, (Result result) {
        final List<dynamic> chunkDynamic = result.args[0];
        final Uint8List chunk = Uint8List.fromList(chunkDynamic.cast<int>());
        sink.add(chunk);
      });

      await sink.close();
      await DBHelper.insertFile(
        FileHistoryModel(ip: ip, fileName: uniqueFileName, filePath: path),
      );

      // In QRScanController.caller()
      debugPrint('Original file name: $fileName');
      debugPrint('Unique file name: $uniqueFileName');
      debugPrint('Full path: $path');

      // After saving to DB
      final savedFile = File(path);
      debugPrint('File exists after save: ${await savedFile.exists()}');
      debugPrint('File size: ${(await savedFile.length())} bytes');

      Get.snackbar("Download Complete", "File saved at:\n$path");

      await session.close();
    } catch (e) {
      print("Download error: $e");
      Get.snackbar("Error", "Download failed: $e");
    }
  }
}
