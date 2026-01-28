import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ✅ Background task entry point
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 Background task started: $task');

    try {
      // Check for new music
      final hasNewMusic = await _checkForNewMusicInBackground();

      if (hasNewMusic) {
        print('✅ Background task completed - New music found!');
      } else {
        print('✅ Background task completed - No new music');
      }

      return Future.value(true);
    } catch (e) {
      print('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

// ✅ Initialize notification service in background
Future<void> _initializeNotifications() async {
  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('app_icon');
  const initSettings = InitializationSettings(android: androidSettings);

  await notifications.initialize(initSettings);

  const androidChannel = AndroidNotificationChannel(
    'music_updates',
    'Music Updates',
    description: 'Notifications for new music additions',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  print('✅ Notifications initialized in background');
}

// ✅ Background music check function - RETURNS BOOL
Future<bool> _checkForNewMusicInBackground() async {
  try {
    print('🎵 Background: Checking for new music...');

    final prefs = await SharedPreferences.getInstance();

    // ✅ FIX: Check if notifications are enabled
    final notificationsEnabled = prefs.getBool('notifications') ?? true;
    if (!notificationsEnabled) {
      print('⏭️ Notifications disabled by user - skipping check');
      return false;
    }

    final lastCheckMillis = prefs.getInt('last_music_check_millis');
    print('📅 Last check (millis): $lastCheckMillis');

    // ✅ FIRESTORE QUERY: Get songs added after last check
    Query query = FirebaseFirestore.instance
        .collection('songs')
        .orderBy('createdAt', descending: false);

    if (lastCheckMillis != null) {
      final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
      query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(lastCheckDate));
    }

    print('🌐 Calling Firestore API...');
    final snapshot = await query.get();
    
    final List<Map<String, dynamic>> newMusic = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title'] ?? 'Unknown Title';
      final artist = data['subtitle'] ?? 'Unknown Artist';
      final createdAt = data['createdAt'] as Timestamp?;

      if (createdAt != null) {
        newMusic.add({
          'title': title,
          'artist': artist,
          'created_at': createdAt.toDate().toIso8601String(),
        });
        print('🆕 New song: $title by $artist');
      }
    }

    print('✅ Total new songs: ${newMusic.length}');

    // ✅ Send notification if new music found AND not first run
    if (newMusic.isNotEmpty && lastCheckMillis != null) {
      print('🔔 Sending notification for ${newMusic.length} songs');
      await _initializeNotifications();
      await _sendBackgroundNotification(newMusic);

      // ✅ Update last check time
      await prefs.setInt('last_music_check_millis', DateTime.now().millisecondsSinceEpoch);
      return true;
    } else if (lastCheckMillis == null) {
      print('⏭️ First run - setting initial check time, no notification');
      await prefs.setInt('last_music_check_millis', DateTime.now().millisecondsSinceEpoch);
      return false;
    } else {
      print('ℹ️ No new songs found');
      // Update check time anyway
      await prefs.setInt('last_music_check_millis', DateTime.now().millisecondsSinceEpoch);
      return false;
    }

  } catch (e) {
    print('❌ Background check error: $e');
    return false;
  }
}

// ✅ Send notification from background - IMPROVED
Future<void> _sendBackgroundNotification(
    List<Map<String, dynamic>> newMusic) async {
  try {
    print('📲 Creating notification...');

    final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

    // ✅ FIX: Use correct icon name
    const androidSettings = AndroidInitializationSettings('app_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);

    // Create channel
    const androidChannel = AndroidNotificationChannel(
      'music_updates',
      'Music Updates',
      description: 'Notifications for new music additions',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // ✅ FIX: Better notification styling
    if (newMusic.length == 1) {
      print('📲 Sending single song notification');

      final androidDetails = AndroidNotificationDetails(
        'music_updates',
        'Music Updates',
        channelDescription: 'Notifications for new music additions',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'app_icon', // ✅ Fixed icon
        playSound: true,
        enableVibration: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          "${newMusic[0]['artist']}'s latest track is now available. Listen exclusively on Jovial Music Player!",
          contentTitle: '🎵 New Release: ${newMusic[0]['title']}',
        ),
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
        '🎵 New Release: ${newMusic[0]['title']}',
        "${newMusic[0]['artist']}'s latest track is now available. Listen exclusively on Jovial Music Player!",
        notificationDetails,
      );

      print('✅ Single notification sent: ${newMusic[0]['title']}');
    } else {
      print('📲 Sending bulk notification with song list');

      // ✅ Create song list for expandable notification
      final songList = newMusic
          .take(5)
          .map((song) => '♪ ${song['title']} - ${song['artist']}')
          .toList();

      final inboxStyle = InboxStyleInformation(
        songList,
        contentTitle: '🎵 New Music Added!',
        summaryText: '${newMusic.length} new tracks are now available',
      );

      final androidDetails = AndroidNotificationDetails(
        'music_updates',
        'Music Updates',
        channelDescription: 'Notifications for new music additions',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'app_icon', // ✅ Fixed icon
        playSound: true,
        enableVibration: true,
        showWhen: true,
        styleInformation: inboxStyle, // ✅ Show song list
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
        '🎵 New Music Added!',
        '${newMusic.length} new tracks have been added for you',
        notificationDetails,
      );

      print('✅ Bulk notification sent: ${newMusic.length} songs');
    }
  } catch (e) {
    print('❌ Notification error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}

// ✅ Background Music Check Manager
class BackgroundMusicCheck {
  static Future<void> initialize() async {
    print('🔧 Initializing WorkManager...');

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // ✅ Set to false to disable debug notifications
    );

    // ✅ Clean up old tasks before registering new ones (prevents ghost notifications)
    await Workmanager().cancelAll();

    // ✅ Register periodic task (15 minutes minimum)
    await Workmanager().registerPeriodicTask(
      'music-check-task',
      'checkNewMusic',
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1), // ✅ First check after 1 minute
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 1),
    );

    print('✅ WorkManager registered (checks every 15 minutes)');
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('🛑 All background tasks cancelled');
  }
}