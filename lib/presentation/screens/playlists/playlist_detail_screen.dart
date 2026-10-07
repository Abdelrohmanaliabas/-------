import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/core/utils/formatters.dart';
import 'package:mazikty/domain/models/playlist.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/providers/playlists_provider.dart';
import 'package:mazikty/presentation/widgets/empty_state_view.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';
import 'create_playlist_dialog.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    // Find current updated version of playlist
    final currentPlaylist = playlistsAsync.value?.firstWhere(
          (p) => p.id == playlist.id,
          orElse: () => playlist,
        ) ??
        playlist;

    final songs = currentPlaylist.songs;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                currentPlaylist.name,
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: currentPlaylist.artworkUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (currentPlaylist.isCustom)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: AppColors.surface,
                  onSelected: (val) {
                    if (val == 'rename') {
                      showRenamePlaylistDialog(
                        context,
                        ref,
                        currentPlaylist.id,
                        currentPlaylist.name,
                      );
                    } else if (val == 'delete') {
                      _showDeleteConfirmation(context, ref, currentPlaylist.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('إعادة تسمية'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف القائمة', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
            ],
          ),

          // Playlist Meta & Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentPlaylist.description != null) ...[
                    Text(
                      currentPlaylist.description!,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.music_note_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${currentPlaylist.songsCount} أغنية',
                        style: AppTypography.bodySmall,
                      ),
                      if (currentPlaylist.songs.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          Formatters.formatDuration(currentPlaylist.totalDuration),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: songs.isEmpty
                              ? null
                              : () {
                                  ref.read(audioPlayerProvider.notifier).playPlaylist(songs);
                                },
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                          label: Text(
                            'تشغيل الكل',
                            style: AppTypography.labelLarge.copyWith(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: songs.isEmpty
                            ? null
                            : () {
                                ref.read(audioPlayerProvider.notifier).playPlaylist(songs);
                                ref.read(audioPlayerProvider.notifier).toggleShuffle();
                              },
                        icon: const Icon(Icons.shuffle_rounded, color: AppColors.primary),
                        label: Text('خلط', style: AppTypography.labelMedium),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final favState = ref.watch(favoritesProvider);
                          final favIds = favState.value?.map((s) => s.id).toSet() ?? {};
                          final allInFav = songs.isNotEmpty && songs.every((s) => favIds.contains(s.id));

                          return IconButton.filledTonal(
                            onPressed: songs.isEmpty
                                ? null
                                : () async {
                                    final count = await ref
                                        .read(favoritesProvider.notifier)
                                        .addAllToFavorites(songs);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            count > 0
                                                ? 'تمت إضافة $count أغنية إلى المفضلة ❤️'
                                                : 'جميع أغاني هذه القائمة موجودة بالفعل في المفضلة ❤️',
                                            style: const TextStyle(fontFamily: 'Cairo'),
                                          ),
                                          backgroundColor: AppColors.surface,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  },
                            style: IconButton.styleFrom(
                              backgroundColor: allInFav ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
                              side: BorderSide(color: allInFav ? AppColors.primary : AppColors.divider),
                            ),
                            icon: Icon(
                              allInFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: allInFav ? 'جميع الأغاني في المفضلة' : 'إضافة جميع الأغاني للمفضلة',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Songs List
          if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: Icons.queue_music_rounded,
                title: 'هذه القائمة فارغة',
                message: 'تصفح الأغاني وأضف مقطوعاتك المفضلة إلى هذه القائمة لتستمع إليها في أي وقت.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  return SongTile(
                    song: song,
                    playlist: songs,
                    index: index,
                    showIndex: true,
                    onRemove: currentPlaylist.isCustom
                        ? () {
                            ref.read(playlistsProvider.notifier).removeSongFromPlaylist(
                                  currentPlaylist.id,
                                  song.id,
                                );
                          }
                        : null,
                  );
                },
                childCount: songs.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String playlistId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('حذف قائمة التشغيل', style: AppTypography.titleMedium),
        content: Text('هل أنت متأكد من رغبتك في حذف هذه القائمة؟', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: AppTypography.labelMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(playlistsProvider.notifier).deletePlaylist(playlistId);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('حذف', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
