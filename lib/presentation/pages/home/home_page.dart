import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mymusicplayer_new/data/models/auth/song_model.dart';
import 'package:mymusicplayer_new/services/favorites_service.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';
import 'package:mymusicplayer_new/services/cloudinary_music_service.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import '../music_player/music_player_page.dart';
import 'package:mymusicplayer_new/presentation/widgets/mini_player.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _player = GlobalMusicPlayer.instance;
  DateTime? _lastBackPressed;

  late PageController _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  List<Song> _currentCarouselSongs = [];
  List<Song> _cachedLatestSongs = [];

  final CloudinaryMusicService _cloudinaryService = CloudinaryMusicService(
    cloudName: 'dti0b5pna',
    apiKey: '456758953885916',
    apiSecret: '8ZJUT7GEf6HwDPpCawbBB04DABw',
  );

  @override
  void initState() {
    super.initState();

    _carouselController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
    );

    FavoritesStore.instance.listenable.addListener(_onFavChanged);
    _player.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });

    _checkForNewMusic();

    _currentCarouselSongs = [...featuredSongs, ...popularSingers];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentCarouselSongs.isNotEmpty) {
        _startCarouselTimer();
      }
    });
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();

    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_carouselController.hasClients && _currentCarouselSongs.isNotEmpty) {
        int nextIndex = (_currentCarouselIndex + 1) % _currentCarouselSongs.length;

        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        ).then((_) {
          if (mounted) {
            setState(() {
              _currentCarouselIndex = nextIndex;
            });
          }
        });
      }
    });
  }

  void _onFavChanged() => setState(() {});

  Future<void> _checkForNewMusic() async {
    try {
      await _cloudinaryService.checkForNewMusic();
    } catch (e) {
      debugPrint('❌ Error checking new music: $e');
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
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    FavoritesStore.instance.listenable.removeListener(_onFavChanged);
    super.dispose();
  }

  void _openMusicPlayer(Song song, List<Song> playlist, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          song: song,
          playlist: playlist,
          currentIndex: index,
        ),
        fullscreenDialog: true,
      ),
    );
  }

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
  ];

  static final List<Song> bollywoodHits = [
    Song(
      title: "Apna Bana Le",
      subtitle: "Arijit Singh • Bhediya",
      year: "2022",
      imageUrl: "https://c.saavncdn.com/191/Bhediya-Hindi-2022-20221122051001-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517000/bollywood/apna_bana_le.mp3",
    ),
    Song(
      title: "Kesariya",
      subtitle: "Arijit Singh • Brahmastra",
      year: "2022",
      imageUrl: "https://c.saavncdn.com/191/Kesariya-From-Brahmastra-Hindi-2022-20220717084852-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517001/bollywood/kesariya.mp3",
    ),
    Song(
      title: "Phir Aur Kya Chahiye",
      subtitle: "Arijit Singh • Zara Hatke Zara Bachke",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/300/Zara-Hatke-Zara-Bachke-Hindi-2023-20230531151011-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517002/bollywood/phir_aur.mp3",
    ),
    Song(
      title: "Tum Kya Mile",
      subtitle: "Arijit Singh, Shreya Ghoshal • Rocky Aur Rani",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/085/Rocky-Aur-Rani-Kii-Prem-Kahaani-Hindi-2023-20230711101459-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517003/bollywood/tum_kya_mile.mp3",
    ),
    Song(
      title: "Maan Meri Jaan",
      subtitle: "King",
      year: "2022",
      imageUrl: "https://c.saavncdn.com/734/Champagne-Talk-Hindi-2022-20221008011951-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517004/bollywood/maan_meri_jaan.mp3",
    ),
    Song(
      title: "Kahani Suno 2.0",
      subtitle: "Kaifi Khalil",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/973/Kahani-Suno-2-0-Hindi-2023-20230426191001-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517005/bollywood/kahani_suno.mp3",
    ),
    Song(
      title: "O Bedardeya",
      subtitle: "Arijit Singh • Tu Jhoothi Main Makkaar",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/355/Tu-Jhoothi-Main-Makkaar-Hindi-2023-20230301161056-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517006/bollywood/bedardeya.mp3",
    ),
    Song(
      title: "Arjan Vailly",
      subtitle: "Bhupinder Babbal • Animal",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/406/Animal-Hindi-2023-20231124191036-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517007/bollywood/arjan_vailly.mp3",
    ),
    Song(
      title: "Satranga",
      subtitle: "Arijit Singh • Animal",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/406/Animal-Hindi-2023-20231124191036-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517008/bollywood/satranga.mp3",
    ),
    Song(
      title: "Chaleya",
      subtitle: "Arijit Singh, Shilpa Rao • Jawan",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/088/Jawan-Hindi-2023-20230828135839-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517009/bollywood/chaleya.mp3",
    ),
    Song(
      title: "Ve Kamleya",
      subtitle: "Arijit Singh, Shreya Ghoshal • Rocky Aur Rani",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/085/Rocky-Aur-Rani-Kii-Prem-Kahaani-Hindi-2023-20230711101459-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517010/bollywood/ve_kamleya.mp3",
    ),
    Song(
      title: "Tere Vaaste",
      subtitle: "Varun Jain, Sachin-Jigar • Zara Hatke Zara Bachke",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/300/Zara-Hatke-Zara-Bachke-Hindi-2023-20230531151011-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517011/bollywood/tere_vaaste.mp3",
    ),
    Song(
      title: "Besharam Rang",
      subtitle: "Shilpa Rao, Caralisa • Pathaan",
      year: "2022",
      imageUrl: "https://c.saavncdn.com/191/Pathaan-Hindi-2023-20230112151003-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517012/bollywood/besharam_rang.mp3",
    ),
    Song(
      title: "Jhoome Jo Pathaan",
      subtitle: "Arijit Singh, Sukriti Kakar • Pathaan",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/191/Pathaan-Hindi-2023-20230112151003-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517013/bollywood/jhoome_jo_pathaan.mp3",
    ),
    Song(
      title: "Hua Main",
      subtitle: "Raghav • Animal",
      year: "2023",
      imageUrl: "https://c.saavncdn.com/406/Animal-Hindi-2023-20231124191036-500x500.jpg",
      audioUrl: "https://res.cloudinary.com/dti0b5pna/video/upload/v1736517014/bollywood/hua_main.mp3",
    ),
  ];

  Stream<List<Song>> getLatestSongsFromFirestore() {
    return FirebaseFirestore.instance
        .collection('songs')
        .orderBy('year', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return Song(
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          year: data['year'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
        );
      }).toList(),
    );
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
        backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
        body: RefreshIndicator(
          onRefresh: () async {
            await _checkForNewMusic();
          },
          color: Colors.orange,
          child: SafeArea(
            child: Stack(
              children: [
                StreamBuilder<List<Song>>(
                  stream: getLatestSongsFromFirestore(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      _cachedLatestSongs = snapshot.data!;
                    }

                    final latestSongs = _cachedLatestSongs;
                    final allSongs = [...featuredSongs, ...popularSingers, ...latestSongs];

                    if (allSongs.isNotEmpty && allSongs.length != _currentCarouselSongs.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _currentCarouselSongs = allSongs;
                          if (_currentCarouselIndex >= _currentCarouselSongs.length) {
                            _currentCarouselIndex = 0;
                          }
                          _startCarouselTimer();
                        }
                      });
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: hasActiveSong ? 125 : 60,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Auto-swipe carousel
                          _buildAutoCarousel(allSongs, isDark),

                          const SizedBox(height: 16),

                          // Trending Now
                          _buildSectionHeader("🔥 Trending Now", isDark),
                          _buildModernHorizontalRow(featuredSongs, isDark),

                          const SizedBox(height: 16),

                          // Popular Artists
                          _buildSectionHeader("⭐ Popular Artists", isDark),
                          _buildModernGrid(popularSingers, isDark),

                          const SizedBox(height: 16),

                          // Latest Releases
                          _buildSectionHeader("🆕 Latest Releases", isDark),
                          if (snapshot.connectionState == ConnectionState.waiting && _cachedLatestSongs.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Colors.orange),
                              ),
                            )
                          else if (latestSongs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                "No latest songs yet",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            _buildLatestSongsGrid(latestSongs, isDark),

                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
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
      ),
    );
  }

  Widget _buildAutoCarousel(List<Song> songs, bool isDark) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _carouselController,
            itemCount: songs.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final song = songs[index];
              return GestureDetector(
                onTap: () => _openMusicPlayer(song, songs, index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          song.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, size: 60, color: Colors.white54),
                            );
                          },
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.subtitle,
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
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                songs.length > 10 ? 10 : songs.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentCarouselIndex == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentCarouselIndex == index
                        ? Colors.orange
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: isDark ? Colors.orange : Colors.deepOrange,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildModernHorizontalRow(List<Song> songs, bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isFav = FavoritesStore.instance.contains(song);

          return GestureDetector(
            onTap: () => _openMusicPlayer(song, songs, index),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            song.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note, size: 35, color: Colors.white54),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 14,
                            ),
                            onPressed: () => FavoritesStore.instance.toggle(song),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 110,
                    child: Text(
                      song.title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.year,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernGrid(List<Song> songs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: songs.map((song) {
          final isFav = FavoritesStore.instance.contains(song);
          final index = songs.indexOf(song);

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
              onTap: () => _openMusicPlayer(song, songs, index),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, size: 24, color: Colors.white54),
                      );
                    },
                  ),
                ),
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : (isDark ? Colors.white60 : Colors.black45),
                  size: 20,
                ),
                onPressed: () => FavoritesStore.instance.toggle(song),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLatestSongsGrid(List<Song> songs, bool isDark) {
    List<List<Song>> rows = [];
    for (int i = 0; i < songs.length; i += 6) {
      rows.add(songs.sublist(i, i + 6 > songs.length ? songs.length : i + 6));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: rows.map((rowSongs) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: rowSongs.map((song) {
                  final isFav = FavoritesStore.instance.contains(song);
                  final index = songs.indexOf(song);

                  return GestureDetector(
                    onTap: () => _openMusicPlayer(song, songs, index),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    song.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 35,
                                          color: Colors.white54,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      color: isFav ? Colors.red : Colors.white,
                                      size: 14,
                                    ),
                                    onPressed: () => FavoritesStore.instance.toggle(song),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 110,
                            child: Text(
                              song.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.year,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}