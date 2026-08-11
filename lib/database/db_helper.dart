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
      version: 12, // Incremented version for POI removal
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 12) {
      await db.execute('DROP TABLE IF EXISTS pois');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE countries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        flag TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedData(db);
  }

  Future _seedData(Database db) async {
    List<Country> initialCountries = [
      Country(name: 'United States', flag: '🇺🇸'),
      Country(name: 'Italy', flag: '🇮🇹'),
      Country(name: 'France', flag: '🇫🇷'),
      Country(name: 'Spain', flag: '🇪🇸'),
      Country(name: 'United Kingdom', flag: '🇬🇧'),
      Country(name: 'Germany', flag: '🇩🇪'),
      Country(name: 'Greece', flag: '🇬🇷'),
      Country(name: 'Egypt', flag: '🇪🇬'),
      Country(name: 'China', flag: '🇨🇳'),
      Country(name: 'Japan', flag: '🇯🇵'),
      Country(name: 'India', flag: '🇮🇳'),
      Country(name: 'Brazil', flag: '🇧🇷'),
      Country(name: 'Australia', flag: '🇦🇺'),
      Country(name: 'Mexico', flag: '🇲🇽'),
      Country(name: 'Peru', flag: '🇵🇪'),
      Country(name: 'Canada', flag: '🇨🇦'),
    ];

    for (var country in initialCountries) {
      await db.insert('countries', country.toMap());
    }

    await db.insert('settings', {'key': 'language', 'value': 'en'});
    await db.insert('settings', {'key': 'showLogos', 'value': 'true'});
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<List<Country>> getAllCountries() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('countries');
    return result.map((json) => Country.fromMap(json)).toList();
  }

  Future<List<Country>> searchCountries(String query) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'countries',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result.map((json) => Country.fromMap(json)).toList();
  }
}
