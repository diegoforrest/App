import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class Record {
  int? id;
  String classification;
  String note;
  String pathToImage;
  DateTime date;

  Record({
    this.id,
    required this.classification,
    required this.note,
    required this.pathToImage,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classification': classification,
      'note': note,
      'pathToImage': pathToImage,
      'date': date.toIso8601String(), // Convert DateTime to String for storage
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      classification: map['classification'],
      note: map['note'],
      pathToImage: map['pathToImage'],
      date: DateTime.parse(map['date']), // Convert String back to DateTime
    );
  }
}

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'records';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'paddy_scan.db');

    return openDatabase(path, version: 1, onCreate: _createDb);
  }

Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classification TEXT,
        note TEXT,
        pathToImage TEXT,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertRecord(Record record) async {
    final db = await database;
    return db.insert(tableName, record.toMap());
  }

  Future<List<Record>> getRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

    Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateRecord(Record record) async {
    final db = await database;
    return await db.update(tableName, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteAllRecords() async { // New function to delete all
    final db = await database;
    return await db.delete(tableName);
  }
}