import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/local_db_service.dart';
import 'package:path/path.dart' as p;

class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  final Dio _dio = Dio();
  final Set<String> _downloadingUrls = {};

  String _normalizeUrl(String url) {
    return ApiService.getImageUrl(url);
  }

  /// Gets the cached file for a network media URL.
  /// If not cached, it triggers background download and returns null immediately
  /// to allow network fallback rendering while saving cache.
  Future<File?> getCachedMedia(String url) async {
    if (url.isEmpty) return null;

    try {
      final normalizedUrl = _normalizeUrl(url);

      // 1. Check SQLite database for cached path
      final String? cachedPath = await LocalDbService().getMediaCache(
        normalizedUrl,
      );
      if (cachedPath != null && cachedPath.isNotEmpty) {
        debugPrint("Cached pathhhhhhhhhhhhhhh: $cachedPath");
        final file = File(cachedPath);
        if (await file.exists()) {
          return file;
        }
      }

      // 2. Not cached: trigger download and cache in the background.
      // We do not await it so the caller can fall back to streaming/loading from network.
      downloadAndCache(normalizedUrl);
      return null;
    } catch (e) {
      debugPrint("Error in getCachedMedia: $e");
      return null;
    }
  }

  /// Downloads the file and saves the path in SQLite cache.
  Future<File?> downloadAndCache(String url) async {
    if (url.isEmpty) return null;

    final normalizedUrl = _normalizeUrl(url);

    if (_downloadingUrls.contains(normalizedUrl)) return null;
    _downloadingUrls.add(normalizedUrl);

    try {
      final absoluteUrl = ApiService.getImageUrl(normalizedUrl);
      final cacheDir = await getTemporaryDirectory();

      // Extract original filename from URL path (excluding query parameters)
      final String pathOnly = Uri.parse(normalizedUrl).path;
      String fileName = pathOnly.split('/').last;
      if (fileName.isEmpty) {
        fileName = "media_${DateTime.now().millisecondsSinceEpoch}";
      }
      final String savePath = p.join(cacheDir.path, fileName);

      await _dio.download(absoluteUrl, savePath);

      final file = File(savePath);
      if (await file.exists()) {
        // Save mapping in SQLite
        await LocalDbService().saveMediaCache(normalizedUrl, savePath);
        return file;
      }
    } catch (e) {
      debugPrint("Failed to download and cache media ($normalizedUrl): $e");
    } finally {
      _downloadingUrls.remove(normalizedUrl);
    }
    return null;
  }

  /// Pre-caches any media messages in a background task
  void precacheMediaFromMessages(List<dynamic> rawMessages) {
    Future.microtask(() {
      for (final raw in rawMessages) {
        if (raw is Map) {
          final type =
              raw['message_type']?.toString() ?? raw['messageType']?.toString();
          if (type == 'image' || type == 'video') {
            final fileUrl =
                raw['file_url']?.toString() ?? raw['fileUrl']?.toString();
            if (fileUrl != null && fileUrl.isNotEmpty) {
              downloadAndCache(fileUrl);
            }
          }
        }
      }
    });
  }
}
