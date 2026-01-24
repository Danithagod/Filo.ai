// SQLite Database Helper for Chat
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class ChatDatabase {
  static final ChatDatabase _instance = ChatDatabase._internal();
  factory ChatDatabase() => _instance;
  ChatDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'chat_history.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        created_at TEXT,
        updated_at TEXT,
        pinned_index INTEGER
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT,
        role TEXT,
        content TEXT,
        timestamp TEXT,
        is_edited INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        reply_to_id TEXT,
        metadata TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Indices for performance
    await db.execute(
      'CREATE INDEX idx_messages_conversation ON messages (conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON messages (timestamp)',
    );

    // FTS5 Virtual Table for Search (Deep search optimization)
    await db.execute('''
      CREATE VIRTUAL TABLE messages_search USING fts5(
        content,
        message_id UNINDEXED,
        conversation_id UNINDEXED,
        tokenize='porter unicode61'
      )
    ''');

    // Triggers to sync FTS5 table
    await _createSearchTriggers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade from v1 to v2: Add FTS5 support
      await db.execute('''
        CREATE VIRTUAL TABLE messages_search USING fts5(
          content,
          message_id UNINDEXED,
          conversation_id UNINDEXED,
          tokenize='porter unicode61'
        )
      ''');

      // Populate initial search data ensuring rowid sync
      await db.execute('''
        INSERT INTO messages_search (rowid, content, message_id, conversation_id)
        SELECT rowid, content, id, conversation_id FROM messages WHERE is_deleted = 0
      ''');

      await _createSearchTriggers(db);
    }
  }

  Future<void> _createSearchTriggers(Database db) async {
    // Insert trigger - Sync ROWID for O(1) lookups
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_messages_insert AFTER INSERT ON messages
      BEGIN
        INSERT INTO messages_search(rowid, content, message_id, conversation_id)
        VALUES (new.rowid, new.content, new.id, new.conversation_id);
      END;
    ''');

    // Update trigger - Update by ROWID (fast)
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_messages_update AFTER UPDATE ON messages
      BEGIN
        UPDATE messages_search 
        SET content = new.content
        WHERE rowid = old.rowid;
      END;
    ''');

    // Delete trigger - Delete by ROWID (fast)
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_messages_delete AFTER DELETE ON messages
      BEGIN
        DELETE FROM messages_search WHERE rowid = old.rowid;
      END;
    ''');
  }
}
