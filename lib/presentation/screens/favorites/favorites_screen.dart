import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/audio_player_provider.dart';
import 'package:mazikty/presentation/providers/favorites_provider.dart';
import 'package:mazikty/presentation/widgets/empty_state_view.dart';
import 'package:mazikty/presentation/widgets/song_tile.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _selectedCategory = 'الكل';

  final List<String> _categories = [
    'الكل',
    'حفلة (Party)',
    'حماسي (Pump-up)',
    'رومانسية (Romance)',
    'شعبي',
    'طرب',
  ];

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030303),
        elevation: 0,
        title: const Text(
          'Liked Music',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast_rounded, color: Colors.white),
            tooltip: 'بث الصوت',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جارٍ البحث عن أجهزة البث المتاحة...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'بحث في المفضلة',
            onPressed: () {
              // Open search
            },
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'لا توجد أغانٍ في المفضلة',
              message:
                  'اضغط على رمز القلب بجانب أي أغنية لتحفظها في قائمتك المفضلة وتصل إليها بسرعة في أي وقت.',
            );
          }

          // Filter by category if selected
          final filteredSongs = _selectedCategory == 'الكل'
              ? songs
              : songs.where((s) {
                  final cat = _selectedCategory.toLowerCase();
                  if (cat.contains('party') || cat.contains('حفلة')) {
                    return s.genre.contains('شعبي') ||
                        s.genre.contains('مهرجانات') ||
                        s.genre.contains('ريمكس') ||
                        s.genre.contains('دبكة');
                  }
                  if (cat.contains('pump') || cat.contains('حماسي')) {
                    return s.genre.contains('تراب') ||
                        s.genre.contains('فونك') ||
                        s.genre.contains('راب') ||
                        s.genre.contains('حماسي');
                  }
                  if (cat.contains('romance') || cat.contains('رومانسية')) {
                    return s.genre.contains('رومانسي') ||
                        s.genre.contains('بوب') ||
                        s.genre.contains('إندي');
                  }
                  return s.genre.contains(_selectedCategory);
                }).toList();

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YouTube Music Style Category Chips (Party, Pump-up, Romance, etc.)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = isSelected ? 'الكل' : category;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFF212121),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? Colors.white : const Color(0xFF383838),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Offline available indicator
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(70), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'المفضلة (${filteredSongs.length} أغنية) متاحة وتعمل بكفاءة عالية',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Song list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        return SongTile(
                          song: song,
                          playlist: filteredSongs,
                          index: index,
                          showIndex: false,
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Floating Pill "▶ Play" button matching YouTube Music screenshot
              Positioned(
                bottom: 80,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    onTap: () {
                      if (filteredSongs.isNotEmpty) {
                        ref.read(audioPlayerProvider.notifier).playPlaylist(filteredSongs);
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(76),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 26,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Text('حدث خطأ في تحميل المفضلة: $err', style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}
