import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'label_scanner.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE sessions (
      id TEXT PRIMARY KEY, store_id TEXT NOT NULL, store_name TEXT NOT NULL, profile TEXT NOT NULL,
      started_at INTEGER NOT NULL, completed_at INTEGER, status TEXT NOT NULL,
      created_at INTEGER DEFAULT (strftime('%s', 'now')), updated_at INTEGER DEFAULT (strftime('%s', 'now'))
    )''');

    await db.execute('''CREATE TABLE image_captures (
      id TEXT PRIMARY KEY, session_id TEXT NOT NULL, store_id TEXT NOT NULL, store_name TEXT NOT NULL,
      area TEXT, aisle TEXT, segment TEXT, capture_type TEXT NOT NULL, file_path TEXT NOT NULL,
      timestamp INTEGER NOT NULL, synced INTEGER DEFAULT 0, sync_attempted_at INTEGER,
      upload_status TEXT DEFAULT 'pending', error_message TEXT,
      created_at INTEGER DEFAULT (strftime('%s', 'now')),
      FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
    )''');

    await db.execute('''CREATE TABLE location_cache (
      store_id TEXT PRIMARY KEY, last_area TEXT, last_aisle TEXT, last_segment TEXT, cached_at INTEGER NOT NULL
    )''');

    await db.execute('CREATE INDEX idx_captures_session ON image_captures(session_id)');
    await db.execute('CREATE INDEX idx_captures_synced ON image_captures(synced)');
    await db.execute('CREATE INDEX idx_captures_store ON image_captures(store_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE image_captures ADD COLUMN area TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE image_captures ADD COLUMN aisle TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE image_captures ADD COLUMN segment TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE image_captures ADD COLUMN store_name TEXT');
      } catch (_) {}
      
      await db.execute('''CREATE TABLE IF NOT EXISTS location_cache (
        store_id TEXT PRIMARY KEY, last_area TEXT, last_aisle TEXT, last_segment TEXT, cached_at INTEGER NOT NULL
      )''');
    }
  }

  Future<void> saveLocationCache({required String storeId, String? area, String? aisle, String? segment}) async {
    final db = await database;
    await db.insert('location_cache', {
      'store_id': storeId, 'last_area': area, 'last_aisle': aisle, 'last_segment': segment,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getLocationCache(String storeId) async {
    final db = await database;
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
    final results = await db.query('location_cache', where: 'store_id = ? AND cached_at > ?', whereArgs: [storeId, threeDaysAgo]);
    return results.isEmpty ? null : results.first;
  }

  Future<String> insertImageCapture({
    required String sessionId, required String storeId, required String storeName,
    String? area, String? aisle, String? segment, required String captureType, required String filePath,
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('image_captures', {
      'id': id, 'session_id': sessionId, 'store_id': storeId, 'store_name': storeName,
      'area': area, 'aisle': aisle, 'segment': segment, 'capture_type': captureType,
      'file_path': filePath, 'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': 0, 'upload_status': 'pending',
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getPendingUploads() async {
    final db = await database;
    return await db.query('image_captures', where: 'synced = 0', orderBy: 'timestamp ASC');
  }

  Future<void> markAsSynced(String captureId) async {
    final db = await database;
    await db.update('image_captures', {
      'synced': 1, 'upload_status': 'synced', 'sync_attempted_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [captureId]);
  }

  Future<int> getTodaysSyncedCount(String storeId) async {
    final db = await database;
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM image_captures WHERE store_id = ? AND synced = 1 AND timestamp >= ?',
      [storeId, startOfDay],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getQueueCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM image_captures WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<String> startSession({required String storeId, required String storeName, required String profile}) async {
    final db = await database;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('sessions', {
      'id': sessionId, 'store_id': storeId, 'store_name': storeName, 'profile': profile,
      'started_at': DateTime.now().millisecondsSinceEpoch, 'status': 'active',
    });
    return sessionId;
  }

  Future<Map<String, dynamic>?> getActiveSession(String storeId) async {
    final db = await database;
    final results = await db.query('sessions', where: 'store_id = ? AND status = ?',
      whereArgs: [storeId, 'active'], orderBy: 'started_at DESC', limit: 1);
    return results.isEmpty ? null : results.first;
  }

  Future<void> completeSession(String sessionId) async {
    final db = await database;
    await db.update('sessions', {
      'status': 'completed', 'completed_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [sessionId]);
  }
}
