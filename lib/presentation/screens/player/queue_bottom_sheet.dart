import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';

class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final queue = playerState.queue;
    final currentSong = playerState.currentSong;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'قائمة الانتظار (${queue.length})',
                    style: AppTypography.titleMedium,
                  ),
                  if (queue.isNotEmpty)
                    Text(
                      'جاري التشغيل',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (queue.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'لا توجد أغاني في قائمة الانتظار',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: queue.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 68),
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrent = song.id == currentSong?.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CachedNetworkImage(
                              imageUrl: song.artworkUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                            if (isCurrent)
                              Container(
                                width: 44,
                                height: 44,
                                color: Colors.black.withAlpha(140),
                                child: const Icon(
                                  Icons.equalizer_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              ref.read(audioPlayerProvider.notifier).removeFromQueue(index);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).skipToIndex(index);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
