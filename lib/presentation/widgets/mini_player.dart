import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/screens/player/full_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final double progress = (playerState.duration.inMilliseconds > 0)
        ? (playerState.position.inMilliseconds / playerState.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const FullPlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Color(0xFF212121),
          border: Border(
            top: BorderSide(color: Color(0xFF2C2C2C), width: 0.8),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Play/Pause button (far left in RTL)
                  IconButton(
                    iconSize: 30,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    color: Colors.white,
                    icon: playerState.isBuffering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            playerState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 32,
                          ),
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).playOrPause();
                    },
                  ),
                  const SizedBox(width: 8),

                  // Cast icon
                  IconButton(
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    color: Colors.white,
                    icon: const Icon(Icons.cast_rounded),
                    onPressed: () {
                      // Cast / output device options
                    },
                  ),
                  const SizedBox(width: 12),

                  // Song title & artist (middle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: const Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Artwork thumbnail (far right in RTL)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: song.artworkUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF2C2C2C),
                        child: const Icon(Icons.music_note, color: Colors.white54, size: 22),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF2C2C2C),
                        child: const Icon(Icons.music_note, color: Colors.white54, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thin progress line at the very bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0x22FFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
