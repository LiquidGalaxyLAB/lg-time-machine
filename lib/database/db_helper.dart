import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/country.dart';
import '../models/poi.dart';

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
      version: 4, // Incrementado para asegurar la actualización de columnas
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS pois');
      await _createPOIsTable(db);
      await _seedPOIs(db);
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

    await _createPOIsTable(db);
    await _seedData(db);
  }

  Future _createPOIsTable(Database db) async {
    await db.execute('''
      CREATE TABLE pois (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        countryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL NOT NULL,
        heading REAL NOT NULL,
        tilt REAL NOT NULL,
        range REAL NOT NULL,
        altitudeMode TEXT NOT NULL,
        FOREIGN KEY (countryId) REFERENCES countries (id) ON DELETE CASCADE
      )
    ''');
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

    await db.insert('settings', {'key': 'language', 'value': 'en'});
    await _seedPOIs(db);
  }

  Future _seedPOIs(Database db) async {
    final spainResult = await db.query('countries', where: 'name = ?', whereArgs: ['Spain']);
    if (spainResult.isNotEmpty) {
      final spainId = spainResult.first['id'] as int;
      
      List<POI> spainPOIs = [
        POI(
          countryId: spainId,
          name: 'Plaza Mayor de Salamanca',
          description: 'Plaza Square',
          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Plaza_Mayor_de_Salamanca_01.jpg/800px-Plaza_Mayor_de_Salamanca_01.jpg',
          latitude: 40.9648929,
          longitude: -5.6637844,
          altitude: 797.4306626,
          heading: 111.8158031,
          tilt: 60.6970201,
          range: 191.8245802,
          altitudeMode: 'relativeToGround',
        ),
        POI(
          countryId: spainId,
          name: 'Sagrada Familia',
          description: 'Catholic Basilica',
          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Sagrada_Familia_01.jpg/800px-Sagrada_Familia_01.jpg',
          latitude: 41.4034299,
          longitude: 2.1739006,
          altitude: 95.6508464,
          heading: 9.5377605,
          tilt: 59.4242461,
          range: 551.3130864,
          altitudeMode: 'relativeToGround',
        ),
      ];

      for (var poi in spainPOIs) {
        await db.insert('pois', poi.toMap());
      }
    }
  }

  Future<List<POI>> getPOIsByCountry(int countryId) async {
    final db = await instance.database;
    final result = await db.query(
      'pois',
      where: 'countryId = ?',
      whereArgs: [countryId],
    );
    return result.map((json) => POI.fromMap(json)).toList();
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
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
