import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/country.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('timemachine.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE countries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        flag TEXT NOT NULL
      )
    ''');

    // Seeding initial data
    await _seedData(db);
  }

  Future _seedData(Database db) async {
    List<Country> initialCountries = [
      Country(name: 'United States', flag: '🇺🇸'),
      Country(name: 'Italy', flag: '🇮🇹'),
      Country(name: 'France', flag: '🇫🇷'),
      Country(name: 'Spain', flag: '🇪🇸'),
    ];

    for (var country in initialCountries) {
      await db.insert('countries', country.toMap());
    }
  }

  Future<List<Country>> getAllCountries() async {
    final db = await instance.database;
    final result = await db.query('countries');
    return result.map((json) => Country.fromMap(json)).toList();
  }

  Future<List<Country>> searchCountries(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'countries',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result.map((json) => Country.fromMap(json)).toList();
  }
}
