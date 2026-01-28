// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 🔔 Request permission first (Android 13+)
    await _requestPermissions();

    // ✅ FIX: Use 'app_icon' instead of '@mipmap/app_icon'
    const androidSettings = AndroidInitializationSettings('app_icon');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );

    // ✅ Create notification channel (CRITICAL for Android 8+)
    await _createNotificationChannel();
  }

  /// Request notification permission (Android 13+)
  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'music_updates', // Must match channelId in notifications
      'Music Updates',
      description: 'Notifications for new music additions',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? true;
  }

  Future<void> showNewMusicNotification({
    required String musicTitle,
    required String artistName,
    int id = 0,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('⏭️ Notifications disabled by user');
      return;
    }

    // ✅ Simple notification without advanced styling
    const androidDetails = AndroidNotificationDetails(
      'music_updates',
      'Music Updates',
      channelDescription: 'Notifications for new music additions',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'app_icon', // ✅ Fixed icon
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      '🎵 New Release: $musicTitle',
      "$artistName's latest track is now available. Listen exclusively on Jovial Music Player!",
      notificationDetails,
    );

    print('✅ Notification shown: $musicTitle by $artistName');
  }

  Future<void> showBulkMusicNotification({
    required int count,
    required List<String> songTitles, // Keep parameter for compatibility
    int id = 1,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('⏭️ Notifications disabled by user');
      return;
    }

    // ✅ Simple notification without InboxStyle
    const androidDetails = AndroidNotificationDetails(
      'music_updates',
      'Music Updates',
      channelDescription: 'Notifications for new music additions',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'app_icon', // ✅ Fixed icon
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      '🎵 New Music Added!',
      '$count new songs have been added to your library',
      notificationDetails,
    );

    print('✅ Bulk notification shown: $count songs');
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Test notification (for debugging)
  Future<void> showTestNotification() async {
    await showNewMusicNotification(
      musicTitle: 'Test Song',
      artistName: 'Test Artist',
    );
  }
}