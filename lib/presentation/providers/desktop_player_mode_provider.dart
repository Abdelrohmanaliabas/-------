import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

enum DesktopMode {
  full,
  miniPlayer,
}

final desktopModeProvider = StateNotifierProvider<DesktopModeNotifier, DesktopMode>((ref) {
  return DesktopModeNotifier();
});

class DesktopModeNotifier extends StateNotifier<DesktopMode> {
  DesktopModeNotifier() : super(DesktopMode.full);

  Size _lastFullSize = const Size(1280, 720);
  Offset _lastFullPosition = const Offset(60, 60);

  Future<void> switchToMiniPlayer() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    try {
      final currentSize = await windowManager.getSize();
      if (currentSize.width > 500) {
        _lastFullSize = currentSize;
        _lastFullPosition = await windowManager.getPosition();
      }

      await windowManager.setMinimumSize(const Size(280, 460));
      await windowManager.setSize(const Size(320, 520));
      final miniPos = Offset(
        (_lastFullPosition.dx + _lastFullSize.width - 340).clamp(20.0, 3840.0),
        (_lastFullPosition.dy + 30).clamp(20.0, 2160.0),
      );
      await windowManager.setPosition(miniPos);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setTitle("تحكم مازيكتي - Mazikty Mini");
      state = DesktopMode.miniPlayer;
    } catch (e) {
      debugPrint('Error switching to mini player: $e');
    }
  }

  Future<void> switchToFullApp() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(800, 550));
      await windowManager.setSize(_lastFullSize.width > 500 ? _lastFullSize : const Size(1280, 720));
      await windowManager.setPosition(_lastFullPosition);
      await windowManager.setTitle("مازيكتي - Mazikty");
      state = DesktopMode.full;
    } catch (e) {
      debugPrint('Error switching to full app: $e');
    }
  }

  void toggleMode() {
    if (state == DesktopMode.full) {
      switchToMiniPlayer();
    } else {
      switchToFullApp();
    }
  }
}
