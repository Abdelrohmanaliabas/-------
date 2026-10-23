import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/screens/player/full_player_screen.dart';

class DesktopSideController extends ConsumerStatefulWidget {
  const DesktopSideController({super.key});

  @override
  ConsumerState<DesktopSideController> createState() => _DesktopSideControllerState();
}

class _DesktopSideControllerState extends ConsumerState<DesktopSideController> {
  bool _isCollapsed = false;
  double _lastVolume = 1.0;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final song = playerState.currentSong;
    final currentVolume = ref.watch(playerVolumeProvider).value ?? 1.0;
    final isFav = song != null && (ref.watch(favoritesProvider).value?.any((s) => s.id == song.id) ?? false);

    // Collapsed Mode: Slim floating vertical bar
    if (_isCollapsed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161616).withAlpha(240),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 16,
                offset: const Offset(-2, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand button
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 26),
                tooltip: 'توسيع لوحة التحكم',
                onPressed: () => setState(() => _isCollapsed = false),
              ),
              const SizedBox(height: 8),

              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),

              // Play/Pause button
              IconButton(
                icon: playerState.isBuffering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        playerState.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                tooltip: playerState.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                onPressed: () => ref.read(audioPlayerProvider.notifier).playOrPause(),
              ),
              const SizedBox(height: 4),

              // Next
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                tooltip: 'التالي',
                onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
              ),
            ],
          ),
        ),
      );
    }

    // Expanded Mode: Full Desktop Controller Sidebar
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 14, top: 20, bottom: 70),
        decoration: BoxDecoration(
          color: const Color(0xFF141414).withAlpha(245),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF282828), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 22,
              offset: const Offset(-4, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Controller Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1B1B),
                  border: Border(bottom: BorderSide(color: Color(0xFF262626), width: 0.8)),
                ),
                child: Row(
                  children: [
                    // Official Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'تحكم مازيكتي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Expand full player
                    IconButton(
                      icon: const Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 18),
                      tooltip: 'فتح المشغل بالحجم الكامل',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                        );
                      },
                    ),
                    // Collapse button
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 22),
                      tooltip: 'تصغير اللوحة',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => setState(() => _isCollapsed = true),
                    ),
                  ],
                ),
              ),

              // Song Info & Artwork Area
              if (song != null) ...[
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      // Artwork with glow
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: song.artworkUrl,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 140,
                                height: 140,
                                color: const Color(0xFF222222),
                                child: const Icon(Icons.music_note_rounded, color: Colors.white30, size: 40),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 140,
                                height: 140,
                                color: const Color(0xFF222222),
                                child: const Icon(Icons.music_note_rounded, color: Colors.white30, size: 40),
                              ),
                            ),
                          ),
                          // Favorite button overlay
                          GestureDetector(
                            onTap: () {
                              ref.read(favoritesProvider.notifier).toggleFavorite(song);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                color: isFav ? AppColors.accent : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Artist
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: const Color(0xFF333333),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: (playerState.duration.inMilliseconds > 0)
                              ? (playerState.position.inMilliseconds / playerState.duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: (val) {
                            final targetMs = (val * playerState.duration.inMilliseconds).toInt();
                            ref.read(audioPlayerProvider.notifier).seek(Duration(milliseconds: targetMs));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(playerState.position),
                              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                            ),
                            Text(
                              _formatDuration(playerState.duration),
                              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: playerState.isShuffleEnabled ? AppColors.primary : Colors.white60,
                          size: 20,
                        ),
                        tooltip: 'خلط الأغاني',
                        onPressed: () => ref.read(audioPlayerProvider.notifier).toggleShuffle(),
                      ),

                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                        tooltip: 'السابق',
                        onPressed: () => ref.read(audioPlayerProvider.notifier).previous(),
                      ),

                      // Play / Pause prominent button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF5252)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(90),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 32,
                          color: Colors.white,
                          icon: playerState.isBuffering
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Icon(
                                  playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                ),
                          onPressed: () => ref.read(audioPlayerProvider.notifier).playOrPause(),
                        ),
                      ),

                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                        tooltip: 'التالي',
                        onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
                      ),

                      // Loop
                      IconButton(
                        icon: Icon(
                          playerState.loopMode == LoopMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: playerState.loopMode != LoopMode.off ? AppColors.primary : Colors.white60,
                          size: 20,
                        ),
                        tooltip: 'تكرار',
                        onPressed: () => ref.read(audioPlayerProvider.notifier).toggleLoopMode(),
                      ),
                    ],
                  ),
                ),

                // Volume Slider Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF262626), width: 0.6),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentVolume > 0) {
                            _lastVolume = currentVolume;
                            ref.read(audioPlayerProvider.notifier).setVolume(0.0);
                          } else {
                            ref.read(audioPlayerProvider.notifier).setVolume(_lastVolume > 0 ? _lastVolume : 1.0);
                          }
                        },
                        child: Icon(
                          currentVolume == 0
                              ? Icons.volume_off_rounded
                              : currentVolume < 0.5
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: const Color(0xFF444444),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: currentVolume.clamp(0.0, 1.0),
                            onChanged: (val) {
                              ref.read(audioPlayerProvider.notifier).setVolume(val);
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${(currentVolume * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Idle State (No song currently playing)
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 44),
                      const SizedBox(height: 10),
                      Text('مازيكتي جاهز', style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'اختر أي أغنية لتشغيلها والتحكم بها من هنا',
                        style: AppTypography.labelSmall.copyWith(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
