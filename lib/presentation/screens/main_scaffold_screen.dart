import 'package:flutter/material.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/screens/home/home_screen.dart';
import 'package:mazikty/presentation/screens/library/library_screen.dart';
import 'package:mazikty/presentation/screens/samples/samples_screen.dart';
import 'package:mazikty/presentation/screens/search/search_screen.dart';
import 'package:mazikty/presentation/screens/upgrade/upgrade_screen.dart';
import 'package:mazikty/presentation/widgets/mini_player.dart';

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
            _currentIndex = 2; // Jump to search tab
          });
        },
      ),
      const SamplesScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      const UpgradeScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: Stack(
        children: [
          // Preserve tabs state
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Mini Player positioned directly above bottom navigation
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
          color: Color(0xFF030303),
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E1E), width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF030303),
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF909090),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 10,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(
            color: const Color(0xFF909090),
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'الصفحة الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.slow_motion_video_outlined),
              activeIcon: Icon(Icons.slow_motion_video_rounded),
              label: 'عينات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'بحث',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music_rounded),
              label: 'المكتبة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: 'الترقية',
            ),
          ],
        ),
      ),
    );
  }
}
