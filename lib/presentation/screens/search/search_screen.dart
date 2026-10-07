import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/domain/models/playlist.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/providers/search_provider.dart';
import 'package:mazikty/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:mazikty/presentation/widgets/artist_avatar.dart';
import 'package:mazikty/presentation/widgets/empty_state_view.dart';
import 'package:mazikty/presentation/widgets/section_header.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final activeFilter = ref.watch(searchFilterProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('البحث', style: AppTypography.titleLarge),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(searchQueryProvider.notifier).state = val;
              },
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'ابحث عن أغنية، فنان، ألبوم أو بلايليست (جيم، عربي، أجنبي)...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filter Chips
          if (query.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildFilterChip('الكل', SearchFilter.all, activeFilter),
                  _buildFilterChip('بلايليست', SearchFilter.playlists, activeFilter),
                  _buildFilterChip('أغاني', SearchFilter.songs, activeFilter),
                  _buildFilterChip('فنانين', SearchFilter.artists, activeFilter),
                  _buildFilterChip('ألبومات', SearchFilter.albums, activeFilter),
                ],
              ),
            ),

          // Content / Results
          Expanded(
            child: query.isEmpty
                ? _buildEmptyOrSuggestionsView()
                : searchResultsAsync.when(
                    data: (results) => _buildResultsView(results, activeFilter),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text('حدث خطأ أثناء البحث: $err', style: AppTypography.bodyMedium),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchFilter filter, SearchFilter current) {
    final isSelected = filter == current;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.black,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? Colors.black : AppColors.textPrimary,
        ),
        backgroundColor: AppColors.surfaceLight,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          ref.read(searchFilterProvider.notifier).state = filter;
        },
      ),
    );
  }

  Widget _buildEmptyOrSuggestionsView() {
    final suggestions = [
      'أغاني جيم عربي',
      'Workout & Gym Hits',
      'مهرجانات',
      'رومانسيات عربية',
      'Morning Vibes',
      'كلاسيكيات عربية',
      'Chill & Relax',
      'Pop Hits 2024',
      'عمرو دياب',
      'شيرين',
      'عمر خيرت',
      'ويجز',
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('عمليات البحث الأكثر رواجاً', style: AppTypography.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '15+ محرك بحث',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions.map((tag) {
            return ActionChip(
              label: Text(tag),
              backgroundColor: AppColors.surfaceLight,
              labelStyle: AppTypography.bodyMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.divider, width: 0.5),
              ),
              onPressed: () {
                _searchController.text = tag;
                ref.read(searchQueryProvider.notifier).state = tag;
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        const EmptyStateView(
          icon: Icons.search_rounded,
          title: 'ابحث في ملايين الأغاني وقوائم التشغيل',
          message: 'ابحث عن قوائم تشغيل جاهزة (جيم، عربي، أجنبي) وأضفها بالكامل للمفضلة بضغطة واحدة!',
        ),
      ],
    );
  }

  Widget _buildResultsView(SearchResults results, SearchFilter filter) {
    if (results.isEmpty) {
      return const EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'لم يتم العثور على نتائج',
        message: 'تأكد من كتابة الكلمات بشكل صحيح أو جرب البحث بكلمات أخرى.',
      );
    }

    final showPlaylists = filter == SearchFilter.all || filter == SearchFilter.playlists;
    final showSongs = filter == SearchFilter.all || filter == SearchFilter.songs;
    final showArtists = filter == SearchFilter.all || filter == SearchFilter.artists;
    final showAlbums = filter == SearchFilter.all || filter == SearchFilter.albums;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Playlists Section
        if (showPlaylists && results.playlists.isNotEmpty) ...[
          SectionHeader(
            title: 'قوائم التشغيل (${results.playlists.length})',
            actionText: null,
          ),
          const SizedBox(height: 4),
          ...results.playlists.map((playlist) => _buildPlaylistResultTile(playlist)),
          const SizedBox(height: 16),
        ],

        // Artists Section
        if (showArtists && results.artists.isNotEmpty) ...[
          const SectionHeader(title: 'الفنانون', actionText: null),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.artists.length,
              itemBuilder: (context, index) {
                return ArtistAvatar(artist: results.artists[index], size: 70);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Albums Section
        if (showAlbums && results.albums.isNotEmpty) ...[
          const SectionHeader(title: 'الألبومات', actionText: null),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.albums.length,
              itemBuilder: (context, index) {
                final album = results.albums[index];
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: album.artworkUrl,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(fontSize: 13),
                      ),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Songs Section
        if (showSongs && results.songs.isNotEmpty) ...[
          SectionHeader(title: 'الأغاني (${results.songs.length})', actionText: null),
          ...results.songs.map((song) {
            return SongTile(
              song: song,
              playlist: null,
              onTap: () {
                ref.read(audioPlayerProvider.notifier).playSongWithRadio(song);
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPlaylistResultTile(Playlist playlist) {
    final favState = ref.watch(favoritesProvider);
    final favIds = favState.value?.map((s) => s.id).toSet() ?? {};
    final addedCount = playlist.songs.where((s) => favIds.contains(s.id)).length;
    final allAdded = playlist.songs.isNotEmpty && addedCount == playlist.songs.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allAdded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
          width: allAdded ? 1.5 : 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(playlist: playlist),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: playlist.artworkUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.surface,
                      child: const Icon(Icons.queue_music, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: AppTypography.titleSmall.copyWith(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (playlist.description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          playlist.description!,
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.music_note, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${playlist.songs.length} أغنية',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                          if (addedCount > 0 && !allAdded) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$addedCount مضافة',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Add to Favorites Button
                _buildAddToFavBtn(
                  playlist: playlist,
                  allAdded: allAdded,
                  onTap: () => _addPlaylistToFavorites(playlist),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddToFavBtn({
    required Playlist playlist,
    required bool allAdded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: allAdded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: allAdded
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: allAdded ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(12),
          border: allAdded
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allAdded ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: allAdded ? AppColors.primary : Colors.black,
            ),
            const SizedBox(width: 5),
            Text(
              allAdded ? 'مضافة' : 'أضف للمفضلة',
              style: AppTypography.labelMedium.copyWith(
                color: allAdded ? AppColors.primary : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPlaylistToFavorites(Playlist playlist) async {
    if (playlist.songs.isEmpty) {
      _showSnackBar('هذه البلايليست فارغة', isError: true);
      return;
    }

    try {
      final count = await ref.read(favoritesProvider.notifier).addAllToFavorites(playlist.songs);
      if (count == 0) {
        _showSnackBar('كل أغاني "${playlist.name}" موجودة بالفعل في المفضلة ❤️');
      } else {
        _showSnackBar(
          'تمت إضافة $count أغنية من "${playlist.name}" للمفضلة بنجاح ❤️',
          isSuccess: true,
        );
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مجدداً', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                      ? Icons.favorite
                      : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : isSuccess
                ? Colors.green.shade700
                : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
