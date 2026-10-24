import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/screens/home/home_screen.dart';
import 'package:mazikty/presentation/screens/library/library_screen.dart';
import 'package:mazikty/presentation/screens/samples/samples_screen.dart';
import 'package:mazikty/presentation/screens/search/search_screen.dart';
import 'package:mazikty/presentation/screens/favorites/favorites_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mazikty/presentation/providers/desktop_player_mode_provider.dart';
import 'package:mazikty/presentation/widgets/desktop_side_controller.dart';
import 'package:mazikty/presentation/widgets/mini_player.dart';
import 'package:mazikty/presentation/widgets/standalone_mini_player_window.dart';
import 'package:window_manager/window_manager.dart';

class MainScaffoldScreen extends ConsumerStatefulWidget {
  const MainScaffoldScreen({super.key});

  @override
  ConsumerState<MainScaffoldScreen> createState() => _MainScaffoldScreenState();
}

class _MainScaffoldScreenState extends ConsumerState<MainScaffoldScreen> with WindowListener {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.addListener(this);
      _setupWindow();
    }
  }

  Future<void> _setupWindow() async {
    try {
      await windowManager.setPreventClose(true);
    } catch (e) {
      debugPrint('Error setting prevent close: $e');
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final mode = ref.read(desktopModeProvider);
    if (mode == DesktopMode.full) {
      // Rather than terminating, detach to floating mini player on the desktop
      ref.read(desktopModeProvider.notifier).switchToMiniPlayer();
    } else {
      // In mini player mode, actually exit
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktopMode = ref.watch(desktopModeProvider);
    if (desktopMode == DesktopMode.miniPlayer) {
      return const StandaloneMiniPlayerWindow();
    }

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
      const FavoritesScreen(),
    ];

    final isDesktopPlatform = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    final isWideScreen = MediaQuery.sizeOf(context).width >= 750;
    final showDesktopController = isDesktopPlatform || isWideScreen;

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

          // Desktop Floating Draggable Playback Controller
          if (showDesktopController)
            const DesktopSideController(),
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
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'المفضلة',
            ),
          ],
        ),
      ),
    );
  }
}
