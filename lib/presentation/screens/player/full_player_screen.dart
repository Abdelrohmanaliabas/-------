import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/core/utils/formatters.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/downloads_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'queue_bottom_sheet.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('لا توجد أغنية قيد التشغيل حالياً', style: AppTypography.titleMedium),
        ),
      );
    }

    if (playerState.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!playerState.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    final isFav = ref.watch(favoritesProvider).value?.any((s) => s.id == song.id) ?? song.isFavorite;
    final isDownloaded = ref.watch(downloadsProvider).value?.any((s) => s.id == song.id) ?? song.isDownloaded;

    final duration = playerState.duration;
    final position = playerState.position;
    final maxMs = duration.inMilliseconds.toDouble();
    final currentMs = (_dragValue ?? position.inMilliseconds.toDouble()).clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.playerBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      color: AppColors.textPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          'جاري التشغيل من',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          song.album.isNotEmpty ? song.album : 'مازيكتي',
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, size: 26),
                      color: AppColors.textPrimary,
                      onPressed: () => _showOptionsMenu(context, ref, song, isFav, isDownloaded),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Album Artwork with subtle glow
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: MediaQuery.of(context).size.width * 0.78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 36,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(180),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CachedNetworkImage(
                      imageUrl: song.artworkUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.music_note, size: 80, color: AppColors.textMuted),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.music_note, size: 80, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Title, Artist and Favorite Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.displayMedium.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.accent : AppColors.textMuted,
                        size: 28,
                      ),
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(song);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress Slider & Timestamps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceLight,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: maxMs > 0 ? maxMs : 1.0,
                        value: currentMs,
                        onChanged: (val) {
                          setState(() {
                            _dragValue = val;
                          });
                        },
                        onChangeEnd: (val) {
                          ref.read(audioPlayerProvider.notifier).seek(
                                Duration(milliseconds: val.round()),
                              );
                          setState(() {
                            _dragValue = null;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Formatters.formatDuration(
                              _dragValue != null
                                  ? Duration(milliseconds: _dragValue!.round())
                                  : position,
                            ),
                            style: AppTypography.bodySmall,
                          ),
                          Text(
                            Formatters.formatDuration(duration),
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Player Controls (Shuffle, Previous, Play/Pause, Next, Repeat)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerState.isShuffleEnabled ? AppColors.primary : AppColors.textMuted,
                        size: 24,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).toggleShuffle();
                      },
                    ),

                    // Previous
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: AppColors.textPrimary,
                        size: 34,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).previous();
                      },
                    ),

                    // Play/Pause Big Button
                    GestureDetector(
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).playOrPause();
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(90),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: playerState.isBuffering
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                playerState.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 38,
                              ),
                      ),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textPrimary,
                        size: 34,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).next();
                      },
                    ),

                    // Repeat Mode
                    IconButton(
                      icon: Icon(
                        playerState.loopMode == LoopMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: playerState.loopMode != LoopMode.off
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 24,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).toggleLoopMode();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Actions: Download, Queue, Share
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                        color: isDownloaded ? AppColors.success : AppColors.textMuted,
                        size: 24,
                      ),
                      tooltip: 'تنزيل بدون إنترنت',
                      onPressed: () async {
                        if (isDownloaded) {
                          await ref.read(downloadsProvider.notifier).deleteDownload(song.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حذف الأغنية من المحملات')),
                            );
                          }
                        } else {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('جاري بدء التحميل...')),
                            );
                            await ref.read(downloadsProvider.notifier).downloadSong(song);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم اكتمال التنزيل بنجاح')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('خطأ في التحميل: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.textMuted,
                        size: 26,
                      ),
                      tooltip: 'قائمة الانتظار',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: const QueueBottomSheet(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    dynamic song,
    bool isFav,
    bool isDownloaded,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppColors.accent : AppColors.textPrimary,
              ),
              title: Text(isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                  style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                ref.read(favoritesProvider.notifier).toggleFavorite(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: AppColors.primary),
              title: Text('إضافة إلى قائمة تشغيل', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
