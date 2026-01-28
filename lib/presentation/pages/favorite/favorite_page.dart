import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mymusicplayer_new/services/favorites_service.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/presentation/widgets/mini_player.dart';
import '../music_player/music_player_page.dart';

class Favoritepage extends StatelessWidget {
  const Favoritepage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MusicPlayerScreen();
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final _player = GlobalMusicPlayer.instance;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    FavoritesStore.instance.listenable.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FavoritesStore.instance.listenable.removeListener(_refresh);
    super.dispose();
  }

  void _openPlayer(List<Song> songs, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MusicPlayerPage(
          song: songs[index],
          playlist: songs,
          currentIndex: index,
        ),
      ),
    );
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
    final List<Song> songs = FavoritesStore.instance.items;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Favorite Songs',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            songs.isEmpty
                ? Center(
              child: Text(
                "No favorites yet!",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: songs.length,
              itemBuilder: (_, index) {
                final song = songs[index];
                final isPlaying = _player.currentSong?.audioUrl == song.audioUrl &&
                    _player.isPlaying;

                return SongTile(
                  song: song,
                  isPlaying: isPlaying,
                  isDark: isDark,
                  onPlayPause: () => _openPlayer(songs, index),
                  onRemove: () => FavoritesStore.instance.toggle(song),
                );
              },
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onPlayPause;
  final VoidCallback onRemove;

  const SongTile({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.isDark,
    required this.onPlayPause,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(song.imageUrl),
      ),
      title: Text(
        song.title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        song.subtitle,
        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: isDark ? Colors.yellow : Colors.orange,
              size: 28,
            ),
            onPressed: onPlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}