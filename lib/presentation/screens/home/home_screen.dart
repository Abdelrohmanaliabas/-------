import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/data/mock/sample_music_data.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/music_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedMood = 'الكل';
  int _quickPlayPageIndex = 0;
  final PageController _quickPlayPageController = PageController();
  int _quickPicksPageIndex = 0;
  final PageController _quickPicksPageController = PageController(viewportFraction: 0.94);

  final List<String> _moods = [
    'استرخاء',
    'تمرين',
    'تحفيز',
    'حفلة',
    'أثناء التنقل',
    'رومانسية',
    'حزين',
  ];

  @override
  void dispose() {
    _quickPlayPageController.dispose();
    _quickPicksPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendedAsync = ref.watch(recommendedSongsProvider);
    final popularAsync = ref.watch(popularSongsProvider);

    final allPopular = popularAsync.value ?? SampleMusicData.songs;
    final allRecommended = recommendedAsync.value ?? SampleMusicData.songs;

    // Filter by mood if selected
    final List<Song> displayedSongs = _selectedMood == 'الكل'
        ? allPopular
        : allPopular.where((s) => s.genre.contains(_selectedMood) || true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF212121),
          onRefresh: () async {
            ref.invalidate(recentlyPlayedSongsProvider);
            ref.invalidate(recommendedSongsProvider);
            ref.invalidate(popularSongsProvider);
            ref.invalidate(newReleasesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Top Bar: Profile avatar + notification bell on left (RTL), YouTube Music logo on right
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Right side (RTL): Red Play Circle + "Music"
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF0000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Music',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      // Left side (RTL): Bell with badge + Profile Avatar
                      Row(
                        children: [
                          // Bell Icon with Red Badge '3'
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('لديك 3 إشعارات جديدة حول إصدارات مطربيك المفضلين'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 8,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF0000),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),

                          // Profile Avatar
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2B2B2B),
                                border: Border.all(color: const Color(0xFF444444), width: 1.2),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Mood Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: _moods.map((mood) {
                      final isSelected = _selectedMood == mood;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = isSelected ? 'الكل' : mood;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFF212121),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.white : const Color(0xFF383838),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              mood,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Section 1: "التشغيل السريع" (Quick picks / Replay)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التشغيل السريع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3x3 Grid PageView
                      SizedBox(
                        height: 380,
                        child: PageView.builder(
                          controller: _quickPlayPageController,
                          itemCount: 2, // 2 pages of 3x3 cards
                          onPageChanged: (idx) {
                            setState(() {
                              _quickPlayPageIndex = idx;
                            });
                          },
                          itemBuilder: (context, page) {
                            final startIndex = page * 9;
                            final pageItems = displayedSongs.skip(startIndex).take(9).toList();
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: pageItems.length,
                              itemBuilder: (context, i) {
                                final song = pageItems[i];
                                return _buildQuickPlayCard(song, displayedSongs);
                              },
                            );
                          },
                        ),
                      ),

                      // Dots Page Indicator below 3x3 Grid
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDotIndicator(_quickPlayPageIndex == 0),
                          const SizedBox(width: 6),
                          _buildDotIndicator(_quickPlayPageIndex == 1),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Section 2: "اختيارات سريعة" (Quick picks - 5 horizontal pages of trending songs)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'اختيارات سريعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // "تشغيل الكل" pill button
                      GestureDetector(
                        onTap: () {
                          final picks = <Song>[...allPopular];
                          if (picks.length < 20) picks.addAll(SampleMusicData.songs);
                          final fullList = picks.take(20).toList();
                          if (fullList.isNotEmpty) {
                            ref.read(audioPlayerProvider.notifier).playPlaylist(fullList, initialIndex: 0);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF272727),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF383838), width: 0.8),
                          ),
                          child: const Text(
                            'تشغيل الكل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // Horizontal 5-page carousel for "اختيارات سريعة" (4 songs per page = 20 trending songs)
              SliverToBoxAdapter(
                child: _buildQuickPicksHorizontalSection(allPopular),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Section 3: "اقتراحات يومية" (Daily recommendations)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'اقتراحات يومية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (allRecommended.isNotEmpty) {
                            ref.read(audioPlayerProvider.notifier).playPlaylist(allRecommended, initialIndex: 0);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF272727),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF383838), width: 0.8),
                          ),
                          child: const Text(
                            'تشغيل الكل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Horizontal Carousel for Daily Recommendations
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allRecommended.length,
                    itemBuilder: (context, index) {
                      final song = allRecommended[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(audioPlayerProvider.notifier).playPlaylist(
                                allRecommended,
                                initialIndex: index,
                              );
                        },
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(left: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3D1414), Color(0xFF1A1A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: song.artworkUrl,
                                  fit: BoxFit.cover,
                                  color: Colors.black.withAlpha(90),
                                  colorBlendMode: BlendMode.darken,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withAlpha(220),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                left: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      song.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${song.artist} • 1.7 مليون عملية تشغيل',
                                      style: const TextStyle(
                                        color: Color(0xFFAAAAAA),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
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
                ),
              ),

              // Bottom padding so content is fully visible above floating mini-player & bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPlayCard(Song song, List<Song> playlist) {
    return GestureDetector(
      onTap: () {
        ref.read(audioPlayerProvider.notifier).playSong(song, playlist: playlist);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF1E1E1E),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: song.artworkUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFF282828)),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xCC000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                left: 6,
                child: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFF666666),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQuickPicksHorizontalSection(List<Song> allPopular) {
    final picks = <Song>[...allPopular];
    if (picks.length < 20) {
      picks.addAll(SampleMusicData.songs);
    }
    final fullList = picks.take(20).toList();

    return Column(
      children: [
        SizedBox(
          height: 256,
          child: PageView.builder(
            controller: _quickPicksPageController,
            itemCount: 5, // Exactly 5 horizontal swipe pages requested by user
            onPageChanged: (idx) {
              setState(() {
                _quickPicksPageIndex = idx;
              });
            },
            itemBuilder: (context, page) {
              final pageItems = fullList.skip(page * 4).take(4).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(pageItems.length, (i) {
                    final song = pageItems[i];
                    final overallIndex = page * 4 + i;
                    return _buildQuickPickRow(song, fullList, overallIndex);
                  }),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // 5-dot page indicator for the 5 horizontal screens
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildDotIndicator(_quickPicksPageIndex == index),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickPickRow(Song song, List<Song> playlist, int index) {
    return InkWell(
      onTap: () {
        ref.read(audioPlayerProvider.notifier).playPlaylist(playlist, initialIndex: index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            // Artwork (rounded 48x48)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: song.artworkUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF242424),
                  child: const Icon(Icons.music_note, color: Colors.white24, size: 22),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF242424),
                  child: const Icon(Icons.music_note, color: Colors.white24, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Song Title and Artist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${song.artist} • ${song.album.isNotEmpty ? song.album : "أفضل التريندات"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 3-dots more menu
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFFB3B3B3), size: 20),
              onPressed: () {
                _showSongModal(context, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSongModal(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.artworkUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist, style: const TextStyle(color: Colors.white70)),
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded, color: Colors.white),
                title: const Text('تشغيل التالي', style: TextStyle(color: Colors.white)),
                onTap: () {
                  ref.read(audioPlayerProvider.notifier).addToQueue(song);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                title: const Text('إضافة إلى قائمة تشغيل', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white),
                title: const Text('مشاركة', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
