import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/services/favorites_service.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/presentation/widgets/mini_player.dart';
import '../music_player/music_player_page.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  final TextEditingController _controller = TextEditingController();
  final _player = GlobalMusicPlayer.instance;
  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  bool isLoading = true;
  DateTime? _lastBackPressed;

  // Static songs from home page
  static final List<Song> featuredSongs = [
    Song(
      title: "Shararat",
      subtitle: "Song",
      year: "2025",
      imageUrl: "https://tse3.mm.bing.net/th/id/OIP.0cXjpS-R_i8Uh8UjyflXRgHaEK?rs=1&pid=ImgDetMain&o=7&rm=3",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176003/Shararat_wqtopz.mp3",
    ),
    Song(
      title: "Gehra Hua",
      subtitle: "Song",
      year: "2025",
      imageUrl: "https://s.saregama.tech/image/c/m/8/3d/f6/gehra-hua_1440_1764228047.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176002/Gehra_Hua_pomzmx.mp3",
    ),
    Song(
      title: "Hungama Ho Gaya",
      subtitle: "Song",
      year: "2014",
      imageUrl: "https://i.scdn.co/image/ab67616d0000b273c98fe77d9787702c1d56fce0",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176001/Hungama_ho_gya_bpmle9.mp3",
    ),
  ];

  static final List<Song> popularSingers = [
    Song(
      title: "FA9LA(fasla)",
      subtitle: "Song",
      year: "2025",
      imageUrl: "https://images.news18.com/ibnkhabar/uploads/2025/12/akshay-5-2025-12-e7e71e37249558861324a50a144e6b14-16x9.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176002/FA9LA_Fasla_r7pvjy.mp3",
    ),
    Song(
      title: "Aawaara Angaara",
      subtitle: "Song",
      year: "2025",
      imageUrl: "https://tse1.mm.bing.net/th/id/OIP.bZqWFP1wSdJDes6EAKZI7QHaEK?rs=1&pid=ImgDetMain&o=7&rm=3",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176002/Aawaara_Angaara_fsl3tz.mp3",
    ),
    Song(
      title: "Ishq Jalakar",
      subtitle: "Song",
      year: "2025",
      imageUrl: "https://static.sociofyme.com/photo/msid-153202823/153202823.cms?t=1271963",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176002/Ishq_Jalakar_vbs62l.mp3",
    ),
    Song(
      title: "Run Down The City",
      subtitle: "Song",
      year: "2025",
      imageUrl: "https://cdn.apnatube.in/upload/photos/2025/12/zUuiZ2WMGPwXNZEAltCm_28_5d6cafb5bb4695fe20c67f4066e4377d_image.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767176001/Run_Down_The_City_xkd0wg.mp3",
    ),
    Song(
      title: "Yeh Dil Deewana Deewana Haan Hai",
      subtitle: "Song",
      year: "2022",
      imageUrl: "https://i.ytimg.com/vi/hc7W811dRuw/oar2.jpg?sqp=-oaymwEYCNAFENAFSFqQAgHyq4qpAwcIARUAAIhC&rs=AOn4CLCnvBviXyZ0fdZw-Ve88YinuMtSaQ",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1767353543/Yeh_Dil_Deewana_Deewana_Haan_Hai_PagaiWorld.com_j594cw.mp3",
    ),
    Song(
      title: 'Tum Ho Toh',
      subtitle: 'Saiyaara',
      year: '2025',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1coq55KYPnS0iCMJihGPx1IfpdOku4ELzJA&s',
      audioUrl: 'https://res.cloudinary.com/dawjttakh/video/upload/v1752387522/Tum_Ho_Toh_Saiyaara_320_Kbps_it7faa.mp3',
    ),
    Song(
      title: 'Ishq Mein',
      subtitle: 'Nadaaniyan',
      year: '2025',
      imageUrl: 'https://a10.gaanacdn.com/gn_img/albums/Bp1bAnK029/1bANwkGXK0/size_m.jpg',
      audioUrl: 'https://res.cloudinary.com/dawjttakh/video/upload/v1753305736/Ishq_Mein_Nadaaniyan_320_Kbps_ko2g1b.mp3',
    ),
    Song(
      title: 'Haqeeqat',
      subtitle: 'Akhil Sachdeva',
      year: '2025',
      imageUrl: 'https://i.ytimg.com/vi/gmaxofTxvm0/hq720.jpg',
      audioUrl: 'https://res.cloudinary.com/dawjttakh/video/upload/v1752387585/Haqeeqat_Akhil_Sachdeva_320_Kbps_b8m8hs.mp3',
    ),
    Song(
      title: 'Pehla Tu Duja Tu',
      subtitle: 'Son of Sardaar',
      year: '2025',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREZbEZPmJYbKTX2IBVMqZLCxL8AzQrjd9T6w&s',
      audioUrl: 'https://res.cloudinary.com/dawjttakh/video/upload/v1752387677/Pehla_Tu_Duja_Tu_Son_Of_Sardaar_2_320_Kbps_czvarv.mp3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
    FavoritesStore.instance.listenable.addListener(_refresh);
    _player.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });
  }

  // Load all songs from Firestore + static songs
  Future<void> _loadAllSongs() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get songs from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .orderBy('year', descending: true)
          .get();

      final firestoreSongs = snapshot.docs.map((doc) {
        final data = doc.data();
        return Song(
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          year: data['year'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
        );
      }).toList();

      // Combine all songs: static + firestore
      setState(() {
        allSongs = [
          ...featuredSongs,
          ...popularSingers,
          ...firestoreSongs,
        ];
        filteredSongs = allSongs;
        isLoading = false;
      });

      debugPrint('✅ Total songs loaded: ${allSongs.length}');
    } catch (e) {
      debugPrint('❌ Error loading songs: $e');
      setState(() {
        // If Firestore fails, at least show static songs
        allSongs = [...featuredSongs, ...popularSingers];
        filteredSongs = allSongs;
        isLoading = false;
      });
    }
  }

  void _refresh() => setState(() {});

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSongs = allSongs;
      } else {
        filteredSongs = allSongs.where((song) {
          final q = query.toLowerCase();
          return song.title.toLowerCase().contains(q) ||
              song.subtitle.toLowerCase().contains(q) ||
              song.year.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _openMusicPlayer(Song song, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          song: song,
          playlist: filteredSongs,
          currentIndex: index,
        ),
        fullscreenDialog: true,
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
  void dispose() {
    _controller.dispose();
    FavoritesStore.instance.listenable.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final hasActiveSong = _player.currentSong != null;

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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, hasActiveSong ? 85 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    TextField(
                      controller: _controller,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: _filterSongs,
                      decoration: InputDecoration(
                        hintText: "Search songs, artists, year...",
                        hintStyle: TextStyle(color: isDark ? Colors.yellow : Colors.orange),
                        prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: isDark ? Colors.white : Colors.black),
                          onPressed: () {
                            _controller.clear();
                            _filterSongs('');
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Results header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _controller.text.isEmpty
                              ? "All Songs"
                              : "Search Results",
                          style: TextStyle(
                            color: isDark ? Colors.yellow : Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${filteredSongs.length} songs",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Songs list
                    Expanded(
                      child: isLoading
                          ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                        ),
                      )
                          : filteredSongs.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No songs found",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Try searching with different keywords",
                              style: TextStyle(
                                color: isDark ? Colors.white30 : Colors.black38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return MusicTile(
                            song: song,
                            onTap: () => _openMusicPlayer(song, index),
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveSong)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: MiniPlayer(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MusicTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final bool isDark;

  const MusicTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = FavoritesStore.instance.contains(song);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            song.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note, color: Colors.white54),
              );
            },
          ),
        ),
        title: Text(
          song.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${song.subtitle} • ${song.year}",
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : (isDark ? Colors.white60 : Colors.black45),
          ),
          onPressed: () => FavoritesStore.instance.toggle(song),
        ),
      ),
    );
  }
}