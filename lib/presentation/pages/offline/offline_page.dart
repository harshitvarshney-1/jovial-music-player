import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/presentation/pages/music_player/music_player_page.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/presentation/widgets/mini_player.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final _player = GlobalMusicPlayer.instance;
  List<SongModel> _offlineSongs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);

    if (kIsWeb) {
      debugPrint('ℹ️ Offline songs query skipped on Web');
      setState(() {
        _offlineSongs = [];
        _isLoading = false;
      });
      return;
    }

    if (!await Permission.audio.isGranted) {
      final status = await Permission.audio.request();
      if (!status.isGranted) {
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      _offlineSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }

    setState(() => _isLoading = false);
  }

  List<SongModel> get _filteredSongs {
    if (_searchQuery.isEmpty) return _offlineSongs;

    return _offlineSongs.where((song) {
      return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (song.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Song _convertToSong(SongModel songModel) {
    return Song(
      title: songModel.title,
      subtitle: songModel.artist ?? 'Unknown Artist',
      year: songModel.dateAdded?.toString() ?? '',
      imageUrl: '',
      audioUrl: songModel.data,
    );
  }

  Future<void> _playSong(SongModel songModel, int index) async {
    try {
      List<Song> playlist = _filteredSongs.map((s) => _convertToSong(s)).toList();
      Song song = _convertToSong(songModel);

      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MusicPlayerPage(
            song: song,
            playlist: playlist,
            currentIndex: index,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error playing song: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing: ${songModel.title}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Offline Songs',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black),
                          onPressed: _loadSongs,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search songs...',
                          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Song Count
                    Text(
                      '${_filteredSongs.length} songs',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Songs List
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                )
                    : _offlineSongs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 80,
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No offline songs found',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadSongs,
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )
                    : _filteredSongs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No songs match "$_searchQuery"',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 100, // Space for mini player
                  ),
                  itemCount: _filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    final isCurrentSong = _player.currentSong?.audioUrl == song.data;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrentSong
                            ? Colors.orange.withOpacity(0.1)
                            : (isDark ? Colors.grey.shade900 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrentSong
                            ? Border.all(color: Colors.orange, width: 1)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCurrentSong && _player.isPlaying
                                ? Icons.equalizer
                                : Icons.music_note,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrentSong ? Colors.orange : (isDark ? Colors.white : Colors.black),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist ?? 'Unknown Artist',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (song.duration != null)
                              Text(
                                _formatDuration(song.duration!),
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.play_circle_filled,
                              color: isCurrentSong ? Colors.orange : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                              size: 28,
                            ),
                          ],
                        ),
                        onTap: () => _playSong(song, index),
                      ),
                    );
                  },
                ),
              ),

              // Mini Player from GlobalMusicPlayer
              const MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}