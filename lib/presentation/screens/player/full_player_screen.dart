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

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  double? _dragValue;
  bool _isVideoMode = false;
  bool _isLiked = false;
  bool _isDisliked = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF030303),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'لا توجد أغنية قيد التشغيل حالياً',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final isFav = ref.watch(favoritesProvider).value?.any((s) => s.id == song.id) ?? song.isFavorite;
    final isDownloaded = ref.watch(downloadsProvider).value?.any((s) => s.id == song.id) ?? song.isDownloaded;

    final duration = playerState.duration;
    final position = playerState.position;
    final maxMs = duration.inMilliseconds.toDouble();
    final currentMs = (_dragValue ?? position.inMilliseconds.toDouble())
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    final screenWidth = MediaQuery.of(context).size.width;
    final albumArtSize = screenWidth * 0.84;

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Down Chevron, Video/Audio Mode Toggle, Cast & 3-Dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Down chevron to close
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Center Segmented Toggle: [ Video | Song/Audio ]
                  Container(
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF212121),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Video Segment
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVideoMode = true;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isVideoMode ? const Color(0xFF383838) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Audio/Song Segment
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVideoMode = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: !_isVideoMode ? const Color(0xFF383838) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.headphones_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cast & 3-Dots Menu
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cast_rounded, size: 22, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 24, color: Colors.white),
                        onPressed: () => _showOptionsMenu(context, ref, song, isFav, isDownloaded),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Large Square Album Artwork
            Center(
              child: Container(
                width: albumArtSize,
                height: albumArtSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(200),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: song.artworkUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF1E1E1E),
                      child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF1E1E1E),
                      child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Song Info: Title and Artist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Pills Row: Like, Dislike, Comment, Save, Share
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Like button pill with count
                    _buildPillButton(
                      icon: _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                      label: '430 ألف',
                      isActive: _isLiked,
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                          if (_isLiked) _isDisliked = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Dislike button pill
                    _buildPillButton(
                      icon: _isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
                      label: null,
                      isActive: _isDisliked,
                      onTap: () {
                        setState(() {
                          _isDisliked = !_isDisliked;
                          if (_isDisliked) _isLiked = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Comments pill
                    _buildPillButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '26 ألف',
                      onTap: () {
                        _showCommentsBottomSheet(context, song.title);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Save / Bookmark pill
                    _buildPillButton(
                      icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      label: 'حفظ',
                      isActive: isFav,
                      onTap: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(song);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Share pill
                    _buildPillButton(
                      icon: Icons.share_rounded,
                      label: 'مشاركة',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم نسخ رابط ${song.title}')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Progress Slider & Timestamps (Strictly LTR: 00:00 on left, total on right, slider left to right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: const Color(0x33FFFFFF),
                        thumbColor: Colors.white,
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
                            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                          ),
                          Text(
                            Formatters.formatDuration(duration),
                            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Player Controls: Shuffle, Previous, Big White Play/Pause, Next, Repeat (Strictly LTR)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle Icon (Far Left)
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerState.isShuffleEnabled ? Colors.white : const Color(0xFF777777),
                        size: 26,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).toggleShuffle();
                      },
                    ),

                    // Previous Track (|<< pointing left)
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).previous();
                      },
                    ),

                    // Big White Circular Play/Pause Button (Center)
                    GestureDetector(
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).playOrPause();
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (playerState.isBuffering && !playerState.isPlaying)
                              const SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  color: Colors.black45,
                                  strokeWidth: 3,
                                ),
                              ),
                            Icon(
                              playerState.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 46,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Next Track (>>| pointing right)
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).next();
                      },
                    ),

                    // Repeat / Loop Mode (Far Right)
                    IconButton(
                      icon: Icon(
                        playerState.loopMode == LoopMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: playerState.loopMode != LoopMode.off
                            ? Colors.white
                            : const Color(0xFF777777),
                        size: 26,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).toggleLoopMode();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Bottom Drag Handle & Playlist Source Name
            GestureDetector(
              onTap: () => showQueueBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF555555),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.album.isNotEmpty ? song.album : 'قائمة التشغيل الحالية',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildPillButton({
    required IconData icon,
    String? label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF383838) : const Color(0xFF212121),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white54 : const Color(0xFF333333),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFFCCCCCC),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFCCCCCC),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, String songTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('التعليقات (26 ألف)', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              Text(
                'أغنية رائعة وتوزيع مذهل! استمتع بسماعها يومياً أثناء التمرين.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.accent : Colors.white,
                ),
                title: Text(isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(favoritesProvider.notifier).toggleFavorite(song);
                },
              ),
              ListTile(
                leading: Icon(
                  isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                  color: Colors.white,
                ),
                title: Text(isDownloaded ? 'محمل بالفعل' : 'تحميل للاستماع بدون إنترنت'),
                onTap: () {
                  Navigator.pop(context);
                  if (!isDownloaded) {
                    ref.read(downloadsProvider.notifier).downloadSong(song);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded, color: Colors.white),
                title: const Text('عرض قائمة الانتظار'),
                onTap: () {
                  Navigator.pop(context);
                  showQueueBottomSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
