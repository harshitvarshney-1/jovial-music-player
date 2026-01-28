import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/services/song_preferences_service.dart';

class GlobalMusicPlayer {
  static final GlobalMusicPlayer instance = GlobalMusicPlayer._();
  GlobalMusicPlayer._();

  AudioPlayer? _audioPlayer;
  Song? currentSong;
  List<Song> playlist = [];
  int currentIndex = 0;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isRepeat = false;
  bool isShuffle = false;
  List<Song> originalPlaylist = [];

  // Song actions state
  Set<String> likedSongs = {};
  Set<String> dislikedSongs = {};
  Set<String> savedSongs = {};
  Map<String, String> downloadedSongs = {};
  Map<String, double> downloadProgress = {};

  bool _isInitialized = false;
  bool _isPlayingOperation = false; // Lock for play operations

  // Stream controllers for state management
  final StreamController<bool> _playingStateController = StreamController<bool>.broadcast();
  final StreamController<Song?> _songChangeController = StreamController<Song?>.broadcast();
  final StreamController<Map<String, dynamic>> _actionStateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get onPlayingStateChanged => _playingStateController.stream;
  Stream<Song?> get onSongChanged => _songChangeController.stream;
  Stream<Map<String, dynamic>> get onActionStateChanged => _actionStateController.stream;

  // Initialize data from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      likedSongs = await SongPreferencesManager.loadLikedSongs();
      dislikedSongs = await SongPreferencesManager.loadDislikedSongs();
      savedSongs = await SongPreferencesManager.loadSavedSongs();
      downloadedSongs = await SongPreferencesManager.loadDownloadedSongs();

      // Cleanup orphaned downloads
      await SongPreferencesManager.cleanupOrphanedDownloads();
      downloadedSongs = await SongPreferencesManager.loadDownloadedSongs();

      // Configure audio player for background playback
      await _configureAudioPlayer();

      // 🎧 Setup Persistent Completion Listener
      audioPlayer.onPlayerComplete.listen((event) async {
        debugPrint('🎼 Global Player: Song completed, handling transition...');
        await handleSongCompletion();
      });

      _isInitialized = true;
      debugPrint('GlobalMusicPlayer initialized with ${likedSongs.length} liked songs');
    } catch (e) {
      debugPrint('Error initializing GlobalMusicPlayer: $e');
    }
  }

  // Configure audio player for background playback
  Future<void> _configureAudioPlayer() async {
    if (kIsWeb) return;
    try {
      final player = audioPlayer;

      // Set audio context for background playback
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      // Set release mode to keep playing in background
      await player.setReleaseMode(ReleaseMode.stop);

      debugPrint('Audio player configured for background playback');
    } catch (e) {
      debugPrint('Error configuring audio player: $e');
    }
  }

  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  void notifyStateChanged() {
    if (!_playingStateController.isClosed) {
      _playingStateController.add(isPlaying);
    }
  }

  void notifySongChanged() {
    if (!_songChangeController.isClosed) {
      _songChangeController.add(currentSong);
    }
  }

  void notifyActionStateChanged() {
    if (!_actionStateController.isClosed && currentSong != null) {
      _actionStateController.add({
        'audioUrl': currentSong!.audioUrl,
        'isLiked': likedSongs.contains(currentSong!.audioUrl),
        'isDisliked': dislikedSongs.contains(currentSong!.audioUrl),
        'isSaved': savedSongs.contains(currentSong!.audioUrl),
        'isDownloaded': downloadedSongs.containsKey(currentSong!.audioUrl),
      });
    }
  }

  // Like song with proper state management
  Future<void> likeSong(String audioUrl) async {
    try {
      likedSongs.add(audioUrl);
      dislikedSongs.remove(audioUrl);
      await Future.wait([
        SongPreferencesManager.saveLikedSongs(likedSongs),
        SongPreferencesManager.saveDislikedSongs(dislikedSongs),
      ]);
      notifyActionStateChanged();
      debugPrint('Song liked: $audioUrl');
    } catch (e) {
      debugPrint('Error liking song: $e');
    }
  }

  // Unlike song
  Future<void> unlikeSong(String audioUrl) async {
    try {
      likedSongs.remove(audioUrl);
      await SongPreferencesManager.saveLikedSongs(likedSongs);
      notifyActionStateChanged();
      debugPrint('Song unliked: $audioUrl');
    } catch (e) {
      debugPrint('Error unliking song: $e');
    }
  }

  // Dislike song
  Future<void> dislikeSong(String audioUrl) async {
    try {
      dislikedSongs.add(audioUrl);
      likedSongs.remove(audioUrl);
      await Future.wait([
        SongPreferencesManager.saveDislikedSongs(dislikedSongs),
        SongPreferencesManager.saveLikedSongs(likedSongs),
      ]);
      notifyActionStateChanged();
      debugPrint('Song disliked: $audioUrl');
    } catch (e) {
      debugPrint('Error disliking song: $e');
    }
  }

  // Remove dislike
  Future<void> removeDislike(String audioUrl) async {
    try {
      dislikedSongs.remove(audioUrl);
      await SongPreferencesManager.saveDislikedSongs(dislikedSongs);
      notifyActionStateChanged();
      debugPrint('Dislike removed: $audioUrl');
    } catch (e) {
      debugPrint('Error removing dislike: $e');
    }
  }

  // Save song
  Future<void> saveSong(String audioUrl) async {
    try {
      savedSongs.add(audioUrl);
      await SongPreferencesManager.saveSavedSongs(savedSongs);
      notifyActionStateChanged();
      debugPrint('Song saved: $audioUrl');
    } catch (e) {
      debugPrint('Error saving song: $e');
    }
  }

  // Unsave song
  Future<void> unsaveSong(String audioUrl) async {
    try {
      savedSongs.remove(audioUrl);
      await SongPreferencesManager.saveSavedSongs(savedSongs);
      notifyActionStateChanged();
      debugPrint('Song unsaved: $audioUrl');
    } catch (e) {
      debugPrint('Error unsaving song: $e');
    }
  }

  // Save downloaded song path
  Future<void> saveDownloadedSong(String audioUrl, String localPath) async {
    try {
      downloadedSongs[audioUrl] = localPath;
      await SongPreferencesManager.saveDownloadedSongs(downloadedSongs);
      notifyActionStateChanged();
      debugPrint('Downloaded song saved: $audioUrl -> $localPath');
    } catch (e) {
      debugPrint('Error saving downloaded song: $e');
    }
  }

  // Remove downloaded song
  Future<void> removeDownloadedSong(String audioUrl) async {
    try {
      downloadedSongs.remove(audioUrl);
      downloadProgress.remove(audioUrl);
      await SongPreferencesManager.saveDownloadedSongs(downloadedSongs);
      notifyActionStateChanged();
      debugPrint('Downloaded song removed: $audioUrl');
    } catch (e) {
      debugPrint('Error removing downloaded song: $e');
    }
  }

  // Helper method to play audio with proper source detection
  Future<bool> playAudio(String audioUrl) async {
    if (audioUrl.isEmpty) {
      debugPrint('Error: Audio URL is empty');
      return false;
    }

    // Prevent concurrent play operations
    if (_isPlayingOperation) {
      debugPrint('Play operation already in progress');
      return false;
    }

    _isPlayingOperation = true;

    try {
      // Check if downloaded version exists
      if (!kIsWeb && downloadedSongs.containsKey(audioUrl)) {
        String localPath = downloadedSongs[audioUrl]!;
        if (await File(localPath).exists()) {
          debugPrint('Playing from local: $localPath');
          await audioPlayer.play(DeviceFileSource(localPath));
          return true;
        } else {
          debugPrint('Downloaded file not found, removing from list');
          await removeDownloadedSong(audioUrl);
        }
      }

      // Validate URL
      if (!_isValidUrl(audioUrl)) {
        debugPrint('Invalid audio URL: $audioUrl');
        return false;
      }

      // Play from network
      debugPrint('Playing from network: $audioUrl');
      if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
        await audioPlayer.play(UrlSource(audioUrl));
      } else if (!kIsWeb) {
        await audioPlayer.play(DeviceFileSource(audioUrl));
      }
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      return false;
    } finally {
      _isPlayingOperation = false;
      notifyStateChanged();
      notifySongChanged();
    }
  }

  // 🔥 SKIP TO NEXT (Used for Background & UI)
  Future<void> skipToNext() async {
    if (playlist.isEmpty) return;

    if (currentIndex < playlist.length - 1) {
      currentIndex++;
    } else {
      // Loop back to start if not repeating single
      currentIndex = 0;
    }

    currentSong = playlist[currentIndex];
    debugPrint('⏭️ Skipping to next: ${currentSong?.title}');

    try {
      await audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      if (currentSong != null) {
        await playAudio(currentSong!.audioUrl);
      }
    } catch (e) {
      debugPrint('Error in skipToNext: $e');
    } finally {
      notifySongChanged();
    }
  }

  // ⏪ SKIP TO PREVIOUS
  Future<void> skipToPrevious() async {
    if (playlist.isEmpty) return;

    if (currentIndex > 0) {
      currentIndex--;
    } else {
      currentIndex = playlist.length - 1;
    }

    currentSong = playlist[currentIndex];
    debugPrint('⏪ Skipping to previous: ${currentSong?.title}');

    try {
      await audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      if (currentSong != null) {
        await playAudio(currentSong!.audioUrl);
      }
    } catch (e) {
      debugPrint('Error in skipToPrevious: $e');
    } finally {
      notifySongChanged();
    }
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        Uri.parse(url);
        return true;
      } catch (e) {
        return false;
      }
    }
    return !kIsWeb && File(url).existsSync();
  }

  void toggleShuffle(Song? currentSong) {
    if (currentSong == null || playlist.isEmpty) return;

    isShuffle = !isShuffle;

    if (isShuffle) {
      originalPlaylist = List.from(playlist);
      int currentSongIndex = playlist.indexWhere((s) => s.audioUrl == currentSong.audioUrl);

      if (currentSongIndex != -1) {
        playlist.removeAt(currentSongIndex);
      }

      playlist.shuffle();

      if (currentSongIndex != -1) {
        playlist.insert(0, currentSong);
      }

      currentIndex = 0;
    } else {
      if (originalPlaylist.isNotEmpty) {
        int originalIndex = originalPlaylist.indexWhere((s) => s.audioUrl == currentSong.audioUrl);
        playlist = List.from(originalPlaylist);
        currentIndex = originalIndex != -1 ? originalIndex : 0;
        originalPlaylist.clear();
      }
    }

    debugPrint('Shuffle toggled: $isShuffle');
  }

  // Handle Song Completion (Background-safe)
  Future<void> handleSongCompletion() async {
    debugPrint('Song completed. Repeat: $isRepeat, Shuffle: $isShuffle');

    if (isRepeat && currentSong != null) {
      debugPrint('Repeating song: ${currentSong!.title}');
      try {
        await audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        await playAudio(currentSong!.audioUrl);
      } catch (e) {
        debugPrint('Error repeating song: $e');
        await skipToNext();
      }
    } else {
      debugPrint('Playing next song');
      await skipToNext();
    }
  }

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _playingStateController.close();
    _songChangeController.close();
    _actionStateController.close();
    debugPrint('GlobalMusicPlayer disposed');
  }
}
