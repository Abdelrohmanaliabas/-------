import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/data/mock/sample_music_data.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/music_providers.dart';

class SamplesScreen extends ConsumerWidget {
  const SamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(popularSongsProvider);
    final songs = songsAsync.value ?? SampleMusicData.songs;

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.slow_motion_video_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('عينات موسيقية', style: AppTypography.titleSmall.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Artwork with Dark Blur
              CachedNetworkImage(
                imageUrl: song.artworkUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFF181818)),
                errorWidget: (context, url, error) => Container(color: const Color(0xFF181818)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(120),
                      Colors.transparent,
                      Colors.black.withAlpha(220),
                      const Color(0xFF030303),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.75, 1.0],
                  ),
                ),
              ),

              // Floating Controls on the Left (RTL)
              Positioned(
                left: 16,
                bottom: 120,
                child: Column(
                  children: [
                    _buildSideAction(
                      icon: Icons.thumb_up_alt_outlined,
                      label: 'إعجاب',
                      onTap: () {},
                    ),
                    const SizedBox(height: 18),
                    _buildSideAction(
                      icon: Icons.bookmark_border_rounded,
                      label: 'حفظ',
                      onTap: () {},
                    ),
                    const SizedBox(height: 18),
                    _buildSideAction(
                      icon: Icons.share_rounded,
                      label: 'مشاركة',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Song Info and Play Button on the Right (RTL)
              Positioned(
                right: 20,
                left: 90,
                bottom: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      song.title,
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.artist,
                      style: AppTypography.bodyLarge.copyWith(
                        color: const Color(0xFFAAAAAA),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),

                    // Big White Play Pill
                    GestureDetector(
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).playSong(song, playlist: songs);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
                            const SizedBox(width: 6),
                            Text(
                              'تشغيل الأغنية كاملة',
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSideAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x66212121),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
