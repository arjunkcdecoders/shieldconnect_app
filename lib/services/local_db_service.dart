import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shieldconnect_app/model/conversation_model.dart';
import 'package:shieldconnect_app/model/message_model.dart';
import 'package:shieldconnect_app/model/friend_model.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathStr = join(dbPath, 'shieldconnect.db');

    return await openDatabase(
      pathStr,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        name TEXT,
        avatar TEXT,
        type TEXT,
        show_typing_indicator INTEGER DEFAULT 1,
        show_last_seen INTEGER DEFAULT 1,
        show_profile_pic INTEGER DEFAULT 1,
        relationship_status TEXT,
        requested_by TEXT,
        is_favorite INTEGER DEFAULT 0,
        last_message_id TEXT,
        last_message_content TEXT,
        last_message_type TEXT,
        last_message_sender_id TEXT,
        last_message_recipient_id TEXT,
        last_message_group_id TEXT,
        last_message_status TEXT,
        last_message_created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT,
        created_at TEXT,
        raw_json TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_messages_chat_id_created_at ON messages(chat_id, created_at DESC)');

    await db.execute('''
      CREATE TABLE announcements (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        media TEXT,
        mediaType TEXT,
        status TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE calls (
        id TEXT PRIMARY KEY,
        created_at TEXT,
        raw_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE status_cache (
        key TEXT PRIMARY KEY,
        raw_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dhsi_cache (
        userId TEXT PRIMARY KEY,
        raw_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_cache (
        userId TEXT PRIMARY KEY,
        raw_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_wallpaper (
        user_id TEXT PRIMARY KEY,
        wallpaper_id TEXT,
        wallpaper_image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE media_cache (
        url TEXT PRIMARY KEY,
        local_path TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE messages (
          id TEXT PRIMARY KEY,
          chat_id TEXT,
          created_at TEXT,
          raw_json TEXT
        )
      ''');
      await db.execute('CREATE INDEX idx_messages_chat_id_created_at ON messages(chat_id, created_at DESC)');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE announcements (
          id TEXT PRIMARY KEY,
          title TEXT,
          content TEXT,
          media TEXT,
          mediaType TEXT,
          status TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE calls (
          id TEXT PRIMARY KEY,
          created_at TEXT,
          raw_json TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE status_cache (
          key TEXT PRIMARY KEY,
          raw_json TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE dhsi_cache (
          userId TEXT PRIMARY KEY,
          raw_json TEXT
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE profile_cache (
          userId TEXT PRIMARY KEY,
          raw_json TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE user_wallpaper (
          user_id TEXT PRIMARY KEY,
          wallpaper_id TEXT,
          wallpaper_image TEXT
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE media_cache (
          url TEXT PRIMARY KEY,
          local_path TEXT
        )
      ''');
    }
  }

  /// Inserts or replaces conversation records in the local database using ConversationModel.
  Future<void> saveConversations(List<ConversationModel> recentChats) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final chat in recentChats) {
        final conversation = chat.conversation;
        final lastMessage = chat.lastMessage;
        final relationship = chat.relationship;
        final requestedBy = chat.requestedBy ?? relationship?.requestedBy;
        final bool isFav = chat.isFavorite == true;

        final id = (conversation?.id).toString();
        if (id.isEmpty || id == 'null') continue;

        batch.insert(
          'conversations',
          {
            'id': id,
            'name': conversation?.name?.toString() ?? '',
            'avatar': conversation?.image?.toString() ?? '',
            'type': conversation?.type?.toString() ?? 'personal',
            'show_typing_indicator': (conversation?.showTypingIndicator == false) ? 0 : 1,
            'show_last_seen': (conversation?.showLastSeen == false) ? 0 : 1,
            'show_profile_pic': (conversation?.showProfilePic == false) ? 0 : 1,
            'relationship_status': relationship?.status?.toString(),
            'requested_by': requestedBy?.toString(),
            'is_favorite': isFav ? 1 : 0,
            'last_message_id': lastMessage?.id?.toString(),
            'last_message_content': lastMessage?.content?.toString() ?? '',
            'last_message_type': lastMessage?.messageType?.toString() ?? 'text',
            'last_message_sender_id': lastMessage?.senderId?.toString(),
            'last_message_recipient_id': lastMessage?.recipientId?.toString(),
            'last_message_group_id': lastMessage?.groupId?.toString(),
            'last_message_status': lastMessage?.status?.toString() ?? 'sent',
            'last_message_created_at': lastMessage?.createdAt?.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error saving conversations in local DB: $e');
    }
  }

  /// Saves a single conversation or updates its last message preview using ConversationModel.
  Future<void> saveSingleConversation(ConversationModel chatItem) async {
    try {
      final db = await database;
      final conversation = chatItem.conversation;
      final lastMessage = chatItem.lastMessage;
      final relationship = chatItem.relationship;
      final requestedBy = chatItem.requestedBy ?? relationship?.requestedBy;
      final bool isFav = chatItem.isFavorite == true;

      final id = (conversation?.id).toString();
      if (id.isEmpty || id == 'null') return;

      await db.insert(
        'conversations',
        {
          'id': id,
          'name': conversation?.name?.toString() ?? '',
          'avatar': conversation?.image?.toString() ?? '',
          'type': conversation?.type?.toString() ?? 'personal',
          'show_typing_indicator': (conversation?.showTypingIndicator == false) ? 0 : 1,
          'show_last_seen': (conversation?.showLastSeen == false) ? 0 : 1,
          'show_profile_pic': (conversation?.showProfilePic == false) ? 0 : 1,
          'relationship_status': relationship?.status?.toString(),
          'requested_by': requestedBy?.toString(),
          'is_favorite': isFav ? 1 : 0,
          'last_message_id': lastMessage?.id?.toString(),
          'last_message_content': lastMessage?.content?.toString() ?? '',
          'last_message_type': lastMessage?.messageType?.toString() ?? 'text',
          'last_message_sender_id': lastMessage?.senderId?.toString(),
          'last_message_recipient_id': lastMessage?.recipientId?.toString(),
          'last_message_group_id': lastMessage?.groupId?.toString(),
          'last_message_status': lastMessage?.status?.toString() ?? 'sent',
          'last_message_created_at': lastMessage?.createdAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving single conversation in local DB: $e');
    }
  }

  /// Fetches cached conversations list as ConversationModel instances.
  Future<List<ConversationModel>> getConversations() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'conversations',
        orderBy: 'last_message_created_at DESC',
      );

      return List.generate(maps.length, (i) {
        final row = maps[i];
        final id = row['id'].toString();

        return ConversationModel(
          isFavorite: row['is_favorite'] == 1,
          unreadCount: 0, // Dynamic, managed in-memory in homescreen_controller
          requestedBy: row['requested_by']?.toString(),
          relationship: FriendModel(
            status: row['relationship_status']?.toString(),
            requestedBy: row['requested_by']?.toString(),
          ),
          conversation: ConversationEntity(
            id: id,
            name: row['name']?.toString(),
            image: row['avatar']?.toString(),
            type: row['type']?.toString(),
            showTypingIndicator: row['show_typing_indicator'] == 1,
            showLastSeen: row['show_last_seen'] == 1,
            showProfilePic: row['show_profile_pic'] == 1,
            isOnline: false, // Managed dynamically in memory
          ),
          lastMessage: row['last_message_id'] != null
              ? MessageModel(
                  id: row['last_message_id']?.toString(),
                  content: row['last_message_content']?.toString(),
                  messageType: row['last_message_type']?.toString(),
                  senderId: row['last_message_sender_id']?.toString(),
                  recipientId: row['last_message_recipient_id']?.toString(),
                  groupId: row['last_message_group_id']?.toString(),
                  status: row['last_message_status']?.toString(),
                  createdAt: row['last_message_created_at'] != null
                      ? DateTime.tryParse(row['last_message_created_at'].toString())
                      : null,
                )
              : null,
        );
      });
    } catch (e) {
      debugPrint('Error loading cached conversations: $e');
      return [];
    }
  }

  /// Deletes a conversation from cache.
  Future<void> deleteConversation(String id) async {
    try {
      final db = await database;
      await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting conversation from local DB: $e');
    }
  }

  /// Clears the entire conversations table.
  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('conversations');
    } catch (e) {
      debugPrint('Error clearing conversations database: $e');
    }
  }

  /// Saves list of raw message maps from API into local database cache under a chat_id.
  Future<void> saveMessages(String chatId, List<dynamic> rawMessages) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final msg in rawMessages) {
        if (msg is! Map) continue;
        final castedMsg = Map<String, dynamic>.from(msg);
        final String? msgId = castedMsg['_id']?.toString() ?? castedMsg['id']?.toString();
        final String? createdAt = castedMsg['created_at']?.toString() ?? castedMsg['createdAt']?.toString();

        if (msgId == null || msgId.isEmpty) continue;

        batch.insert(
          'messages',
          {
            'id': msgId,
            'chat_id': chatId,
            'created_at': createdAt ?? DateTime.now().toIso8601String(),
            'raw_json': jsonEncode(castedMsg),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error saving messages in local DB: $e');
    }
  }

  /// Saves a single raw message map into local database cache.
  Future<void> saveSingleMessage(String chatId, Map<String, dynamic> rawMessage) async {
    try {
      final db = await database;
      final String? msgId = rawMessage['_id']?.toString() ?? rawMessage['id']?.toString();
      final String? createdAt = rawMessage['created_at']?.toString() ?? rawMessage['createdAt']?.toString();

      if (msgId == null || msgId.isEmpty) return;

      await db.insert(
        'messages',
        {
          'id': msgId,
          'chat_id': chatId,
          'created_at': createdAt ?? DateTime.now().toIso8601String(),
          'raw_json': jsonEncode(rawMessage),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving single message in local DB: $e');
    }
  }

  /// Retrieves list of raw messages for a chat from SQLite ordered by created_at DESC with limit/offset.
  Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    required int limit,
    required int offset,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      final List<Map<String, dynamic>> results = [];
      for (final row in rows) {
        final String? rawJson = row['raw_json']?.toString();
        if (rawJson != null && rawJson.isNotEmpty) {
          try {
            final Map<String, dynamic> decoded = Map<String, dynamic>.from(jsonDecode(rawJson));
            results.add(decoded);
          } catch (_) {}
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error loading cached messages: $e');
      return [];
    }
  }

  /// Clears chat history for a specific chat.
  Future<void> clearChatHistory(String chatId) async {
    try {
      final db = await database;
      await db.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
    } catch (e) {
      debugPrint('Error clearing chat history in local DB: $e');
    }
  }

  /// Inserts or replaces announcement records in the local database.
  Future<void> saveAnnouncements(List<dynamic> rawAnnouncements) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final raw in rawAnnouncements) {
        if (raw is Map) {
          final id = (raw['_id'] ?? raw['id'] ?? '').toString();
          if (id.isEmpty) continue;

          batch.insert(
            'announcements',
            {
              'id': id,
              'title': raw['title']?.toString(),
              'content': (raw['content'] ?? raw['message'])?.toString(),
              'media': raw['media']?.toString(),
              'mediaType': raw['mediaType']?.toString(),
              'status': raw['status']?.toString(),
              'createdAt': (raw['createdAt'] ?? raw['created_at'] ?? raw['time'])?.toString(),
              'updatedAt': raw['updatedAt']?.toString(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error saving announcements in local DB: $e');
    }
  }

  /// Fetches cached announcements list as raw maps.
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'announcements',
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        final row = maps[i];
        return {
          '_id': row['id'],
          'title': row['title'],
          'content': row['content'],
          'media': row['media'],
          'mediaType': row['mediaType'],
          'status': row['status'],
          'createdAt': row['createdAt'],
          'updatedAt': row['updatedAt'],
        };
      });
    } catch (e) {
      debugPrint('Error loading cached announcements: $e');
      return [];
    }
  }

  /// Clears the announcements table.
  Future<void> clearAnnouncementsCache() async {
    try {
      final db = await database;
      await db.delete('announcements');
    } catch (e) {
      debugPrint('Error clearing announcements database: $e');
    }
  }

  /// Inserts or replaces call records in the local database.
  Future<void> saveCalls(List<dynamic> rawCalls) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final raw in rawCalls) {
        if (raw is Map) {
          final casted = Map<String, dynamic>.from(raw);
          final id = (casted['_id'] ?? casted['id'] ?? '').toString();
          final createdAt = casted['created_at']?.toString() ?? DateTime.now().toIso8601String();
          if (id.isEmpty) continue;

          batch.insert(
            'calls',
            {
              'id': id,
              'created_at': createdAt,
              'raw_json': jsonEncode(casted),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error saving calls in local DB: $e');
    }
  }

  /// Fetches cached calls list as raw maps.
  Future<List<Map<String, dynamic>>> getCalls() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'calls',
        orderBy: 'created_at DESC',
      );

      final List<Map<String, dynamic>> results = [];
      for (final row in rows) {
        final String? rawJson = row['raw_json']?.toString();
        if (rawJson != null && rawJson.isNotEmpty) {
          try {
            final Map<String, dynamic> decoded = Map<String, dynamic>.from(jsonDecode(rawJson));
            results.add(decoded);
          } catch (_) {}
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error loading cached calls: $e');
      return [];
    }
  }

  /// Clears the calls table.
  Future<void> clearCallsCache() async {
    try {
      final db = await database;
      await db.delete('calls');
    } catch (e) {
      debugPrint('Error clearing calls database: $e');
    }
  }

  /// Saves raw status data in status_cache.
  Future<void> saveStatusCache(String key, List<dynamic> rawData) async {
    try {
      final db = await database;
      await db.insert(
        'status_cache',
        {
          'key': key,
          'raw_json': jsonEncode(rawData),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving status cache ($key) in local DB: $e');
    }
  }

  /// Retrieves raw cached status data.
  Future<List<dynamic>> getStatusCache(String key) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'status_cache',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (rows.isNotEmpty) {
        final String? rawJson = rows.first['raw_json']?.toString();
        if (rawJson != null && rawJson.isNotEmpty) {
          final decoded = jsonDecode(rawJson);
          if (decoded is List) {
            return decoded;
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error loading cached statuses ($key): $e');
      return [];
    }
  }

  /// Clears the status_cache table.
  Future<void> clearStatusCache() async {
    try {
      final db = await database;
      await db.delete('status_cache');
    } catch (e) {
      debugPrint('Error clearing status cache database: $e');
    }
  }

  /// Saves raw DHSI data for a user in dhsi_cache.
  Future<void> saveDhsiCache(String userId, Map<String, dynamic> rawData) async {
    try {
      final db = await database;
      await db.insert(
        'dhsi_cache',
        {
          'userId': userId,
          'raw_json': jsonEncode(rawData),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving DHSI cache in local DB: $e');
    }
  }

  /// Retrieves raw cached DHSI data for a user.
  Future<Map<String, dynamic>?> getDhsiCache(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'dhsi_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      if (rows.isNotEmpty) {
        final String? rawJson = rows.first['raw_json']?.toString();
        if (rawJson != null && rawJson.isNotEmpty) {
          return Map<String, dynamic>.from(jsonDecode(rawJson));
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error loading cached DHSI: $e');
      return null;
    }
  }

  /// Clears the dhsi_cache table.
  Future<void> clearDhsiCache() async {
    try {
      final db = await database;
      await db.delete('dhsi_cache');
    } catch (e) {
      debugPrint('Error clearing DHSI cache database: $e');
    }
  }

  /// Saves raw profile data for a user in profile_cache.
  Future<void> saveProfileCache(String userId, Map<String, dynamic> rawData) async {
    try {
      final db = await database;
      await db.insert(
        'profile_cache',
        {
          'userId': userId,
          'raw_json': jsonEncode(rawData),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving profile cache in local DB: $e');
    }
  }

  /// Retrieves raw cached profile data for a user.
  Future<Map<String, dynamic>?> getProfileCache(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'profile_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      if (rows.isNotEmpty) {
        final String? rawJson = rows.first['raw_json']?.toString();
        if (rawJson != null && rawJson.isNotEmpty) {
          return Map<String, dynamic>.from(jsonDecode(rawJson));
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
      return null;
    }
  }

  /// Clears the profile_cache table.
  Future<void> clearProfileCache() async {
    try {
      final db = await database;
      await db.delete('profile_cache');
    } catch (e) {
      debugPrint('Error clearing profile cache database: $e');
    }
  }

  /// Saves the user's selected wallpaper ID and image URL locally.
  Future<void> saveUserWallpaper(String userId, String wallpaperId, String wallpaperImage) async {
    try {
      final db = await database;
      await db.insert(
        'user_wallpaper',
        {
          'user_id': userId,
          'wallpaper_id': wallpaperId,
          'wallpaper_image': wallpaperImage,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving user wallpaper in local DB: $e');
    }
  }

  /// Retrieves the user's selected wallpaper info.
  Future<Map<String, String>?> getUserWallpaper(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'user_wallpaper',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (rows.isNotEmpty) {
        return {
          'wallpaper_id': rows.first['wallpaper_id']?.toString() ?? '',
          'wallpaper_image': rows.first['wallpaper_image']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error getting user wallpaper from local DB: $e');
    }
    return null;
  }

  /// Clears the user_wallpaper table.
  Future<void> clearUserWallpaperCache() async {
    try {
      final db = await database;
      await db.delete('user_wallpaper');
    } catch (e) {
      debugPrint('Error clearing user wallpaper database: $e');
    }
  }

  /// Saves a media URL and its local file path mapping in SQLite.
  Future<void> saveMediaCache(String url, String localPath) async {
    try {
      final db = await database;
      await db.insert(
        'media_cache',
        {
          'url': url,
          'local_path': localPath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving media cache in local DB: $e');
    }
  }

  /// Retrieves the cached local file path for a media URL.
  Future<String?> getMediaCache(String url) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'media_cache',
        where: 'url = ?',
        whereArgs: [url],
      );
      if (rows.isNotEmpty) {
        return rows.first['local_path']?.toString();
      }
    } catch (e) {
      debugPrint('Error getting media cache from local DB: $e');
    }
    return null;
  }

  /// Clears the media_cache table.
  Future<void> clearMediaCache() async {
    try {
      final db = await database;
      await db.delete('media_cache');
    } catch (e) {
      debugPrint('Error clearing media cache database: $e');
    }
  }
}
