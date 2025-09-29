// SQLite Database Layer for Upload Queue - Bulletproof Persistence
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'upload_models.dart';

// =============================================================================
// PERSISTENT DATABASE LAYER
// =============================================================================

class UploadQueueDatabase {
  static Database? _database;
  static const String dbName = 'upload_queue.db';
  static const int dbVersion = 1;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE upload_queue (
        id TEXT PRIMARY KEY,
        local_file_path TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT NOT NULL,
        error_message TEXT,
        server_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE upload_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        upload_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        message TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (upload_id) REFERENCES upload_queue (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_upload_status ON upload_queue (status)');
    await db.execute('CREATE INDEX idx_upload_created ON upload_queue (created_at)');
    
    debugPrint('Upload queue database tables created');
  }

  static Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
    debugPrint('Database upgrade from $oldVersion to $newVersion');
  }

  // =============================================================================
  // CRUD OPERATIONS
  // =============================================================================

  static Future<void> insertUpload(UploadQueueItem item) async {
    final db = await database;
    await db.insert('upload_queue', {
      'id': item.id,
      'local_file_path': item.localFilePath,
      'metadata_json': jsonEncode(item.metadata.toJson()),
      'status': item.status.name,
      'progress': item.progress,
      'retry_count': item.retryCount,
      'created_at': item.createdAt.toIso8601String(),
      'last_attempt_at': item.lastAttemptAt.toIso8601String(),
      'error_message': item.errorMessage,
      'server_url': item.serverUrl,
    });
  }

  static Future<void> updateUpload(UploadQueueItem item) async {
    final db = await database;
    await db.update(
      'upload_queue',
      {
        'status': item.status.name,
        'progress': item.progress,
        'retry_count': item.retryCount,
        'last_attempt_at': item.lastAttemptAt.toIso8601String(),
        'error_message': item.errorMessage,
        'server_url': item.serverUrl,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<List<UploadQueueItem>> getAllUploads() async {
    final db = await database;
    final maps = await db.query('upload_queue', orderBy: 'created_at DESC');
    
    return maps.map((map) => _mapToUploadItem(map)).toList();
  }

  static Future<List<UploadQueueItem>> getPendingUploads() async {
    final db = await database;
    final maps = await db.query(
      'upload_queue',
      where: 'status IN (?, ?, ?)',
      whereArgs: [UploadStatus.pending.name, UploadStatus.failed.name, UploadStatus.paused.name],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((map) => _mapToUploadItem(map)).toList();
  }

  static Future<List<UploadQueueItem>> getStuckUploads() async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    
    final maps = await db.query(
      'upload_queue',
      where: 'status != ? AND created_at < ?',
      whereArgs: [UploadStatus.completed.name, cutoffTime.toIso8601String()],
    );
    
    return maps.map((map) => _mapToUploadItem(map)).toList();
  }

  static Future<void> deleteUpload(String id) async {
    final db = await database;
    await db.delete('upload_queue', where: 'id = ?', whereArgs: [id]);
    await db.delete('upload_logs', where: 'upload_id = ?', whereArgs: [id]);
  }

  static Future<void> deleteCompletedUploads() async {
    final db = await database;
    final deletedRows = await db.delete(
      'upload_queue', 
      where: 'status = ?', 
      whereArgs: [UploadStatus.completed.name],
    );
    debugPrint('Deleted $deletedRows completed uploads');
  }

  static Future<void> logEvent(String uploadId, String eventType, String message) async {
    final db = await database;
    await db.insert('upload_logs', {
      'upload_id': uploadId,
      'event_type': eventType,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getUploadLogs(String uploadId) async {
    final db = await database;
    return await db.query(
      'upload_logs',
      where: 'upload_id = ?',
      whereArgs: [uploadId],
      orderBy: 'timestamp DESC',
    );
  }

  // =============================================================================
  // STATISTICS
  // =============================================================================

  static Future<Map<String, int>> getQueueStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM upload_queue 
      GROUP BY status
    ''');
    
    final stats = <String, int>{};
    for (final row in result) {
      stats[row['status'] as String] = row['count'] as int;
    }
    
    return stats;
  }

  static Future<int> getTotalFileSize() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(json_extract(metadata_json, '\$.fileSizeBytes')) as total_size
      FROM upload_queue
      WHERE status != ?
    ''', [UploadStatus.completed.name]);
    
    return (result.first['total_size'] as int?) ?? 0;
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  static UploadQueueItem _mapToUploadItem(Map<String, dynamic> map) {
    return UploadQueueItem(
      id: map['id'] as String,
      localFilePath: map['local_file_path'] as String,
      metadata: CaptureMetadata.fromJson(jsonDecode(map['metadata_json'] as String)),
      status: UploadStatus.values.byName(map['status'] as String),
      progress: (map['progress'] as num).toDouble(),
      retryCount: map['retry_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptAt: DateTime.parse(map['last_attempt_at'] as String),
      errorMessage: map['error_message'] as String?,
      serverUrl: map['server_url'] as String?,
    );
  }

  // =============================================================================
  // DATABASE MAINTENANCE
  // =============================================================================

  static Future<void> cleanup() async {
    final db = await database;
    
    // Delete logs older than 30 days
    final cutoffTime = DateTime.now().subtract(const Duration(days: 30));
    await db.delete(
      'upload_logs',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime.toIso8601String()],
    );
    
    // Vacuum database to reclaim space
    await db.execute('VACUUM');
    
    debugPrint('Database cleanup completed');
  }
}
