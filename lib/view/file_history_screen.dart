import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import '../data/controller/history_controller.dart';
import 'generate_qr_code_view.dart';

class FileHistoryScreen extends StatelessWidget {
  final FileHistoryController controller = Get.put(FileHistoryController());

  FileHistoryScreen({super.key});

  Widget fileIcon(String filePath) {
    final ext = extension(filePath).toLowerCase();
    if (['.jpg', '.jpeg', '.png'].contains(ext)) {
      return Icon(Icons.image, color: Colors.blue);
    }
    if (['.mp4'].contains(ext)) {
      return Icon(Icons.video_file, color: Colors.red);
    }
    if (['.mp3'].contains(ext)) {
      return Icon(Icons.audiotrack, color: Colors.green);
    }
    if (['.pdf'].contains(ext)) {
      return Icon(Icons.picture_as_pdf, color: Colors.orange);
    }
    return Icon(Icons.insert_drive_file, color: Colors.grey);
  }

  Future<Widget> buildImageWidget(String filePath) async {
    try {
      debugPrint('Attempting to load image from: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File not found: $filePath');
        return Icon(Icons.broken_image, color: Colors.red);
      }

      final bytes = await file.readAsBytes();
      debugPrint('Loaded ${bytes.length} bytes from $filePath');

      if (bytes.isEmpty) {
        debugPrint('Empty file: $filePath');
        return Icon(Icons.broken_image, color: Colors.red);
      }
      final checksum = bytes.length;
      debugPrint('File checksum: $checksum');

      return Image.memory(
        bytes,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error displaying image: $error');
          return Icon(Icons.broken_image, color: Colors.red);
        },
      );
    } catch (e) {
      debugPrint("Critical error loading image: $e");
      return Icon(Icons.broken_image, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        leading: GestureDetector(
          onTap: () {
            Get.to(() => GenerateQRCodeView());
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text("Downloaded Files"),
      ),
      body: Obx(() {
        if (controller.fileList.isEmpty) {
          return Center(child: Text("No files found"));
        }

        return ListView.builder(
          itemCount: controller.fileList.length,
          itemBuilder: (_, index) {
            final file = controller.fileList[index];
            final ext = extension(file.filePath).toLowerCase();

            return FutureBuilder<Widget>(
              future:
                  ['.jpg', '.jpeg', '.png'].contains(ext)
                      ? buildImageWidget(file.filePath.toString())
                      : Future.value(fileIcon(file.filePath)),
              builder: (context, snapshot) {
                return ListTile(
                  key: ValueKey(file.filePath),
                  // Ensure unique widget for each file
                  leading: FutureBuilder<Widget>(
                    future:
                        ['.jpg', '.jpeg', '.png'].contains(ext)
                            ? buildImageWidget(file.filePath)
                            : Future.value(fileIcon(file.filePath)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        debugPrint(
                          'Error for ${file.filePath}: ${snapshot.error}',
                        );
                        return Icon(Icons.error, color: Colors.red);
                      }
                      return snapshot.data ?? Icon(Icons.insert_drive_file);
                    },
                  ),
                  title: Text(file.fileName),
                  subtitle: Text(file.filePath),
                  onTap: () async {
                    final result = await OpenFile.open(file.filePath);
                    debugPrint(
                      "Opened: ${file.filePath}, result: ${result.message}",
                    );
                  },
                );
              },
            );
          },
        );
      }),
    );
  }
}
