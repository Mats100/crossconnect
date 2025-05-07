import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/file_model.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'file_history.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
        CREATE TABLE files (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fileName TEXT,
          filePath TEXT
        )
      ''');
      },
    );
  }

  static Future<void> insertFile(FileHistoryModel file) async {
    final db = await initDB();
    await db.insert('files', file.toMap());
  }

  static Future<List<FileHistoryModel>> fetchFiles() async {
    final db = await initDB();
    final maps = await db.query('files');
    return maps.map((e) => FileHistoryModel.fromMap(e)).toList();
  }

  static Future<FileHistoryModel?> getFileById(int id) async {
    final db = await initDB();
    final maps = await db.query('files', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return FileHistoryModel.fromMap(maps.first);
    } else {
      return null;
    }
  }
}
