import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/music_providers.dart';
import 'package:mazikty/presentation/widgets/artist_avatar.dart';
import 'package:mazikty/presentation/widgets/playlist_card.dart';
import 'package:mazikty/presentation/widgets/section_header.dart';
import 'package:mazikty/presentation/widgets/song_card.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';
import 'widgets/categories_section.dart';
import 'widgets/continue_listening_section.dart';
import 'widgets/home_hero_banner.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentlyPlayedSongsProvider);
    final recommendedAsync = ref.watch(recommendedSongsProvider);
    final popularAsync = ref.watch(popularSongsProvider);
    final newReleasesAsync = ref.watch(newReleasesProvider);
    final continueListeningAsync = ref.watch(continueListeningProvider);
    final genresAsync = ref.watch(genresProvider);
    final artistsAsync = ref.watch(featuredArtistsProvider);
    final playlistsAsync = ref.watch(featuredPlaylistsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(recentlyPlayedSongsProvider);
            ref.invalidate(recommendedSongsProvider);
            ref.invalidate(popularSongsProvider);
            ref.invalidate(newReleasesProvider);
            ref.invalidate(continueListeningProvider);
            ref.invalidate(genresProvider);
            ref.invalidate(featuredArtistsProvider);
            ref.invalidate(featuredPlaylistsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Top App Bar with Logo & Branding
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(90),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مازيكتي',
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'عالمك الموسيقي الراقي',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('متصل', style: AppTypography.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: GestureDetector(
                    onTap: onSearchTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider, width: 0.6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'البحث عن أغنية أو مطرب أو ألبوم...',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Hero Banner (Featured Highlight)
              recommendedAsync.when(
                data: (songs) {
                  if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: HomeHeroBanner(song: songs.first),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                  ),
                ),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Continue Listening
              continueListeningAsync.when(
                data: (songs) {
                  if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const SectionHeader(
                          title: 'أكمل الاستماع',
                          subtitle: 'تابع من حيث توقفت',
                          actionText: null,
                        ),
                        SizedBox(
                          height: 76,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: songs.length,
                            itemBuilder: (context, index) => ContinueListeningCard(song: songs[index]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Categories / Genres
              genresAsync.when(
                data: (genres) => SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const SectionHeader(
                        title: 'التصنيفات والأنغام',
                        subtitle: 'استكشف المقامات والأنواع الموسيقية',
                        actionText: null,
                      ),
                      CategoriesSection(genres: genres),
                    ],
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Popular Songs
              popularAsync.when(
                data: (songs) => SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const SectionHeader(
                        title: 'الأغاني الأكثر استماعًا',
                        subtitle: 'المقطوعات الأكثر شعبية هذا الأسبوع',
                        actionText: null,
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: songs.length,
                          itemBuilder: (context, index) => SongCard(song: songs[index], playlist: songs),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Featured Artists
              artistsAsync.when(
                data: (artists) => SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const SectionHeader(
                        title: 'أبرز الفنانين والمبدعين',
                        subtitle: 'كبار رواد الموسيقى والطرب',
                        actionText: null,
                      ),
                      SizedBox(
                        height: 145,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: artists.length,
                          itemBuilder: (context, index) => ArtistAvatar(artist: artists[index]),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // New Releases
              newReleasesAsync.when(
                data: (songs) => SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const SectionHeader(
                        title: 'أحدث الإصدارات',
                        subtitle: 'ألحان جديدة أُضيفت مؤخراً',
                        actionText: null,
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: songs.length,
                          itemBuilder: (context, index) => SongCard(song: songs[index], playlist: songs),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Featured Playlists
              playlistsAsync.when(
                data: (playlists) => SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const SectionHeader(
                        title: 'قوائم تشغيل مميزة',
                        subtitle: 'مختارات موسيقية تناسب مزاجك',
                        actionText: null,
                      ),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: playlists.length,
                          itemBuilder: (context, index) => PlaylistCard(playlist: playlists[index]),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Recently Played list
              recentAsync.when(
                data: (songs) => SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const SectionHeader(
                        title: 'الأغاني الأخيرة',
                        subtitle: 'ما تم الاستماع إليه مؤخراً',
                        actionText: null,
                      ),
                      ...songs.map((s) => SongTile(song: s, playlist: songs)),
                    ],
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
