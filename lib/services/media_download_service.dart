import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'chat_service.dart';

/// Media download service for handling secure file downloads with caching
class MediaDownloadService {
  static final MediaDownloadService _instance = MediaDownloadService._internal();
  factory MediaDownloadService() => _instance;
  MediaDownloadService._internal();

  // Download progress callbacks
  final Map<String, ValueNotifier<double>> _downloadProgress = {};
  final Map<String, bool> _downloadCancelled = {};
  
  // Cache management
  final Map<String, File> _fileCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheExpiry = Duration(days: 7);
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB

  /// Download media file from URL
  Future<MediaDownloadResult> downloadMedia({
    required MediaAttachment mediaAttachment,
    bool useCache = true,
    bool showProgress = true,
  }) async {
    final downloadId = _generateDownloadId();
    
    try {
      // Initialize progress tracking
      if (showProgress) {
        _downloadProgress[downloadId] = ValueNotifier<double>(0.0);
        _downloadCancelled[downloadId] = false;
      }

      // Check cache first
      if (useCache) {
        final cachedFile = await _getCachedFile(mediaAttachment.id);
        if (cachedFile != null) {
          return MediaDownloadResult(
            success: true,
            file: cachedFile,
            fromCache: true,
            downloadId: downloadId,
          );
        }
      }

      if (showProgress) _updateProgress(downloadId, 0.1);

      // Download file from server
      final downloadedData = await _downloadFromServer(
        mediaAttachment.fileUrl,
        downloadId,
        showProgress,
      );

      if (showProgress) _updateProgress(downloadId, 0.8);

      // Decrypt if encrypted
      Uint8List finalData = downloadedData;
      if (mediaAttachment.isEncrypted && mediaAttachment.encryptionKey != null) {
        finalData = await _decryptFileData(downloadedData, mediaAttachment.encryptionKey!);
      }

      if (showProgress) _updateProgress(downloadId, 0.9);

      // Save to local storage
      final localFile = await _saveToLocalStorage(
        finalData,
        mediaAttachment.fileName,
        mediaAttachment.id,
      );

      if (showProgress) _updateProgress(downloadId, 1.0);

      // Update cache
      if (useCache) {
        _fileCache[mediaAttachment.id] = localFile;
        _cacheTimestamps[mediaAttachment.id] = DateTime.now();
        await _cleanupCache();
      }

      // Clean up progress tracking
      if (showProgress) {
        _downloadProgress.remove(downloadId);
        _downloadCancelled.remove(downloadId);
      }

      return MediaDownloadResult(
        success: true,
        file: localFile,
        fromCache: false,
        downloadId: downloadId,
        fileSize: finalData.length,
      );

    } catch (e) {
      // Clean up on error
      if (showProgress) {
        _downloadProgress.remove(downloadId);
        _downloadCancelled.remove(downloadId);
      }
      
      return MediaDownloadResult(
        success: false,
        error: 'Download failed: $e',
        downloadId: downloadId,
      );
    }
  }

  /// Download thumbnail separately
  Future<MediaDownloadResult> downloadThumbnail({
    required MediaAttachment mediaAttachment,
    bool useCache = true,
  }) async {
    if (mediaAttachment.thumbnailUrl == null) {
      return MediaDownloadResult(
        success: false,
        error: 'No thumbnail available',
        downloadId: '',
      );
    }

    final thumbnailId = '${mediaAttachment.id}_thumb';
    
    try {
      // Check cache first
      if (useCache) {
        final cachedFile = await _getCachedFile(thumbnailId);
        if (cachedFile != null) {
          return MediaDownloadResult(
            success: true,
            file: cachedFile,
            fromCache: true,
            downloadId: thumbnailId,
          );
        }
      }

      // Download thumbnail from server
      final downloadedData = await _downloadFromServer(
        mediaAttachment.thumbnailUrl!,
        thumbnailId,
        false, // No progress for thumbnails
      );

      // Save to local storage
      final localFile = await _saveToLocalStorage(
        downloadedData,
        'thumb_${mediaAttachment.fileName}',
        thumbnailId,
      );

      // Update cache
      if (useCache) {
        _fileCache[thumbnailId] = localFile;
        _cacheTimestamps[thumbnailId] = DateTime.now();
      }

      return MediaDownloadResult(
        success: true,
        file: localFile,
        fromCache: false,
        downloadId: thumbnailId,
        fileSize: downloadedData.length,
      );

    } catch (e) {
      return MediaDownloadResult(
        success: false,
        error: 'Thumbnail download failed: $e',
        downloadId: thumbnailId,
      );
    }
  }

  /// Download file from server (mock implementation)
  Future<Uint8List> _downloadFromServer(
    String url,
    String downloadId,
    bool showProgress,
  ) async {
    // Mock file data for demonstration
    // In production, use http package or dio for actual downloads
    final random = List<int>.generate(1024 * 100, (i) => i % 256); // 100KB mock data
    final totalSize = random.length;
    int downloaded = 0;
    const int chunkSize = 4 * 1024; // 4KB chunks

    final result = <int>[];
    
    while (downloaded < totalSize && !(showProgress && (_downloadCancelled[downloadId] ?? false))) {
      await Future.delayed(const Duration(milliseconds: 20)); // Simulate network delay
      
      final chunkEnd = (downloaded + chunkSize < totalSize) 
          ? downloaded + chunkSize 
          : totalSize;
      
      result.addAll(random.sublist(downloaded, chunkEnd));
      downloaded = chunkEnd;
      
      if (showProgress) {
        final progress = 0.1 + (downloaded / totalSize) * 0.7;
        _updateProgress(downloadId, progress);
      }
    }
    
    if (showProgress && (_downloadCancelled[downloadId] ?? false)) {
      throw Exception('Download cancelled by user');
    }
    
    return Uint8List.fromList(result);
  }

  /// Decrypt downloaded file data
  Future<Uint8List> _decryptFileData(Uint8List encryptedData, String encryptionKey) async {
    try {
      if (encryptedData.length < 16) {
        throw Exception('Invalid encrypted data');
      }

  final key = encrypt.Key.fromBase64(encryptionKey);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
  // Extract IV (first 16 bytes)
  final iv = encrypt.IV(encryptedData.sublist(0, 16));
      
  // Extract encrypted data (remaining bytes)
  final ciphertext = encryptedData.sublist(16);
  
  final encrypted = encrypt.Encrypted(ciphertext);
  final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('File decryption failed: $e');
    }
  }

  /// Save file to local storage
  Future<File> _saveToLocalStorage(
    Uint8List data,
    String fileName,
    String fileId,
  ) async {
    try {
      final directory = await _getMediaCacheDirectory();
      final filePath = path.join(directory.path, '${fileId}_$fileName');
      final file = File(filePath);
      
      await file.writeAsBytes(data);
      return file;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Get cached file if available and not expired
  Future<File?> _getCachedFile(String fileId) async {
    try {
      final cachedFile = _fileCache[fileId];
      final cacheTime = _cacheTimestamps[fileId];
      
      if (cachedFile != null && cacheTime != null) {
        // Check if cache is expired
        if (DateTime.now().difference(cacheTime) > cacheExpiry) {
          await _removeCachedFile(fileId);
          return null;
        }
        
        // Check if file still exists
        if (await cachedFile.exists()) {
          return cachedFile;
        } else {
          await _removeCachedFile(fileId);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Cache check error: $e');
      return null;
    }
  }

  /// Remove cached file
  Future<void> _removeCachedFile(String fileId) async {
    try {
      final cachedFile = _fileCache[fileId];
      if (cachedFile != null && await cachedFile.exists()) {
        await cachedFile.delete();
      }
      
      _fileCache.remove(fileId);
      _cacheTimestamps.remove(fileId);
    } catch (e) {
      debugPrint('Failed to remove cached file: $e');
    }
  }

  /// Clean up expired cache files
  Future<void> _cleanupCache() async {
    try {
      final now = DateTime.now();
      final expiredIds = <String>[];
      
      for (final entry in _cacheTimestamps.entries) {
        if (now.difference(entry.value) > cacheExpiry) {
          expiredIds.add(entry.key);
        }
      }
      
      for (final id in expiredIds) {
        await _removeCachedFile(id);
      }
      
      // Check total cache size and remove oldest files if needed
      await _enforceMaxCacheSize();
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
    }
  }

  /// Enforce maximum cache size
  Future<void> _enforceMaxCacheSize() async {
    try {
      int totalSize = 0;
      final fileSizes = <String, int>{};
      
      // Calculate total cache size
      for (final entry in _fileCache.entries) {
        final file = entry.value;
        if (await file.exists()) {
          final size = await file.length();
          fileSizes[entry.key] = size;
          totalSize += size;
        }
      }
      
      if (totalSize <= maxCacheSize) return;
      
      // Sort by timestamp (oldest first)
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest files until under size limit
      for (final entry in sortedEntries) {
        if (totalSize <= maxCacheSize) break;
        
        final fileSize = fileSizes[entry.key] ?? 0;
        await _removeCachedFile(entry.key);
        totalSize -= fileSize;
      }
    } catch (e) {
      debugPrint('Cache size enforcement error: $e');
    }
  }

  /// Get media cache directory
  Future<Directory> _getMediaCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'media_cache'));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  /// Update download progress
  void _updateProgress(String downloadId, double progress) {
    _downloadProgress[downloadId]?.value = progress;
  }

  /// Get download progress notifier
  ValueNotifier<double>? getDownloadProgress(String downloadId) {
    return _downloadProgress[downloadId];
  }

  /// Cancel download
  void cancelDownload(String downloadId) {
    _downloadCancelled[downloadId] = true;
  }

  /// Generate unique download ID
  String _generateDownloadId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'download_$timestamp';
  }

  /// Get cache statistics
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      int totalFiles = _fileCache.length;
      int totalSize = 0;
      int validFiles = 0;
      
      for (final file in _fileCache.values) {
        if (await file.exists()) {
          totalSize += await file.length();
          validFiles++;
        }
      }
      
      return CacheStatistics(
        totalFiles: totalFiles,
        validFiles: validFiles,
        totalSizeBytes: totalSize,
        maxSizeBytes: maxCacheSize,
      );
    } catch (e) {
      return CacheStatistics(
        totalFiles: 0,
        validFiles: 0,
        totalSizeBytes: 0,
        maxSizeBytes: maxCacheSize,
      );
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getMediaCacheDirectory();
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      
      _fileCache.clear();
      _cacheTimestamps.clear();
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Pre-download media for better user experience
  Future<void> preloadMedia(List<MediaAttachment> mediaList) async {
    for (final media in mediaList) {
      try {
        // Only preload smaller files (images, thumbnails)
        if (media.fileSize < 5 * 1024 * 1024) { // 5MB limit
          await downloadMedia(
            mediaAttachment: media,
            useCache: true,
            showProgress: false,
          );
        }
        
        // Always preload thumbnails
        if (media.thumbnailUrl != null) {
          await downloadThumbnail(
            mediaAttachment: media,
            useCache: true,
          );
        }
      } catch (e) {
        debugPrint('Preload failed for ${media.fileName}: $e');
      }
    }
  }
}

/// Media download result
class MediaDownloadResult {
  final bool success;
  final File? file;
  final bool fromCache;
  final String? error;
  final String downloadId;
  final int? fileSize;

  MediaDownloadResult({
    required this.success,
    this.file,
    this.fromCache = false,
    this.error,
    required this.downloadId,
    this.fileSize,
  });

  /// Formatted file size
  String? get formattedFileSize {
    if (fileSize == null) return null;
    
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    if (fileSize! < 1024 * 1024 * 1024) return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Cache statistics
class CacheStatistics {
  final int totalFiles;
  final int validFiles;
  final int totalSizeBytes;
  final int maxSizeBytes;

  CacheStatistics({
    required this.totalFiles,
    required this.validFiles,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
  });

  /// Cache usage percentage
  double get usagePercentage {
    if (maxSizeBytes == 0) return 0.0;
    return (totalSizeBytes / maxSizeBytes) * 100;
  }

  /// Formatted total size
  String get formattedTotalSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (totalSizeBytes < 1024 * 1024 * 1024) return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Formatted max size
  String get formattedMaxSize {
    if (maxSizeBytes < 1024) return '$maxSizeBytes B';
    if (maxSizeBytes < 1024 * 1024) return '${(maxSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (maxSizeBytes < 1024 * 1024 * 1024) return '${(maxSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(maxSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}