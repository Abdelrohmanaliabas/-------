import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/downloads_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/providers/playlists_provider.dart';
import 'package:mazikty/presentation/widgets/playlist_card.dart';
import 'package:mazikty/presentation/widgets/section_header.dart';
import 'package:mazikty/presentation/screens/downloads/downloads_screen.dart';
import 'package:mazikty/presentation/screens/playlists/create_playlist_dialog.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;
    final downloadsCount = ref.watch(downloadsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('المكتبة الموسيقية', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'إنشاء قائمة تشغيل',
            onPressed: () {
              showCreatePlaylistDialog(context, ref);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Quick navigation cards (Downloads & Favorites)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickTile(
                    context,
                    title: 'المحملات',
                    subtitle: '$downloadsCount أغنية',
                    icon: Icons.download_done_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickTile(
                    context,
                    title: 'المفضلة',
                    subtitle: '$favoritesCount أغنية',
                    icon: Icons.favorite_rounded,
                    color: AppColors.accent,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SectionHeader(
            title: 'قوائم التشغيل الخاصة بك',
            actionText: 'إنشاء قائمة',
            onAction: () {
              showCreatePlaylistDialog(context, ref);
            },
          ),

          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'لا توجد قوائم تشغيل حتى الآن',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    return PlaylistCard(playlist: pl, width: double.infinity);
                  },
                ),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (err, _) => Center(child: Text('خطأ في تحميل القوائم: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
