import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgres/postgres.dart';
import 'package:ytx/models/ytify_result.dart';
import 'package:ytx/services/storage_service.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref.watch(storageServiceProvider));
});

class CloudSyncService {
  final StorageService _storage;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  
  bool _ignoreChanges = false;
  
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  CloudSyncService(this._storage);

  void _log(String message) {
    print(message);
    _logController.add(message);
  }

  void initBackgroundSync() {
    // Listen to changes and trigger sync
    _storage.historyListenable.addListener(_triggerSync);
    _storage.favoritesListenable.addListener(_triggerSync);
    _storage.playlistsListenable.addListener(_triggerSync);
    _storage.subscriptionsListenable.addListener(_triggerSync);
    
    // Trigger initial sync
    Future.delayed(const Duration(seconds: 2), _triggerSync);
  }

  void _triggerSync() {
    if (_storage.postgresUri == null) return;
    if (_ignoreChanges) return;

    // Debounce: Cancel previous timer and start a new one
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 15), () async {
      if (_isSyncing) return;
      try {
        _log('Auto-Syncing...');
        await syncData();
        _log('Auto-Sync Completed');
      } catch (e) {
        _log('Auto-Sync Failed: $e');
      }
    });
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _ignoreChanges = true;

    final uri = _storage.postgresUri;
    if (uri == null || uri.isEmpty) {
      _isSyncing = false;
      _ignoreChanges = false;
      throw Exception('PostgreSQL URI not configured');
    }

    Connection? conn;
    try {
      // ... (connection logic remains the same)
      var uriString = uri;
      if (uriString.startsWith('postgresql://')) {
        uriString = uriString.replaceFirst('postgresql://', 'postgres://');
      }
      
      final uriObj = Uri.parse(uriString);
      final userInfo = uriObj.userInfo.split(':');
      final username = userInfo.isNotEmpty ? userInfo[0] : null;
      final password = userInfo.length > 1 ? userInfo[1] : null;
      
      // Parse query parameters
      final queryParams = uriObj.queryParameters;
      final sslModeParam = queryParams['sslmode'];
      
      SslMode sslMode = SslMode.disable;
      if (sslModeParam == 'require' || sslModeParam == 'verify-full' || sslModeParam == 'verify-ca') {
        sslMode = SslMode.require;
      }

      final endpoint = Endpoint(
        host: uriObj.host,
        port: uriObj.port != 0 ? uriObj.port : 5432,
        database: uriObj.pathSegments.isNotEmpty ? uriObj.pathSegments[0] : 'postgres',
        username: username,
        password: password,
      );

      _log('Connecting to Postgres: Host=${endpoint.host} Port=${endpoint.port} DB=${endpoint.database} SSL=$sslMode');

      conn = await Connection.open(endpoint, settings: ConnectionSettings(sslMode: sslMode));
    } catch (e) {
      _log('Connection Error: $e');
      _isSyncing = false;
      _ignoreChanges = false;
      rethrow;
    }

    if (conn == null) {
        _isSyncing = false;
        _ignoreChanges = false;
        throw Exception('Could not connect to database');
    }

    try {
      // Check/Create table
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS user_data (
          key TEXT PRIMARY KEY,
          value JSONB,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Sync History
      _log('Syncing History...');
      await _syncItem(
        conn,
        'history',
        () => _storage.getHistory().map((e) => e.toJson()).toList(),
        (json) async {
          final list = (json as List).map((e) => YtifyResult.fromJson(e)).toList();
          await _storage.setHistory(list);
        },
        (local, cloud) {
          final localList = (local as List).map((e) => YtifyResult.fromJson(e)).toList();
          final cloudList = (cloud as List).map((e) => YtifyResult.fromJson(e)).toList();
          return _mergeLists(localList, cloudList).map((e) => e.toJson()).toList();
        },
      );

      // Sync Favorites
      _log('Syncing Favorites...');
      await _syncItem(
        conn,
        'favorites',
        () => _storage.getFavorites().map((e) => e.toJson()).toList(),
        (json) async {
          final list = (json as List).map((e) => YtifyResult.fromJson(e)).toList();
          await _storage.setFavorites(list);
        },
        (local, cloud) {
          final localList = (local as List).map((e) => YtifyResult.fromJson(e)).toList();
          final cloudList = (cloud as List).map((e) => YtifyResult.fromJson(e)).toList();
          return _mergeLists(localList, cloudList).map((e) => e.toJson()).toList();
        },
      );

      // Sync Subscriptions
      _log('Syncing Subscriptions...');
      await _syncItem(
        conn,
        'subscriptions',
        () => _storage.getSubscriptions().map((e) => e.toJson()).toList(),
        (json) async {
          final list = (json as List).map((e) => YtifyResult.fromJson(e)).toList();
          await _storage.setSubscriptions(list);
        },
        (local, cloud) {
          final localList = (local as List).map((e) => YtifyResult.fromJson(e)).toList();
          final cloudList = (cloud as List).map((e) => YtifyResult.fromJson(e)).toList();
          return _mergeLists(localList, cloudList).map((e) => e.toJson()).toList();
        },
      );

      // Sync Playlists
      _log('Syncing Playlists...');
      await _syncItem(
        conn,
        'playlists',
        () {
          final playlists = _storage.getAllPlaylists();
          final jsonMap = <String, dynamic>{};
          for (final entry in playlists.entries) {
            jsonMap[entry.key] = entry.value.map((e) => e.toJson()).toList();
          }
          return jsonMap;
        },
        (json) async {
          final map = Map<String, dynamic>.from(json as Map);
          final playlists = <String, List<YtifyResult>>{};
          for (final entry in map.entries) {
            final list = (entry.value as List).map((e) => YtifyResult.fromJson(e)).toList();
            playlists[entry.key] = list;
          }
          await _storage.setPlaylists(playlists);
        },
        (local, cloud) {
          final localMap = Map<String, dynamic>.from(local as Map);
          final cloudMap = Map<String, dynamic>.from(cloud as Map);
          final mergedMap = <String, dynamic>{};
          
          final allKeys = {...localMap.keys, ...cloudMap.keys};
          for (final key in allKeys) {
            final localList = localMap.containsKey(key) 
                ? (localMap[key] as List).map((e) => YtifyResult.fromJson(e)).toList() 
                : <YtifyResult>[];
            final cloudList = cloudMap.containsKey(key) 
                ? (cloudMap[key] as List).map((e) => YtifyResult.fromJson(e)).toList() 
                : <YtifyResult>[];
            
            mergedMap[key] = _mergeLists(localList, cloudList).map((e) => e.toJson()).toList();
          }
          return mergedMap;
        },
      );
      _log('Sync Completed Successfully');

    } catch (e) {
      _log('Cloud Sync Error: $e');
      rethrow;
    } finally {
      await conn?.close();
      _isSyncing = false;
      _ignoreChanges = false;
    }
  }

  List<YtifyResult> _mergeLists(List<YtifyResult> local, List<YtifyResult> cloud) {
    final Map<String, YtifyResult> merged = {};
    
    // Add cloud items first
    for (var item in cloud) {
      final id = item.videoId ?? item.browseId ?? item.title; // Use title as fallback ID if needed
      if (id != null) merged[id] = item;
    }
    
    // Add/Overwrite with local items (assuming local might be newer, or just union)
    // Actually for a simple union, order doesn't matter much unless we have timestamps.
    // Let's just ensure we have all unique items.
    for (var item in local) {
      final id = item.videoId ?? item.browseId ?? item.title;
      if (id != null) merged[id] = item;
    }
    
    return merged.values.toList();
  }

  Future<void> _syncItem(
    Connection conn,
    String key,
    dynamic Function() getLocalData,
    Future<void> Function(dynamic) setLocalData,
    dynamic Function(dynamic local, dynamic cloud) mergeData,
  ) async {
    // Check if data exists in DB
    final result = await conn.execute(
      Sql.named('SELECT value FROM user_data WHERE key = @key'),
      parameters: {'key': key},
    );

    if (result.isNotEmpty) {
      // Data exists in DB, merge with local
      final row = result.first;
      final cloudValue = row[0];
      
      if (cloudValue != null) {
        final localValue = getLocalData();
        final mergedValue = mergeData(localValue, cloudValue);
        
        // Update Local
        await setLocalData(mergedValue);
        
        // Update Cloud
        await conn.execute(
          Sql.named('UPDATE user_data SET value = @value, updated_at = CURRENT_TIMESTAMP WHERE key = @key'),
          parameters: {'key': key, 'value': TypedValue(Type.jsonb, mergedValue)},
        );
      }
    } else {
      // No data in DB, upload local
      final localData = getLocalData();
      
      await conn.execute(
        Sql.named('INSERT INTO user_data (key, value) VALUES (@key, @value)'),
        parameters: {'key': key, 'value': TypedValue(Type.jsonb, localData)}, // Use TypedValue for explicit JSONB
      );
    }
  }
}
