import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/downloads_provider.dart';
import 'package:mazikty/presentation/widgets/empty_state_view.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider);
    final activeDownloads = ref.watch(downloadProgressStreamProvider).value ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('الموسيقى المحملة', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(downloadsProvider.notifier).loadDownloads();
            },
          ),
        ],
      ),
      body: downloadsAsync.when(
        data: (songs) {
          if (songs.isEmpty && activeDownloads.isEmpty) {
            return const EmptyStateView(
              icon: Icons.download_done_rounded,
              title: 'لا توجد أغانٍ محملة',
              message:
                  'يمكنك تنزيل الأغاني المصرح بها للاستماع إليها دون الحاجة للاتصال بالإنترنت من خلال النقر على أيقونة التنزيل بجانب الأغنية.',
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // Active download progress indicators
              if (activeDownloads.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('جاري تنزيل الأغاني...', style: AppTypography.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...activeDownloads.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('معرف الأغنية: ${entry.key}', style: AppTypography.bodySmall),
                                    Text('${(entry.value * 100).toInt()}%', style: AppTypography.labelSmall),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: entry.value,
                                  backgroundColor: AppColors.surfaceCard,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],

              // Header summary
              if (songs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${songs.length} أغنية متوفرة أوفلاين', style: AppTypography.bodyMedium),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).playPlaylist(songs);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                        label: Text('تشغيل الكل', style: AppTypography.labelMedium.copyWith(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

              ...songs.map((song) {
                return SongTile(
                  song: song,
                  playlist: songs,
                  onRemove: () async {
                    await ref.read(downloadsProvider.notifier).deleteDownload(song.id);
                  },
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('فشل تحميل القائمة: $err', style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}
