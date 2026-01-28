import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/presentation/pages/music_player/music_player_page.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final _player = GlobalMusicPlayer.instance;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _songChangeSubscription;

  @override
  void initState() {
    super.initState();
    _player.initialize();

    _stateSubscription = _player.onPlayingStateChanged.listen((_) {
      if (mounted) setState(() {});
    });

    _playerStateSubscription =
        _player.audioPlayer.onPlayerStateChanged.listen((state) {
          if (mounted) {
            setState(() {
              _player.isPlaying = state == PlayerState.playing;
            });
          }
        });

    _songChangeSubscription = _player.onSongChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _songChangeSubscription?.cancel();
    super.dispose();
  }

  void _openPlayer() {
    if (_player.currentSong != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MusicPlayerPage(
            song: _player.currentSong!,
            playlist: _player.playlist,
            currentIndex: _player.currentIndex,
          ),
        ),
      );
    }
  }

  void _playPause() async {
    try {
      if (_player.isPlaying) {
        await _player.audioPlayer.pause();
      } else {
        await _player.audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause in mini player: $e');
    }
  }

  Future<void> _playNext() async {
    if (_player.currentIndex < _player.playlist.length - 1) {
      setState(() {
        _player.currentIndex++;
        _player.currentSong = _player.playlist[_player.currentIndex];
      });
      _player.notifySongChanged();

      try {
        await _player.audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        if (_player.currentSong!.audioUrl.isNotEmpty) {
          await _player.playAudio(_player.currentSong!.audioUrl);
        }
      } catch (e) {
        debugPrint('Error playing next in mini player: $e');
      }
    } else {
      await _player.audioPlayer.stop();
      if (mounted) {
        setState(() {
          _player.isPlaying = false;
        });
      }
    }
  }

  Future<void> _playPrevious() async {
    if (_player.currentIndex > 0) {
      setState(() {
        _player.currentIndex--;
        _player.currentSong = _player.playlist[_player.currentIndex];
      });
      _player.notifySongChanged();

      try {
        await _player.audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        if (_player.currentSong!.audioUrl.isNotEmpty) {
          await _player.playAudio(_player.currentSong!.audioUrl);
        }
      } catch (e) {
        debugPrint('Error playing previous in mini player: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_player.currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _openPlayer,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _player.currentSong!.imageUrl.isNotEmpty
                  ? Image.network(
                _player.currentSong!.imageUrl,
                height: 48,
                width: 48,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 48,
                    width: 48,
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _buildMiniPlaceholder(),
              )
                  : _buildMiniPlaceholder(),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _player.currentSong!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _player.currentSong!.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            IconButton(
              icon: Icon(
                Icons.skip_previous,
                color: _player.currentIndex > 0 ? Colors.white : Colors.white38,
                size: 28,
              ),
              onPressed: _player.currentIndex > 0 ? _playPrevious : null,
            ),

            IconButton(
              icon: Icon(
                _player.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _playPause,
            ),

            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: _player.currentIndex < _player.playlist.length - 1
                    ? Colors.white
                    : Colors.white38,
                size: 28,
              ),
              onPressed: _player.currentIndex < _player.playlist.length - 1
                  ? _playNext
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlaceholder() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
    );
  }
}
