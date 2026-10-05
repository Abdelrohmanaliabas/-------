import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/widgets/empty_state_view.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('المفضلة', style: AppTypography.titleLarge),
        actions: [
          favoritesAsync.when(
            data: (songs) {
              if (songs.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 32),
                  tooltip: 'تشغيل الكل',
                  onPressed: () {
                    ref.read(audioPlayerProvider.notifier).playPlaylist(songs);
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'لا توجد أغانٍ في المفضلة',
              message:
                  'اضغط على رمز القلب بجانب أي أغنية لتحفظها في قائمتك المفضلة وتصل إليها بسرعة في أي وقت.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(70), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مفضلتك متاحة بالكامل أوفلاين وتعمل تلقائياً دون اتصال بالإنترنت',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${songs.length} أغنية مفضلة',
                  style: AppTypography.bodySmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return SongTile(
                      song: song,
                      playlist: songs,
                      index: index,
                      showIndex: false,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('حدث خطأ في تحميل المفضلة: $err', style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}
