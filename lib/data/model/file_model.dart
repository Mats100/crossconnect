class FileHistoryModel {
  final int? id;
  final String ip;
  final String fileName;
  final String filePath;

  FileHistoryModel({
    this.id,
    required this.ip,
    required this.fileName,
    required this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ip': ip,
      'fileName': fileName,
      'filePath': filePath,
    };
  }

  factory FileHistoryModel.fromMap(Map<String, dynamic> map) {
    return FileHistoryModel(
      id: map['id'],
      ip: map['ip'],
      fileName: map['fileName'],
      filePath: map['filePath'],
    );
  }
}
