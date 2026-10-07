import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/domain/models/playlist.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/providers/search_provider.dart';
import 'package:mazikty/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  int _selectedChipIndex = 0;

  final List<String> _chips = [
    'الأغاني',
    'الفيديوهات',
    'قوائم تشغيل من إنشاء المنتدى',
    'قوائم التشغيل المميزة',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: SafeArea(
        child: Column(
          children: [
            // YouTube Music Top Search Capsule Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Back Arrow (RTL)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        }
                      },
                    ),

                    // Search Input Field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref.read(searchQueryProvider.notifier).state = val;
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'بحث في مازيكتي...',
                          hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    // Clear button if typing
                    if (query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),

                    // Mic Icon
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 22),
                      onPressed: () {
                        // Voice search prompt
                      },
                    ),

                    // Waveform / Audio recognition icon
                    IconButton(
                      icon: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: List.generate(_chips.length, (index) {
                  final isSelected = _selectedChipIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChipIndex = index;
                        });
                        if (index == 0) {
                          ref.read(searchFilterProvider.notifier).state = SearchFilter.songs;
                        } else if (index == 1) {
                          ref.read(searchFilterProvider.notifier).state = SearchFilter.all;
                        } else {
                          ref.read(searchFilterProvider.notifier).state = SearchFilter.playlists;
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFF212121),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.white : const Color(0xFF383838),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _chips[index],
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content / Results
            Expanded(
              child: query.isEmpty
                  ? _buildSuggestionsView()
                  : searchResultsAsync.when(
                      data: (results) => _buildYouTubeMusicResultsView(results),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (err, _) => Center(
                        child: Text('حدث خطأ: $err', style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsView() {
    final suggestions = [
      'اغاني جيم',
      'حبيبي أنا من غيرك',
      'الضرب السني',
      'بلاش الملامة',
      'MOTIVATION FUNK',
      'SLAVA FUNK! (Slowed)',
      'تامر حسني',
      'عمرو دياب',
      'تمارين قوية',
      'اغاني عربيه للجيم',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'عمليات البحث الرائجة',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...suggestions.map(
          (text) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_rounded, color: Color(0xFF888888), size: 22),
            title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            trailing: const Icon(Icons.north_west_rounded, color: Color(0xFF888888), size: 18),
            onTap: () {
              _searchController.text = text;
              ref.read(searchQueryProvider.notifier).state = text;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeMusicResultsView(SearchResults results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'لم يتم العثور على نتائج مطابقة',
          style: TextStyle(color: Color(0xFF888888), fontSize: 15),
        ),
      );
    }

    final topSong = results.songs.isNotEmpty ? results.songs.first : null;
    final otherSongs = results.songs.isNotEmpty ? results.songs.skip(1).toList() : <Song>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Top Featured Result Card (matching Image 3 top card)
        if (topSong != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF303030), width: 0.8),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            topSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أغنية • ${topSong.artist}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: topSong.artworkUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card Actions Row: [ White "تشغيل" | Dark "حفظ" ]
                Row(
                  children: [
                    // Play Button Pill (White)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(audioPlayerProvider.notifier).playSong(
                                topSong,
                                playlist: results.songs,
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                              SizedBox(width: 6),
                              Text(
                                'تشغيل',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Save Button Pill (Dark)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(topSong);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'حفظ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Playlists matching results
        if (results.playlists.isNotEmpty)
          ...results.playlists.map((playlist) => _buildPlaylistTile(playlist)),

        // Other matching songs
        ...otherSongs.map((song) {
          return SongTile(
            song: song,
            playlist: results.songs,
          );
        }),
      ],
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: IconButton(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
        onPressed: () {},
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        'قائمة تشغيل • ${playlist.songsCount} مقطع',
        maxLines: 1,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
      ),
      trailing: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: playlist.artworkUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
    );
  }
}
