import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../db/db_helper_class.dart';
import '../model/file_model.dart';

import 'dart:typed_data';

class FileHistoryController extends GetxController {
  RxList<FileHistoryModel> fileList = <FileHistoryModel>[].obs;
  Rx<FileHistoryModel?> fileById = Rx<FileHistoryModel?>(null);
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  final Map<String, Uint8List> imageCache = {};


  @override
  void onInit() {
    super.onInit();
    clearImageCache();
    fetchFiles().then((_) => verifyFiles());
  }

  void clearImageCache() {
    imageCache.clear();
    debugPrint('Image cache cleared');
  }



  Future<void> fetchFiles() async {
    isLoading.value = true;
    try {
      final data = await DBHelper.fetchFiles();
      imageCache.clear();
      fileList.value = data;
    } catch (e) {
      errorMessage.value = "Failed to load files: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> verifyFiles() async {
    for (var file in fileList) {
      final fileExists = await File(file.filePath).exists();
      print('File: ${file.fileName} | Path: ${file.filePath} | Exists: $fileExists');
      if (fileExists) {
        final bytes = await File(file.filePath).readAsBytes();
        print('File size: ${bytes.length} bytes');
      }
    }
  }


  Future<void> getFileById(int id) async {
    isLoading.value = true;
    errorMessage.value = '';
    fileById.value = null;

    try {
      final file = await DBHelper.getFileById(id);
      if (file != null) {
        fileById.value = file;
      } else {
        errorMessage.value = "No file found for ID $id.";
      }
    } catch (e) {
      errorMessage.value = "Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
}
