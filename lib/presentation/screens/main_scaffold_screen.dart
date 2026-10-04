import 'package:flutter/material.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/widgets/mini_player.dart';
import 'package:mazikty/presentation/screens/favorites/favorites_screen.dart';
import 'package:mazikty/presentation/screens/home/home_screen.dart';
import 'package:mazikty/presentation/screens/library/library_screen.dart';
import 'package:mazikty/presentation/screens/search/search_screen.dart';

class MainScaffoldScreen extends StatefulWidget {
  const MainScaffoldScreen({super.key});

  @override
  State<MainScaffoldScreen> createState() => _MainScaffoldScreenState();
}

class _MainScaffoldScreenState extends State<MainScaffoldScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onSearchTap: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const SearchScreen(),
      const FavoritesScreen(),
      const LibraryScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack ensures tabs preserve their scroll positions and state
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Mini Player positioned above bottom navigation
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.6),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedLabelStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTypography.labelSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'البحث',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music_rounded),
              label: 'المكتبة',
            ),
          ],
        ),
      ),
    );
  }
}
