// lib/services/cloudinary_music_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

class CloudinaryMusicService {
  final String cloudName;
  final String apiKey;
  final String apiSecret;

  final NotificationService _notificationService = NotificationService();

  CloudinaryMusicService({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
  });

  /// Fetch new music from Cloudinary
  Future<List<Map<String, dynamic>>> fetchNewMusic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString('last_music_check');

      debugPrint('📅 Last check time: $lastCheck');
      debugPrint('🔍 Fetching music from Cloudinary...');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/resources/audio?max_results=100',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization':
          'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Cloudinary API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final List resources = data['resources'] ?? [];
      debugPrint('📦 Total resources found: ${resources.length}');

      final List<Map<String, dynamic>> newMusic = [];

      for (final resource in resources) {
        final createdAt = resource['created_at'];
        if (createdAt == null) continue;

        final songCreatedTime = DateTime.parse(createdAt);

        // ✅ Check if song is new (added after last check)
        if (lastCheck == null ||
            songCreatedTime.isAfter(DateTime.parse(lastCheck))) {
          final title = _extractTitle(resource);
          final artist = _extractArtist(resource);

          debugPrint(
              '🆕 New song found: $title by $artist (created: $createdAt)');

          newMusic.add({
            'title': title,
            'artist': artist,
            'url': resource['secure_url'],
            'duration': resource['duration'] ?? 0,
            'format': resource['format'] ?? '',
            'created_at': createdAt,
          });
        }
      }

      debugPrint('✅ Total new songs: ${newMusic.length}');

      // ✅ FIX: Only send notification if NOT first run AND there are new songs
      if (newMusic.isNotEmpty && lastCheck != null) {
        debugPrint('🔔 Sending notification for ${newMusic.length} new songs');
        await _notifyNewMusic(newMusic);
      } else if (newMusic.isNotEmpty && lastCheck == null) {
        debugPrint('⏭️ First run detected, skipping notification');
      } else {
        debugPrint('ℹ️ No new songs to notify');
      }

      // ✅ Update last check time AFTER checking
      final now = DateTime.now().toIso8601String();
      await prefs.setString('last_music_check', now);
      debugPrint('💾 Updated last check time to: $now');

      return newMusic;
    } catch (e) {
      debugPrint('❌ Cloudinary fetch error: $e');
      return [];
    }
  }

  /// Extract clean song title
  String _extractTitle(Map resource) {
    final publicId = resource['public_id']?.toString() ?? 'Unknown';
    return publicId.split('/').last.replaceAll('_', ' ');
  }

  /// Extract artist from metadata
  String _extractArtist(Map resource) {
    return resource['context']?['custom']?['artist'] ?? 'Unknown Artist';
  }

  /// Send notification - IMPROVED
  Future<void> _notifyNewMusic(List<Map<String, dynamic>> newMusic) async {
    try {
      if (newMusic.length == 1) {
        debugPrint('📲 Showing single notification...');
        await _notificationService.showNewMusicNotification(
          musicTitle: newMusic[0]['title'],
          artistName: newMusic[0]['artist'],
        );
        debugPrint('✅ Single notification sent');
      } else {
        debugPrint('📲 Showing bulk notification...');

        // ✅ Create song titles list for expandable notification
        final songTitles = newMusic
            .map((song) => '♪ ${song['title']} - ${song['artist']}')
            .toList();

        await _notificationService.showBulkMusicNotification(
          count: newMusic.length,
          songTitles: songTitles, // ✅ Pass song list
        );
        debugPrint('✅ Bulk notification sent');
      }
    } catch (e) {
      debugPrint('❌ Notification error: $e');
    }
  }

  /// Public method (called from Homepage)
  Future<void> checkForNewMusic() async {
    debugPrint('🎵 Starting new music check...');
    await fetchNewMusic();
    debugPrint('🎵 New music check completed');
  }

  /// Reset last check (for testing)
  Future<void> resetLastCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_music_check');
    debugPrint('🔄 Last check time reset');
  }
}