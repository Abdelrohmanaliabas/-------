import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/search_provider.dart';
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
                hintText: 'ابحث عن أغنية، فنان، ألبوم أو مقام...',
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
      'عود البطل',
      'عمرو دياب',
      'بنت الجيران',
      'شيرين',
      'الغزالة رايقة',
      'سطلانة',
      'أحمد سعد',
      'ويجز',
      'نصير شمة',
      'عمر خيرت',
      'فيروز',
      'أم كلثوم',
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
          title: 'ابحث في ملايين الأغاني والمهرجانات',
          message: 'محرك بحث فائق يبحث عبر أكثر من 15 مصدراً وقاعدة بيانات موسيقية عالمية وعربية لتجد أي أغنية فوراً.',
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

    final showSongs = filter == SearchFilter.all || filter == SearchFilter.songs;
    final showArtists = filter == SearchFilter.all || filter == SearchFilter.artists;
    final showAlbums = filter == SearchFilter.all || filter == SearchFilter.albums;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
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
              playlist: results.songs,
            );
          }),
        ],
      ],
    );
  }
}
