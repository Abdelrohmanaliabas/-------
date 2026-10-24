import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/desktop_player_mode_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:window_manager/window_manager.dart';

class StandaloneMiniPlayerWindow extends ConsumerStatefulWidget {
  const StandaloneMiniPlayerWindow({super.key});

  @override
  ConsumerState<StandaloneMiniPlayerWindow> createState() => _StandaloneMiniPlayerWindowState();
}

class _StandaloneMiniPlayerWindowState extends ConsumerState<StandaloneMiniPlayerWindow> {
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Window Header (Draggable on desktop using DragToMoveArea)
            DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1B1B),
                  border: Border(bottom: BorderSide(color: Color(0xFF262626), width: 0.8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator_rounded, color: Colors.white38, size: 18),
                    const SizedBox(width: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'تحكم مازيكتي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Restore Full App Button
                    IconButton(
                      icon: const Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 16),
                      tooltip: 'العودة للتطبيق الكامل',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        ref.read(desktopModeProvider.notifier).switchToFullApp();
                      },
                    ),
                    const SizedBox(width: 2),
                    // Exit Application Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      tooltip: 'إغلاق التطبيق نهائياً',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () async {
                        await windowManager.destroy();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Content Area
            Expanded(
              child: song == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off_rounded, size: 40, color: Colors.white.withAlpha(60)),
                          const SizedBox(height: 8),
                          Text(
                            'لا يوجد مقطع يعمل حالياً',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white38),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.open_in_full_rounded, size: 16),
                            label: const Text('فتح مازيكتي'),
                            onPressed: () {
                              ref.read(desktopModeProvider.notifier).switchToFullApp();
                            },
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Artwork with glow
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: song.artworkUrl,
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 170,
                                    height: 170,
                                    color: const Color(0xFF242424),
                                    child: const Icon(Icons.music_note, color: Colors.white24, size: 40),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 170,
                                    height: 170,
                                    color: const Color(0xFF242424),
                                    child: const Icon(Icons.music_note, color: Colors.white24, size: 40),
                                  ),
                                ),
                              ),
                              // Favorite overlay button
                              Container(
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withAlpha(160),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? AppColors.accent : Colors.white70,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                  onPressed: () {
                                    ref.read(favoritesProvider.notifier).toggleFavorite(song);
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Song Title & Artist
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          // Progress Bar & Durations (LTR Directionality)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3.0,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: playerState.duration.inMilliseconds > 0
                                        ? (playerState.position.inMilliseconds /
                                                playerState.duration.inMilliseconds)
                                            .clamp(0.0, 1.0)
                                        : 0.0,
                                    onChanged: (value) {
                                      final position = playerState.duration * value;
                                      ref.read(audioPlayerProvider.notifier).seek(position);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(playerState.position),
                                        style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
                                      ),
                                      Text(
                                        _formatDuration(playerState.duration),
                                        style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Playback Controls Row (LTR: Repeat, Prev, Play/Pause, Next, Shuffle)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Repeat mode
                                IconButton(
                                  icon: Icon(
                                    playerState.loopMode == LoopMode.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    size: 18,
                                    color: playerState.loopMode != LoopMode.off ? Colors.white : Colors.white38,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => ref.read(audioPlayerProvider.notifier).toggleLoopMode(),
                                ),

                                // Previous track
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  onPressed: () => ref.read(audioPlayerProvider.notifier).previous(),
                                ),

                                // Big circular Play / Pause button
                                GestureDetector(
                                  onTap: () => ref.read(audioPlayerProvider.notifier).playOrPause(),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 10,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: playerState.isBuffering
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black54),
                                            )
                                          : Icon(
                                              playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              color: Colors.black,
                                              size: 30,
                                            ),
                                    ),
                                  ),
                                ),

                                // Next track
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
                                ),

                                // Shuffle mode
                                IconButton(
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    size: 18,
                                    color: playerState.isShuffleEnabled ? Colors.white : Colors.white38,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => ref.read(audioPlayerProvider.notifier).toggleShuffle(),
                                ),
                              ],
                            ),
                          ),

                          // Volume Control Bar (LTR)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (currentVolume > 0) {
                                      _lastVolume = currentVolume;
                                      ref.read(audioPlayerProvider.notifier).setVolume(0);
                                    } else {
                                      ref.read(audioPlayerProvider.notifier).setVolume(_lastVolume > 0 ? _lastVolume : 1.0);
                                    }
                                  },
                                  child: Icon(
                                    currentVolume == 0
                                        ? Icons.volume_off_rounded
                                        : (currentVolume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                    color: const Color(0xFF888888),
                                    size: 16,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                      activeTrackColor: const Color(0xFF888888),
                                      inactiveTrackColor: Colors.white12,
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
                                  style: const TextStyle(color: Color(0xFF777777), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
