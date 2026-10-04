import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/domain/models/genre.dart';
import 'package:mazikty/domain/models/playlist.dart';
import 'package:mazikty/presentation/providers/music_providers.dart';
import 'package:mazikty/presentation/screens/playlists/playlist_detail_screen.dart';

class CategoriesSection extends ConsumerWidget {
  final List<Genre> genres;

  const CategoriesSection({super.key, required this.genres});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          final color = Color(int.tryParse(genre.colorHex) ?? 0xFF00E5FF);

          return GestureDetector(
            onTap: () async {
              final songs = await ref.read(songsByGenreProvider(genre.id).future);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(
                      playlist: Playlist(
                        id: genre.id,
                        name: genre.name,
                        description: 'مختارات من روائع تصنيف ${genre.name}',
                        artworkUrl: genre.artworkUrl,
                        songs: songs,
                        isCustom: false,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withAlpha(160),
                    AppColors.surfaceLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(80), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getGenreIcon(genre.icon),
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    genre.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getGenreIcon(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note_rounded;
      case 'graphic_eq':
        return Icons.graphic_eq_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'piano':
        return Icons.piano_rounded;
      case 'headset':
        return Icons.headset_rounded;
      default:
        return Icons.album_rounded;
    }
  }
}
