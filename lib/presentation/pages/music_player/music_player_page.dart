import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/services/favorites_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/services/song_preferences_service.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';

// Services are now in lib/services/

// ============================================================================
// MUSIC PLAYER PAGE - Main UI
// ============================================================================
class MusicPlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final int currentIndex;

  const MusicPlayerPage({
    super.key,
    required this.song,
    required this.playlist,
    required this.currentIndex,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> with WidgetsBindingObserver {
  final _player = GlobalMusicPlayer.instance;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _songChangedSubscription;
  StreamSubscription? _actionStateSubscription;
  bool _isLoading = false;

  // Local state for UI
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSaved = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  // Download cancellation
  CancelToken? _downloadCancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');
    // This helps maintain playback during screen off
  }

  Future<void> _initializePlayer() async {
    await _player.initialize();
    _initPlayer();
    await _loadSongState();
    _setupActionListener();
  }

  void _setupActionListener() {
    _actionStateSubscription = _player.onActionStateChanged.listen((state) {
      if (mounted && state['audioUrl'] == widget.song.audioUrl) {
        setState(() {
          _isLiked = state['isLiked'] ?? false;
          _isDisliked = state['isDisliked'] ?? false;
          _isSaved = state['isSaved'] ?? false;
          _isDownloaded = state['isDownloaded'] ?? false;
        });
      }
    });
  }

  Future<void> _loadSongState() async {
    if (!mounted) return;

    try {
      final isLiked = _player.likedSongs.contains(widget.song.audioUrl);
      final isDisliked = _player.dislikedSongs.contains(widget.song.audioUrl);
      final isSaved = _player.savedSongs.contains(widget.song.audioUrl);
      final isDownloaded = _player.downloadedSongs.containsKey(widget.song.audioUrl);

      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isDisliked = isDisliked;
          _isSaved = isSaved;
          _isDownloaded = isDownloaded;
          _downloadProgress = _player.downloadProgress[widget.song.audioUrl] ?? 0.0;
        });
      }

      debugPrint('Song state loaded for: ${widget.song.title}');
    } catch (e) {
      debugPrint('Error loading song state: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelSubscriptions();
    _downloadCancelToken?.cancel();
    super.dispose();
  }

  void _cancelSubscriptions() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _songChangedSubscription?.cancel();
    _actionStateSubscription?.cancel();
  }

  void _initPlayer() async {
    _cancelSubscriptions();

    bool needsToPlayNewSong = _player.currentSong?.audioUrl != widget.song.audioUrl;

    _player.playlist = widget.playlist;
    _player.currentIndex = widget.currentIndex;
    _player.currentSong = widget.song;

    _playerStateSubscription = _player.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _player.isPlaying = state == PlayerState.playing;
          _isLoading = false;
        });
        _player.notifyStateChanged();
      }
    });

    _durationSubscription = _player.audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _player.duration = newDuration;
        });
      }
    });

    _positionSubscription = _player.audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _player.position = newPosition;
        });
      }
    });

    _songChangedSubscription = _player.onSongChanged.listen((newSong) {
      debugPrint('🎵 Song changed notification in UI: ${newSong?.title}');
      if (mounted) {
        _loadSongState();
        setState(() {});
      }
    });

    if (needsToPlayNewSong && widget.song.audioUrl.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _player.audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        bool success = await _player.playAudio(widget.song.audioUrl);
        if (!success && mounted) {
          _showError('Failed to play audio');
        }
      } catch (e) {
        debugPrint('Error initializing player: $e');
        if (mounted) {
          _showError('Error playing song');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }

  // Action Methods
  Future<void> _toggleLike() async {
    try {
      if (_isLiked) {
        await _player.unlikeSong(widget.song.audioUrl);
        _showSuccess('Removed from Liked Songs');
      } else {
        await _player.likeSong(widget.song.audioUrl);
        _showSuccess('Added to Liked Songs');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      _showError('Failed to update like status');
    }
  }

  Future<void> _toggleDislike() async {
    try {
      if (_isDisliked) {
        await _player.removeDislike(widget.song.audioUrl);
        _showSuccess('Dislike Removed');
      } else {
        await _player.dislikeSong(widget.song.audioUrl);
        _showSuccess('Song Disliked');
      }
    } catch (e) {
      debugPrint('Error toggling dislike: $e');
      _showError('Failed to update dislike status');
    }
  }

  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        await _player.unsaveSong(widget.song.audioUrl);
        _showSuccess('Removed from Saved Songs');
      } else {
        await _player.saveSong(widget.song.audioUrl);
        _showSuccess('Added to Saved Songs');
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
      _showError('Failed to update save status');
    }
  }

  Future<void> _shareSong() async {
    try {
      final result = await Share.shareWithResult(
        'Check out this song: ${widget.song.title} by ${widget.song.subtitle}\n${widget.song.audioUrl}',
        subject: widget.song.title,
      );

      if (result.status == ShareResultStatus.success) {
        _showSuccess('Song shared successfully');
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
      _showError('Failed to share song');
    }
  }

  Future<void> _downloadSong() async {
    if (kIsWeb) {
      _showError('Downloads are not supported on Web.');
      return;
    }
    if (_isDownloading) return;

    if (_isDownloaded) {
      _showDeleteDownloadDialog();
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _downloadCancelToken = CancelToken();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      if (kIsWeb) {
        _showError('Downloads are not supported on Web.');
        return;
      }
      final songsDir = Directory('${appDir.path}/songs');

      if (!await songsDir.exists()) {
        await songsDir.create(recursive: true);
      }

      String fileName = widget.song.title.replaceAll(RegExp(r'[^\w\s-]'), '');
      fileName = fileName.replaceAll(' ', '_');
      fileName = '${fileName}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${songsDir.path}/$fileName.mp3';

      Dio dio = Dio();
      await dio.download(
        widget.song.audioUrl,
        filePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
              _player.downloadProgress[widget.song.audioUrl] = _downloadProgress;
            });
          }
        },
      );

      await _player.saveDownloadedSong(widget.song.audioUrl, filePath);

      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Song downloaded successfully!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            action: SnackBarAction(
              label: 'Play',
              onPressed: () async {
                await _player.audioPlayer.stop();
                await _player.playAudio(widget.song.audioUrl);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('Download cancelled');
      } else {
        debugPrint('Download error: $e');
        if (mounted) {
          _showError('Download failed!');
        }
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _showDeleteDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Download', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Do you want to delete this downloaded song?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDownload();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDownload() async {
    try {
      String? localPath = _player.downloadedSongs[widget.song.audioUrl];
      if (localPath != null) {
        if (!kIsWeb) {
          File file = File(localPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        await _player.removeDownloadedSong(widget.song.audioUrl);
      }

      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _downloadProgress = 0.0;
        });
        _showSuccess('Download deleted');
      }
    } catch (e) {
      debugPrint('Error deleting download: $e');
      _showError('Failed to delete download');
    }
  }

// CONTINUATION OF MUSIC PLAYER PAGE

  void _playPause() async {
    try {
      if (_player.isPlaying) {
        await _player.audioPlayer.pause();
      } else {
        await _player.audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
      _showError('Playback error');
    }
  }

  void _seekForward() async {
    try {
      final newPosition = _player.position + const Duration(seconds: 10);
      if (newPosition < _player.duration) {
        await _player.audioPlayer.seek(newPosition);
      } else {
        await _player.audioPlayer.seek(_player.duration);
      }
    } catch (e) {
      debugPrint('Error seeking forward: $e');
    }
  }

  void _seekBackward() async {
    try {
      final newPosition = _player.position - const Duration(seconds: 10);
      if (newPosition > Duration.zero) {
        await _player.audioPlayer.seek(newPosition);
      } else {
        await _player.audioPlayer.seek(Duration.zero);
      }
    } catch (e) {
      debugPrint('Error seeking backward: $e');
    }
  }

  Future<void> _playNext() async {
    setState(() => _isLoading = true);
    await _player.skipToNext();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _playPrevious() async {
    setState(() => _isLoading = true);
    await _player.skipToPrevious();
    if (mounted) setState(() => _isLoading = false);
  }

  void _toggleRepeat() {
    setState(() {
      _player.isRepeat = !_player.isRepeat;
    });
    debugPrint('Repeat toggled: ${_player.isRepeat}');
  }

  void _toggleShuffle() {
    setState(() {
      _player.toggleShuffle(_player.currentSong);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Now Playing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Album Art
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _player.currentSong?.imageUrl.isNotEmpty == true
                                ? Image.network(
                              _player.currentSong!.imageUrl,
                              height: 280,
                              width: 280,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 280,
                                  width: 280,
                                  color: Colors.grey.shade800,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.orange,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderArt();
                              },
                            )
                                : _buildPlaceholderArt(),
                          ),
                          if (_isLoading)
                            Container(
                              height: 280,
                              width: 280,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Song Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            _player.currentSong?.title ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _player.currentSong?.subtitle ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Like Button
                          _buildActionButton(
                            icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            label: _formatCount(_player.likedSongs.length),
                            isActive: _isLiked,
                            onTap: _toggleLike,
                          ),

                          // Dislike Button
                          _buildActionButton(
                            icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                            label: '',
                            isActive: _isDisliked,
                            onTap: _toggleDislike,
                          ),

                          // Save Button
                          _buildActionButton(
                            icon: _isSaved ? Icons.playlist_add_check : Icons.playlist_add,
                            label: 'Save',
                            isActive: _isSaved,
                            onTap: _toggleSave,
                          ),

                          // Share Button
                          _buildActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            isActive: false,
                            onTap: _shareSong,
                          ),

                          // Download Button
                          _buildDownloadButton(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: _player.duration.inSeconds > 0
                                  ? _player.position.inSeconds
                                  .toDouble()
                                  .clamp(0.0, _player.duration.inSeconds.toDouble())
                                  : 0.0,
                              max: _player.duration.inSeconds > 0
                                  ? _player.duration.inSeconds.toDouble()
                                  : 1.0,
                              onChanged: (value) async {
                                try {
                                  await _player.audioPlayer
                                      .seek(Duration(seconds: value.toInt()));
                                } catch (e) {
                                  debugPrint('Error seeking: $e');
                                }
                              },
                              activeColor: Colors.orange,
                              inactiveColor: Colors.white24,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_player.position),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_player.duration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Playback Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.skip_previous,
                              color: _player.currentIndex > 0
                                  ? Colors.white
                                  : Colors.white38,
                              size: 36,
                            ),
                            onPressed:
                            _player.currentIndex > 0 ? _playPrevious : null,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.replay_10,
                                color: Colors.white, size: 32),
                            onPressed: _seekBackward,
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isLoading
                                    ? Icons.hourglass_empty
                                    : (_player.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                                color: Colors.white,
                                size: 38,
                              ),
                              onPressed: _isLoading ? null : _playPause,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.forward_10,
                                color: Colors.white, size: 32),
                            onPressed: _seekForward,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.skip_next,
                              color: _player.currentIndex <
                                  _player.playlist.length - 1
                                  ? Colors.white
                                  : Colors.white38,
                              size: 36,
                            ),
                            onPressed: _player.currentIndex <
                                _player.playlist.length - 1
                                ? _playNext
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Shuffle and Repeat Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _player.isShuffle
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: _player.isShuffle
                                    ? Colors.orange
                                    : Colors.white70,
                                size: 24,
                              ),
                              onPressed: _toggleShuffle,
                              tooltip: _player.isShuffle ? 'Shuffle On' : 'Shuffle Off',
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _player.isRepeat
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _player.isRepeat
                                    ? Icons.repeat_one
                                    : Icons.repeat,
                                color: _player.isRepeat
                                    ? Colors.orange
                                    : Colors.white70,
                                size: 24,
                              ),
                              onPressed: _toggleRepeat,
                              tooltip: _player.isRepeat ? 'Repeat One' : 'Repeat Off',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange : Colors.white70,
              size: 24,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.orange : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 2.5,
              color: Colors.orange,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_downloadProgress * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return _buildActionButton(
      icon: _isDownloaded ? Icons.download_done : Icons.download,
      label: _isDownloaded ? 'Downloaded' : 'Download',
      isActive: _isDownloaded,
      onTap: _downloadSong,
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade600,
          ],
        ),
      ),
      child: const Icon(Icons.music_note, size: 100, color: Colors.white70),
    );
  }
}