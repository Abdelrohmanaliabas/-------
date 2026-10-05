import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/domain/models/song.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/downloads_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/providers/playlists_provider.dart';
import 'package:mazikty/presentation/screens/playlists/create_playlist_dialog.dart';

class SongTile extends ConsumerWidget {
  final Song song;
  final List<Song>? playlist;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showArtwork;
  final bool showIndex;

  const SongTile({
    super.key,
    required this.song,
    this.playlist,
    this.index,
    this.onTap,
    this.onRemove,
    this.showArtwork = true,
    this.showIndex = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    final isFav = ref.watch(favoritesProvider).value?.any((s) => s.id == song.id) ?? song.isFavorite;
    final isDownloaded = ref.watch(downloadsProvider).value?.any((s) => s.id == song.id) ?? song.isDownloaded;

    return InkWell(
      onTap: onTap ??
          () {
            if (playlist != null && playlist!.isNotEmpty) {
              final targetIndex = (index != null && index! >= 0 && index! < playlist!.length)
                  ? index!
                  : playlist!.indexWhere((s) => s.id == song.id);
              ref.read(audioPlayerProvider.notifier).playPlaylist(
                    playlist!,
                    initialIndex: targetIndex >= 0 ? targetIndex : 0,
                  );
            } else {
              ref.read(audioPlayerProvider.notifier).playSong(song);
            }
          },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            if (showIndex && index != null) ...[
              SizedBox(
                width: 26,
                child: Text(
                  '${index! + 1}',
                  style: AppTypography.labelMedium.copyWith(
                    color: isCurrentSong ? AppColors.primary : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showArtwork) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: song.artworkUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 24),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 24),
                      ),
                    ),
                    if (isCurrentSong)
                      Container(
                        width: 52,
                        height: 52,
                        color: Colors.black.withAlpha(120),
                        child: Icon(
                          isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: isCurrentSong ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (isDownloaded) ...[
                        const Icon(
                          Icons.download_done_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          '${song.artist} • ${song.album}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppColors.accent : AppColors.textMuted,
                size: 22,
              ),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(song);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () {
                _showMoreOptions(context, ref, isFav, isDownloaded);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(
    BuildContext context,
    WidgetRef ref,
    bool isFav,
    bool isDownloaded,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.artworkUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist,
                            style: AppTypography.bodySmall,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: AppColors.primary),
                title: Text('إضافة إلى قائمة تشغيل', style: AppTypography.bodyLarge),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showAddToPlaylistDialog(context, ref);
                },
              ),
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.accent : AppColors.textPrimary,
                ),
                title: Text(
                  isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                  style: AppTypography.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  ref.read(favoritesProvider.notifier).toggleFavorite(song);
                },
              ),
              if (song.isDownloadable)
                ListTile(
                  leading: Icon(
                    isDownloaded ? Icons.delete_outline_rounded : Icons.download_rounded,
                    color: isDownloaded ? AppColors.error : AppColors.textPrimary,
                  ),
                  title: Text(
                    isDownloaded ? 'حذف من التحميلات' : 'تنزيل للاستماع دون إنترنت',
                    style: AppTypography.bodyLarge,
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    if (isDownloaded) {
                      await ref.read(downloadsProvider.notifier).deleteDownload(song.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حذف الأغنية من التحميلات')),
                        );
                      }
                    } else {
                      try {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('جاري بدء التحميل...')),
                          );
                        }
                        await ref.read(downloadsProvider.notifier).downloadSong(song);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم اكتمال التحميل بنجاح')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تعذر تحميل الأغنية، يرجى التحقق من اتصال الإنترنت')),
                          );
                        }
                      }
                    }
                  },
                ),
              if (onRemove != null)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  title: Text('إزالة من هذه القائمة',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    onRemove!();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Consumer(
          builder: (context, ref, _) {
            final playlistsAsync = ref.watch(playlistsProvider);
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('إضافة إلى قائمة تشغيل', style: AppTypography.titleMedium),
              content: SizedBox(
                width: double.maxFinite,
                child: playlistsAsync.when(
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'لا توجد قوائم تشغيل حتى الآن. قم بإنشاء قائمة جديدة أولاً.',
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (ctx, i) {
                        final pl = playlists[i];
                        final contains = pl.songs.any((s) => s.id == song.id);
                        return ListTile(
                          title: Text(pl.name, style: AppTypography.titleSmall),
                          subtitle: Text('${pl.songsCount} أغنية', style: AppTypography.bodySmall),
                          trailing: contains
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                              : const Icon(Icons.add_circle_outline_rounded, color: AppColors.textMuted),
                          onTap: () async {
                            if (!contains) {
                              await ref.read(playlistsProvider.notifier).addSongToPlaylist(pl.id, song);
                              if (context.mounted) {
                                Navigator.pop(dialogCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تمت إضافة الأغنية إلى "${pl.name}"')),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('حدث خطأ في تحميل القوائم', style: AppTypography.bodyMedium),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    showCreatePlaylistDialog(context, ref);
                  },
                  child: Text('+ قائمة جديدة', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('إلغاء', style: AppTypography.labelMedium),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
