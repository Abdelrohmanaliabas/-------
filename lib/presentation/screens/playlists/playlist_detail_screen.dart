import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/domain/models/playlist.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/providers/playlists_provider.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';
import 'create_playlist_dialog.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final currentPlaylist = playlistsAsync.value?.firstWhere(
          (p) => p.id == playlist.id,
          orElse: () => playlist,
        ) ??
        playlist;

    final songs = currentPlaylist.songs;
    final favState = ref.watch(favoritesProvider);
    final favIds = favState.value?.map((s) => s.id).toSet() ?? {};
    final isSaved = favIds.contains(currentPlaylist.id);

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar: Back & Cast
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cast_rounded, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Cover Art, Title & Meta (YouTube Music Playlist Header)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Center Square Artwork
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(200),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: currentPlaylist.artworkUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFF1E1E1E)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF1E1E1E),
                              child: const Icon(Icons.queue_music, size: 60, color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Playlist Title
                    Text(
                      currentPlaylist.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Creator Row: Avatar + Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF333333),
                          ),
                          child: const Icon(Icons.person, size: 14, color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentPlaylist.description?.isNotEmpty == true
                              ? currentPlaylist.description!
                              : 'مازيكتي للموسيقى',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Metadata: views • duration • date
                    Text(
                      '2.1 مليون مشاهدة • ${currentPlaylist.songsCount} مقطع • تم التحديث مؤخراً',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons Row: [3-dots, Comments, BIG WHITE PLAY, Bookmark, Download]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircleActionButton(
                          icon: Icons.more_vert_rounded,
                          onTap: () {
                            if (currentPlaylist.isCustom) {
                              showRenamePlaylistDialog(
                                context,
                                ref,
                                currentPlaylist.id,
                                currentPlaylist.name,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        _buildCircleActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 14),

                        // Big White Circular Play Button
                        GestureDetector(
                          onTap: () {
                            if (songs.isNotEmpty) {
                              ref.read(audioPlayerProvider.notifier).playPlaylist(songs, initialIndex: 0);
                            }
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        _buildCircleActionButton(
                          icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تمت إضافة ${currentPlaylist.name} إلى مكتبتك'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),

                        _buildCircleActionButton(
                          icon: Icons.arrow_downward_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('جاري تحميل قائمة التشغيل للاستماع بدون إنترنت...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Promotional banner card (matching Image 4)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0xFF2B2B2B),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'جرّب الآن',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'انقر لمعاينة قائمة التشغيل هذه والعثور على أغانيك المفضلة',
                                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Song List
            if (songs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('لا توجد مقاطع في هذه القائمة بعد', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return SongTile(
                      song: song,
                      playlist: songs,
                      index: index,
                    );
                  },
                  childCount: songs.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF212121),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
