import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/domain/models/artist.dart';
import 'package:mazikty/presentation/screens/artist/artist_detail_screen.dart';

class ArtistAvatar extends StatelessWidget {
  final Artist artist;
  final double size;

  const ArtistAvatar({
    super.key,
    required this.artist,
    this.size = 85,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(artist: artist),
          ),
        );
      },
      child: Container(
        width: size + 20,
        margin: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: artist.imageUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: size,
                    height: size,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.person, color: AppColors.textMuted),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: size,
                    height: size,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.person, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              artist.genre ?? 'فنان',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
