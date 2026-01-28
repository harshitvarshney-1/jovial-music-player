import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';

/// A persistent store for favorite songs using Firestore.
/// Favorites are saved per user email and synced across all devices.
/// Login on any device with same email = same favorites! 🔥
class FavoritesStore {
  FavoritesStore._();
  static final FavoritesStore instance = FavoritesStore._();

  final Map<String, Song> _map = {};
  final ValueNotifier<int> listenable = ValueNotifier<int>(0);

  List<Song> get items => _map.values.toList(growable: false);

  bool contains(Song song) => _map.containsKey(song.audioUrl);

  /// Initialize and load favorites from Firestore
  Future<void> initialize() async {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in - load their favorites
        loadFavorites();
      } else {
        // User logged out - clear favorites
        _map.clear();
        listenable.value++;
        debugPrint('🚪 User logged out - favorites cleared');
      }
    });

    // Load favorites for current user (if any)
    if (FirebaseAuth.instance.currentUser != null) {
      await loadFavorites();
    }
  }

  /// Load favorites from Firestore for current user
  Future<void> loadFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot load favorites');
        return;
      }

      debugPrint('📥 Loading favorites for user: ${user.email}');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true) // Latest first
          .get();

      _map.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final song = Song(
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          year: data['year'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
        );
        _map[song.audioUrl] = song;
      }

      listenable.value++;
      debugPrint('✅ Loaded ${_map.length} favorites for ${user.email}');
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
    }
  }

  /// Toggle favorite and save to Firestore
  Future<void> toggle(Song song) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot save favorite');
        // Show a message to user to login
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(song.audioUrl.hashCode.toString()); // Use hash as doc ID

      if (contains(song)) {
        // Remove from local map
        _map.remove(song.audioUrl);
        // Remove from Firestore
        await docRef.delete();
        debugPrint('🗑️ Removed from favorites: ${song.title}');
      } else {
        // Add to local map
        _map[song.audioUrl] = song;
        // Save to Firestore
        await docRef.set({
          'title': song.title,
          'subtitle': song.subtitle,
          'year': song.year,
          'imageUrl': song.imageUrl,
          'audioUrl': song.audioUrl,
          'addedAt': FieldValue.serverTimestamp(),
          'userEmail': user.email, // Store email for reference
        });
        debugPrint('❤️ Added to favorites: ${song.title}');
      }

      listenable.value++; // Notify listeners
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
    }
  }

  /// Sync favorites from cloud (useful after login)
  Future<void> syncFromCloud() async {
    debugPrint('🔄 Syncing favorites from cloud...');
    await loadFavorites();
  }

  /// Clear all favorites (for logout or account deletion)
  Future<void> clearAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = FirebaseFirestore.instance.batch();
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .get();

        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('🧹 Cleared all favorites from Firestore');
      }

      _map.clear();
      listenable.value++;
      debugPrint('🧹 Cleared local favorites');
    } catch (e) {
      debugPrint('❌ Error clearing favorites: $e');
    }
  }

  /// Get total count of favorites
  int get count => _map.length;

  /// Check if any favorites exist
  bool get hasFavorites => _map.isNotEmpty;
}