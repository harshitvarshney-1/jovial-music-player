import 'package:mymusicplayer_new/presentation/pages/intro/get_started_page.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/register_page.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/signin_page.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/signup_or_signin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:mymusicplayer_new/presentation/pages/favorite/favorite_page.dart';
import 'package:mymusicplayer_new/services/favorites_service.dart';
import 'package:mymusicplayer_new/presentation/pages/offline/offline_page.dart';
import 'package:mymusicplayer_new/firebase_options.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mymusicplayer_new/core/service_locator.dart';

import 'package:mymusicplayer_new/presentation/pages/splash/splash_page.dart';
import 'package:mymusicplayer_new/presentation/pages/home/home_page.dart';
import 'package:mymusicplayer_new/presentation/pages/search/search_page.dart';
import 'package:mymusicplayer_new/presentation/pages/profile/profile_page.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';
import 'package:mymusicplayer_new/services/notification_service.dart';
import 'package:mymusicplayer_new/services/background_music_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mymusicplayer_new/presentation/pages/admin/admin_dashboard.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification != null) {
    // Show notification even when app is in background/terminated
    await NotificationService().initialize(); // Re-init in background isolate if needed
    await NotificationService().showNewMusicNotification(
      musicTitle:
          message.notification!.title?.replaceFirst('🎵 New Release: ', '') ??
              'Unknown Track',
      artistName: message.data['artist'] ?? 'New Artist',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hydrated Storage
  final storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
        (await getApplicationDocumentsDirectory()).path),
  );
  HydratedBloc.storage = storage;

  // 1️⃣ Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialized');

  // 2️⃣ Initialize FavoritesStore (IMPORTANT for permanent favorites!)
  await FavoritesStore.instance.initialize();
  debugPrint('✅ FavoritesStore initialized - favorites will sync with cloud');

  // Initialize other dependencies
  await initializeDependencies();

  // Initialize Notification Service
  if (!kIsWeb) {
    await NotificationService().initialize();
    debugPrint('✅ Notification Service initialized');

    // Initialize Background Music Check
    await BackgroundMusicCheck.initialize();
    debugPrint('✅ Background Music Check initialized');

    // 📩 Initialize Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;

    // Request permissions for iOS/Android 13+
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get the token (for debugging/targeted notifications)
    messaging.getToken().then((token) {
      debugPrint('🔥 FCM Token: $token');
    });

    // 📣 Subscribe to music updates topic
    messaging.subscribeToTopic('music_updates');
    debugPrint('📣 Subscribed to music_updates topic');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        NotificationService().showNewMusicNotification(
          musicTitle: message.notification!.title?.replaceFirst('🎵 New Release: ', '') ?? 'Unknown Track',
          artistName: 'New Artist', // Ideally passed in data
        );
      }
    });
  } else {
    debugPrint('ℹ️ Skipping mobile services (Notification/Background) on Web');
  }

  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MusicPlayerApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MusicPlayerApp extends StatelessWidget {
  final bool isLoggedIn;
  const MusicPlayerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn ? const PlayerPage() : const SplashPage(),
      routes: {
        '/getStarted': (context) => const GetStartedPage(),
        '/signupOrsignin': (context) => const SignupOrSignin(),
        '/signup': (context) => const SignupPage(),
        '/signin': (context) => const SigninPage(),
        '/userHome': (context) => const PlayerPage(),
        '/adminDashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  int _currentIndex = 2;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      Favoritepage(),
      Searchpage(),
      Homepage(),
      OfflinePage(),
      ProfilePage(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    GlobalMusicPlayer.instance.audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: isDark ? Colors.black : Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: isDark ? Colors.white70 : Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "Offline",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}