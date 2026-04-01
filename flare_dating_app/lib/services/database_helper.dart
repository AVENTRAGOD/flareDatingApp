import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flare_dating.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  first_name $textType,
  last_name $textType,
  dob $textType,
  gender $textType,
  photo_path $textTypeNullable,
  location $textTypeNullable
)
''');

    // Create interests table
    await db.execute('''
CREATE TABLE user_interests (
  id $idType,
  user_id $intType,
  interest $textType,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
)
''');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<int> insertInterest(int userId, String interest) async {
    final db = await instance.database;
    return await db.insert('user_interests', {
      'user_id': userId,
      'interest': interest,
    });
  }

  Future<List<String>> getUserInterests(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_interests',
      columns: ['interest'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((e) => e['interest'] as String).toList();
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'first_name', 'last_name', 'dob', 'gender', 'photo_path'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> updateUser(Map<String, dynamic> user, int id) async {
    final db = await instance.database;
    return db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateUserLocation(int id, String location) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'location': location},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
