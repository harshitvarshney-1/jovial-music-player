import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SongPreferencesManager {
  static const String _likedSongsKey = 'liked_songs';
  static const String _dislikedSongsKey = 'disliked_songs';
  static const String _savedSongsKey = 'saved_songs';
  static const String _downloadedSongsKey = 'downloaded_songs';

  static SharedPreferences? _prefsInstance;

  static Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  static Future<bool> saveLikedSongs(Set<String> likedSongs) async {
    try {
      final prefs = await _prefs;
      return await prefs.setStringList(_likedSongsKey, likedSongs.toList());
    } catch (e) {
      debugPrint('Error saving liked songs: $e');
      return false;
    }
  }

  static Future<Set<String>> loadLikedSongs() async {
    try {
      final prefs = await _prefs;
      final list = prefs.getStringList(_likedSongsKey) ?? [];
      return list.toSet();
    } catch (e) {
      debugPrint('Error loading liked songs: $e');
      return {};
    }
  }

  static Future<bool> saveDislikedSongs(Set<String> dislikedSongs) async {
    try {
      final prefs = await _prefs;
      return await prefs.setStringList(_dislikedSongsKey, dislikedSongs.toList());
    } catch (e) {
      debugPrint('Error saving disliked songs: $e');
      return false;
    }
  }

  static Future<Set<String>> loadDislikedSongs() async {
    try {
      final prefs = await _prefs;
      final list = prefs.getStringList(_dislikedSongsKey) ?? [];
      return list.toSet();
    } catch (e) {
      debugPrint('Error loading disliked songs: $e');
      return {};
    }
  }

  static Future<bool> saveSavedSongs(Set<String> savedSongs) async {
    try {
      final prefs = await _prefs;
      return await prefs.setStringList(_savedSongsKey, savedSongs.toList());
    } catch (e) {
      debugPrint('Error saving saved songs: $e');
      return false;
    }
  }

  static Future<Set<String>> loadSavedSongs() async {
    try {
      final prefs = await _prefs;
      final list = prefs.getStringList(_savedSongsKey) ?? [];
      return list.toSet();
    } catch (e) {
      debugPrint('Error loading saved songs: $e');
      return {};
    }
  }

  static Future<bool> saveDownloadedSongs(Map<String, String> downloadedSongs) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(_downloadedSongsKey, jsonEncode(downloadedSongs));
    } catch (e) {
      debugPrint('Error saving downloaded songs: $e');
      return false;
    }
  }

  static Future<Map<String, String>> loadDownloadedSongs() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(_downloadedSongsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
      return {};
    } catch (e) {
      debugPrint('Error loading downloaded songs: $e');
      return {};
    }
  }

  static Future<void> cleanupOrphanedDownloads() async {
    if (kIsWeb) return;
    try {
      final downloads = await loadDownloadedSongs();
      final Map<String, String> validDownloads = {};

      for (var entry in downloads.entries) {
        if (await File(entry.value).exists()) {
          validDownloads[entry.key] = entry.value;
        }
      }

      if (validDownloads.length != downloads.length) {
        await saveDownloadedSongs(validDownloads);
        debugPrint('Cleaned up ${downloads.length - validDownloads.length} orphaned downloads');
      }
    } catch (e) {
      debugPrint('Error cleaning up downloads: $e');
    }
  }
}
