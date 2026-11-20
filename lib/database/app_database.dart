import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('strokeguard.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        left_sensor_value INTEGER NOT NULL,
        right_sensor_value INTEGER NOT NULL,
        heart_rate INTEGER NOT NULL,
        measured_at TEXT NOT NULL
      )
    ''');

    await _createAlertsTable(db);
    await _createFamilyMembersTable(db);
  }

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createAlertsTable(db);
    }
    if (oldVersion < 3) {
      await _createFamilyMembersTable(db);
    }
  }

  Future<void> _createAlertsTable(Database db) async {
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createFamilyMembersTable(Database db) async {
    await db.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertFamilyMember({
    required String name,
    required String relationship,
    String email = '',
    required DateTime createdAt,
  }) async {
    final db = await instance.database;

    return await db.insert('family_members', {
      'name': name,
      'relationship': relationship,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    final db = await instance.database;

    return await db.query(
      'family_members',
      orderBy: 'created_at ASC',
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await instance.database;

    return await db.delete(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertMeasurement({
    required int leftSensorValue,
    required int rightSensorValue,
    required int heartRate,
    required DateTime measuredAt,
  }) async {
    final db = await instance.database;

    return await db.insert('measurements', {
      'left_sensor_value': leftSensorValue,
      'right_sensor_value': rightSensorValue,
      'heart_rate': heartRate,
      'measured_at': measuredAt.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMeasurements() async {
    final db = await instance.database;

    return await db.query(
      'measurements',
      orderBy: 'measured_at DESC',
    );
  }

  Future<int> insertAlert({
    required String title,
    required String message,
    required String severity,
    required DateTime createdAt,
  }) async {
    final db = await instance.database;

    return await db.insert('alerts', {
      'title': title,
      'message': message,
      'severity': severity,
      'created_at': createdAt.toIso8601String(),
      'is_read': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    final db = await instance.database;

    return await db.query(
      'alerts',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markAlertAsRead(int id) async {
    final db = await instance.database;

    return await db.update(
      'alerts',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
